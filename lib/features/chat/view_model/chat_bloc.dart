import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/match.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/match_repository.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  const ChatOpened();
}

class ChatDraftChanged extends ChatEvent {
  const ChatDraftChanged(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

class ChatSendPressed extends ChatEvent {
  const ChatSendPressed([this.text]);

  /// Send this text instead of the draft (icebreaker chips).
  final String? text;
  @override
  List<Object?> get props => [text];
}

class _ChatPolled extends ChatEvent {
  const _ChatPolled();
}

enum ChatStatus { loading, ready, failure }

class ChatState extends Equatable {
  const ChatState({
    required this.match,
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.draft = '',
    this.draftVersion = 0,
    this.isSending = false,
    this.error,
  });

  final Match match;
  final ChatStatus status;

  /// Oldest first.
  final List<Message> messages;
  final String draft;

  /// Bumped after a send so the stateless input field rebuilds empty.
  final int draftVersion;
  final bool isSending;
  final String? error;

  bool get canSend => draft.trim().isNotEmpty && !isSending;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? draft,
    int? draftVersion,
    bool? isSending,
    String? error,
  }) =>
      ChatState(
        match: match,
        status: status ?? this.status,
        messages: messages ?? this.messages,
        draft: draft ?? this.draft,
        draftVersion: draftVersion ?? this.draftVersion,
        isSending: isSending ?? this.isSending,
        error: error,
      );

  @override
  List<Object?> get props => [match, status, messages, draft, draftVersion, isSending, error];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._repo, Match match) : super(ChatState(match: match)) {
    on<ChatOpened>(_onOpened);
    on<ChatDraftChanged>((e, emit) => emit(state.copyWith(draft: e.text)));
    on<ChatSendPressed>(_onSend);
    on<_ChatPolled>(_onPolled);
  }

  final MatchRepository _repo;
  Timer? _poll;

  Future<void> _onOpened(ChatOpened e, Emitter<ChatState> emit) async {
    try {
      final msgs = await _repo.messages(state.match.id);
      emit(state.copyWith(status: ChatStatus.ready, messages: msgs));
    } on ApiException catch (err) {
      emit(state.copyWith(status: ChatStatus.failure, error: err.message));
    }
    // Replace with a WebSocket once the backend has one.
    _poll ??= Timer.periodic(AppConfig.chatPollInterval, (_) => add(const _ChatPolled()));
  }

  Future<void> _onPolled(_ChatPolled e, Emitter<ChatState> emit) async {
    try {
      final msgs = await _repo.messages(state.match.id);
      if (msgs.length != state.messages.length) emit(state.copyWith(messages: msgs));
    } on ApiException {
      // Silent: polling should not interrupt the user.
    }
  }

  Future<void> _onSend(ChatSendPressed e, Emitter<ChatState> emit) async {
    final text = (e.text ?? state.draft).trim();
    if (text.isEmpty || state.isSending) return;
    emit(state.copyWith(isSending: true));
    try {
      final msg = await _repo.sendMessage(state.match.id, text);
      emit(state.copyWith(
        messages: [...state.messages, msg],
        draft: e.text == null ? '' : state.draft,
        draftVersion: e.text == null ? state.draftVersion + 1 : state.draftVersion,
        isSending: false,
      ));
    } on ApiException catch (err) {
      emit(state.copyWith(isSending: false, error: err.message));
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
