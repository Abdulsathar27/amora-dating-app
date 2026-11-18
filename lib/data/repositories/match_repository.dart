import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/match.dart';
import '../models/message.dart';

class MatchRepository {
  MatchRepository(this._client);

  final DioClient _client;

  Future<List<Match>> matches() async {
    final json = await _client.get(ApiEndpoints.matches);
    return (json['items'] as List).map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Match> match(String id) async => Match.fromJson(await _client.get(ApiEndpoints.match(id)) as Map<String, dynamic>);

  Future<void> unmatch(String matchId) => _client.delete(ApiEndpoints.match(matchId));

  Future<void> setMuted(String matchId, bool muted) => _client.patch(ApiEndpoints.match(matchId), data: {'is_muted': muted});

  Future<List<Message>> messages(String matchId) async {
    final json = await _client.get(ApiEndpoints.messages(matchId));
    return (json['items'] as List).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Message> send(String matchId, {MessageType type = MessageType.text, String text = '', String? mediaUrl}) async {
    final json = await _client.post(
      ApiEndpoints.messages(matchId),
      data: {'type': type.value, 'text': text, 'media_url': ?mediaUrl},
    );
    return Message.fromJson(json as Map<String, dynamic>);
  }

  Future<Message> react(String messageId, String? reaction) async =>
      Message.fromJson(await _client.put(ApiEndpoints.reaction(messageId), data: {'reaction': reaction}) as Map<String, dynamic>);

  Future<Message> reveal(String messageId) async =>
      Message.fromJson(await _client.post(ApiEndpoints.reveal(messageId)) as Map<String, dynamic>);
}
