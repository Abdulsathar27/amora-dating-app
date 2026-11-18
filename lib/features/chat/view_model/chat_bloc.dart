import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/match.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/match_repository.dart';

// ---------------- Events ----------------
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

/// Sends the draft, or [text] directly (conversation starters).
class ChatSendPressed extends ChatEvent {
  const ChatSendPressed([this.text]);
  final String? text;
  @override
  List<Object?> get props => [text];
}

class ChatMediaSent extends ChatEvent {
  const ChatMediaSent(this.type, this.url);
  final MessageType type;
  final String url;
  @override
  List<Object?> get props => [type, url];
}

/// Long-press on a message opens the reaction bar for it (null closes it).
class ChatMessageSelected extends ChatEvent {
  const ChatMessageSelected(this.message);
  final Message? message;
  @override
  List<Object?> get props => [message];
}

class ChatReacted extends ChatEvent {
  const ChatReacted(this.reaction);
  final String reaction;
  @override
  List<Object?> get props => [reaction];
}

class ChatPhotoRevealed extends ChatEvent {
  const ChatPhotoRevealed(this.messageId);
  final String messageId;
  @override
  List<Object?> get props => [messageId];
}

/// "Not now" on a hidden photo: keep it hidden and collapse the choices.
class ChatPhotoDeclined extends ChatEvent {
  const ChatPhotoDeclined(this.messageId);
  final String messageId;
  @override
  List<Object?> get props => [messageId];
}

class ChatMuteToggled extends ChatEvent {
  const ChatMuteToggled();
}

class ChatVoicePlayed extends ChatEvent {
  const ChatVoicePlayed(this.messageId);
  final String? messageId;
  @override
  List<Object?> get props => [messageId];
}

class _ChatPolled extends ChatEvent {
  const _ChatPolled();
}

// ---------------- State ----------------
enum ChatStatus { loading, ready, failure }

class ChatState extends Equatable {
  const ChatState({
    required this.match,
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.draft = '',
    this.draftVersion = 0,
    this.isSending = false,
    this.partnerTyping = false,
    this.selected,
    this.declined = const {},
    this.isMuted = false,
    this.playingId,
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
  final bool partnerTyping;

  /// Message with the reaction bar open.
  final Message? selected;

  /// Hidden photos the user chose "Not now" for.
  final Set<String> declined;
  final bool isMuted;
  final String? playingId;
  final String? error;

  bool get hasDraft => draft.trim().isNotEmpty;
  bool get isNew => status == ChatStatus.ready && messages.isEmpty;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? draft,
    int? draftVersion,
    bool? isSending,
    bool? partnerTyping,
    Message? Function()? selected,
    Set<String>? declined,
    bool? isMuted,
    String? Function()? playingId,
    String? Function()? error,
  }) => ChatState(
    match: match,
    status: status ?? this.status,
    messages: messages ?? this.messages,
    draft: draft ?? this.draft,
    draftVersion: draftVersion ?? this.draftVersion,
    isSending: isSending ?? this.isSending,
    partnerTyping: partnerTyping ?? this.partnerTyping,
    selected: selected != null ? selected() : this.selected,
    declined: declined ?? this.declined,
    isMuted: isMuted ?? this.isMuted,
    playingId: playingId != null ? playingId() : this.playingId,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [match, status, messages, draft, draftVersion, isSending, partnerTyping, selected, declined, isMuted, playingId, error];
}

// ---------------- ViewModel ----------------
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._repo, Match match) : super(ChatState(match: match, isMuted: match.isMuted)) {
    on<ChatOpened>(_onOpened);
    on<ChatDraftChanged>((e, emit) => emit(state.copyWith(draft: e.text)));
    on<ChatSendPressed>(_onSend);
    on<ChatMediaSent>(_onMedia);
    on<ChatMessageSelected>((e, emit) => emit(state.copyWith(selected: () => e.message)));
    on<ChatReacted>(_onReacted);
    on<ChatPhotoRevealed>(_onRevealed);
    on<ChatPhotoDeclined>((e, emit) => emit(state.copyWith(declined: {...state.declined, e.messageId})));
    on<ChatMuteToggled>(_onMute);
    on<ChatVoicePlayed>((e, emit) => emit(state.copyWith(playingId: () => state.playingId == e.messageId ? null : e.messageId)));
    on<_ChatPolled>(_onPolled);
  }

  final MatchRepository _repo;
  Timer? _poll;

  Future<void> _onOpened(ChatOpened e, Emitter<ChatState> emit) async {
    try {
      emit(state.copyWith(status: ChatStatus.ready, messages: await _repo.messages(state.match.id)));
    } on ApiException catch (err) {
      emit(state.copyWith(status: ChatStatus.failure, error: () => err.message));
    }
    // Replace with a WebSocket once the backend has one.
    _poll ??= Timer.periodic(AppConfig.chatPollInterval, (_) => add(const _ChatPolled()));
  }

  Future<void> _onPolled(_ChatPolled e, Emitter<ChatState> emit) async {
    try {
      final msgs = await _repo.messages(state.match.id);
      if (msgs.length != state.messages.length) emit(state.copyWith(messages: msgs, partnerTyping: false));
    } on ApiException {
      // Silent: polling should not interrupt the user.
    }
  }

  Future<void> _onSend(ChatSendPressed e, Emitter<ChatState> emit) async {
    final text = (e.text ?? state.draft).trim();
    if (text.isEmpty || state.isSending) return;
    emit(state.copyWith(isSending: true, error: () => null));
    try {
      final msg = await _repo.send(state.match.id, text: text);
      emit(
        state.copyWith(
          messages: [...state.messages, msg],
          draft: e.text == null ? '' : state.draft,
          draftVersion: e.text == null ? state.draftVersion + 1 : state.draftVersion,
          isSending: false,
          partnerTyping: true,
        ),
      );
    } on ApiException catch (err) {
      emit(state.copyWith(isSending: false, error: () => err.message));
    }
  }

  Future<void> _onMedia(ChatMediaSent e, Emitter<ChatState> emit) async {
    try {
      final msg = await _repo.send(state.match.id, type: e.type, mediaUrl: e.url);
      emit(state.copyWith(messages: [...state.messages, msg], partnerTyping: true));
    } on ApiException catch (err) {
      emit(state.copyWith(error: () => err.message));
    }
  }

  Future<void> _onReacted(ChatReacted e, Emitter<ChatState> emit) async {
    final target = state.selected;
    if (target == null) return;
    final next = target.reaction == e.reaction ? null : e.reaction;
    emit(state.copyWith(selected: () => null, messages: [for (final m in state.messages) m.id == target.id ? m.copyWith(reaction: next ?? '') : m]));
    try {
      await _repo.react(target.id, next);
    } on ApiException catch (err) {
      emit(state.copyWith(error: () => err.message));
    }
  }

  Future<void> _onRevealed(ChatPhotoRevealed e, Emitter<ChatState> emit) async {
    emit(state.copyWith(messages: [for (final m in state.messages) m.id == e.messageId ? m.copyWith(isHidden: false) : m]));
    try {
      await _repo.reveal(e.messageId);
    } on ApiException catch (err) {
      emit(state.copyWith(error: () => err.message));
    }
  }

  Future<void> _onMute(ChatMuteToggled e, Emitter<ChatState> emit) async {
    final muted = !state.isMuted;
    emit(state.copyWith(isMuted: muted));
    try {
      await _repo.setMuted(state.match.id, muted);
    } on ApiException catch (err) {
      emit(state.copyWith(isMuted: !muted, error: () => err.message));
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
