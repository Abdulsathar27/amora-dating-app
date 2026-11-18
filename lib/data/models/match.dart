import 'package:equatable/equatable.dart';

import 'message.dart';
import 'profile.dart';

class Match extends Equatable {
  const Match({
    required this.id,
    required this.profile,
    required this.matchedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isMuted = false,
  });

  final String id;

  /// The other person.
  final Profile profile;
  final DateTime matchedAt;
  final Message? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final bool isMuted;

  bool get hasConversation => lastMessage != null;

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'].toString(),
    profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
    matchedAt: DateTime.parse(json['matched_at'] as String),
    lastMessage: json['last_message'] == null ? null : Message.fromJson(json['last_message'] as Map<String, dynamic>),
    unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    isOnline: json['is_online'] as bool? ?? false,
    isMuted: json['is_muted'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, profile, matchedAt, lastMessage, unreadCount, isOnline, isMuted];
}

enum LikeKind { like, superLike, compliment }

/// Someone who liked you but you haven't answered yet ("They noticed you.").
class ReceivedLike extends Equatable {
  const ReceivedLike({
    required this.profile,
    required this.likedAt,
    this.kind = LikeKind.like,
    this.reason,
    this.comment,
  });

  final Profile profile;
  final DateTime likedAt;
  final LikeKind kind;

  /// "Liked your voice intro", "Liked your photo"…
  final String? reason;

  /// Compliment text, if they sent one.
  final String? comment;

  factory ReceivedLike.fromJson(Map<String, dynamic> json) => ReceivedLike(
    profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
    likedAt: DateTime.parse(json['liked_at'] as String),
    kind: switch (json['kind']) {
      'super_like' => LikeKind.superLike,
      'compliment' => LikeKind.compliment,
      _ => LikeKind.like,
    },
    reason: json['reason'] as String?,
    comment: json['comment'] as String?,
  );

  @override
  List<Object?> get props => [profile, likedAt, kind, reason, comment];
}
