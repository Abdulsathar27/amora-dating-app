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

  Future<void> unmatch(String matchId) => _client.delete(ApiEndpoints.match(matchId));

  Future<List<Message>> messages(String matchId, {String? before}) async {
    final json = await _client.get(
      ApiEndpoints.messages(matchId),
      query: {'before': ?before},
    );
    return (json['items'] as List).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Message> sendMessage(String matchId, String text) async {
    final json = await _client.post(ApiEndpoints.messages(matchId), data: {'text': text});
    return Message.fromJson(json as Map<String, dynamic>);
  }
}
