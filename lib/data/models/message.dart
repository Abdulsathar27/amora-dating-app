import 'package:equatable/equatable.dart';

class Message extends Equatable {
  const Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  final String id;
  final String matchId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'].toString(),
        matchId: json['match_id'].toString(),
        senderId: json['sender_id'].toString(),
        text: json['text'] as String? ?? '',
        sentAt: DateTime.parse(json['sent_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, matchId, senderId, text, sentAt, isRead];
}
