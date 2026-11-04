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
    this.expiresAt,
    this.canSendFirstMessage = true,
  });

  final String id;

  /// The other person.
  final Profile profile;
  final DateTime matchedAt;
  final Message? lastMessage;
  final int unreadCount;

  /// Bumble-style: a match with no conversation expires after 24h. Null = never.
  final DateTime? expiresAt;

  /// Bumble-style "first move" rule decided by the backend.
  final bool canSendFirstMessage;

  bool get hasConversation => lastMessage != null;

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'].toString(),
        profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
        matchedAt: DateTime.parse(json['matched_at'] as String),
        lastMessage: json['last_message'] == null
            ? null
            : Message.fromJson(json['last_message'] as Map<String, dynamic>),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
        canSendFirstMessage: json['can_send_first_message'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, profile, matchedAt, lastMessage, unreadCount, expiresAt, canSendFirstMessage];
}

/// Someone who liked you but you haven't swiped on yet ("Likes You").
class ReceivedLike extends Equatable {
  const ReceivedLike({required this.profile, required this.likedAt, this.isSuperLike = false, this.comment});

  final Profile profile;
  final DateTime likedAt;
  final bool isSuperLike;

  /// Hinge-style comment attached to the like.
  final String? comment;

  factory ReceivedLike.fromJson(Map<String, dynamic> json) => ReceivedLike(
        profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
        likedAt: DateTime.parse(json['liked_at'] as String),
        isSuperLike: json['is_super_like'] as bool? ?? false,
        comment: json['comment'] as String?,
      );

  @override
  List<Object?> get props => [profile, likedAt, isSuperLike, comment];
}
