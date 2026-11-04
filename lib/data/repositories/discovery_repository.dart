import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/discovery.dart';
import '../models/match.dart';
import '../models/profile.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._client);

  final DioClient _client;

  Future<List<Profile>> feed({int limit = 10}) async {
    final json = await _client.get(ApiEndpoints.feed, query: {'limit': limit});
    return (json['items'] as List).map((e) => Profile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SwipeResult> swipe({required String profileId, required SwipeAction action, String? comment}) async {
    final json = await _client.post(
      ApiEndpoints.swipe,
      data: {'target_id': profileId, 'action': action.value, 'comment': ?comment},
    );
    return SwipeResult.fromJson(json as Map<String, dynamic>);
  }

  /// Undo the last pass (Tinder "rewind"). Returns the restored profile.
  Future<Profile> rewind() async {
    final json = await _client.post(ApiEndpoints.rewind);
    return Profile.fromJson(json as Map<String, dynamic>);
  }

  Future<DiscoveryPreferences> preferences() async {
    final json = await _client.get(ApiEndpoints.preferences);
    return DiscoveryPreferences.fromJson(json as Map<String, dynamic>);
  }

  Future<DiscoveryPreferences> savePreferences(DiscoveryPreferences prefs) async {
    final json = await _client.put(ApiEndpoints.preferences, data: prefs.toJson());
    return DiscoveryPreferences.fromJson(json as Map<String, dynamic>);
  }

  Future<List<ReceivedLike>> receivedLikes() async {
    final json = await _client.get(ApiEndpoints.receivedLikes);
    return (json['items'] as List).map((e) => ReceivedLike.fromJson(e as Map<String, dynamic>)).toList();
  }
}
