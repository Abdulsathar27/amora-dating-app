import 'package:equatable/equatable.dart';

enum MessageType {
  text('text'),
  voice('voice'),
  photo('photo'),
  gif('gif');

  const MessageType(this.value);
  final String value;

  static MessageType fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => MessageType.text);
}

class Message extends Equatable {
  const Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.sentAt,
    this.type = MessageType.text,
    this.text = '',
    this.mediaUrl,
    this.voiceSeconds,
    this.reaction,
    this.isHidden = false,
    this.isRead = false,
  });

  final String id;
  final String matchId;
  final String senderId;
  final DateTime sentAt;
  final MessageType type;
  final String text;
  final String? mediaUrl;
  final int? voiceSeconds;

  /// Icon name of a reaction (heart, smile, star…), if any.
  final String? reaction;

  /// Incoming photo waiting for consent ("It stays hidden until you choose to see it").
  final bool isHidden;
  final bool isRead;

  /// One-line preview for the Messages list.
  String get preview => switch (type) {
    MessageType.text => text,
    MessageType.voice => 'Sent a voice message',
    MessageType.photo => 'Sent a photo',
    MessageType.gif => 'Sent a GIF',
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'].toString(),
    matchId: json['match_id'].toString(),
    senderId: json['sender_id'].toString(),
    sentAt: DateTime.parse(json['sent_at'] as String),
    type: MessageType.fromValue(json['type'] as String?),
    text: json['text'] as String? ?? '',
    mediaUrl: json['media_url'] as String?,
    voiceSeconds: (json['voice_seconds'] as num?)?.toInt(),
    reaction: json['reaction'] as String?,
    isHidden: json['is_hidden'] as bool? ?? false,
    isRead: json['is_read'] as bool? ?? false,
  );

  Message copyWith({String? reaction, bool? isHidden}) => Message(
    id: id,
    matchId: matchId,
    senderId: senderId,
    sentAt: sentAt,
    type: type,
    text: text,
    mediaUrl: mediaUrl,
    voiceSeconds: voiceSeconds,
    reaction: reaction ?? this.reaction,
    isHidden: isHidden ?? this.isHidden,
    isRead: isRead,
  );

  @override
  List<Object?> get props => [id, matchId, senderId, sentAt, type, text, mediaUrl, voiceSeconds, reaction, isHidden, isRead];
}
