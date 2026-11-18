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

  /// [comment] turns a like into a compliment ("Send Maya a compliment").
  Future<SwipeResult> swipe({required String profileId, required SwipeAction action, String? comment}) async {
    final json = await _client.post(
      ApiEndpoints.swipe,
      data: {'target_id': profileId, 'action': action.value, 'comment': ?comment},
    );
    return SwipeResult.fromJson(json as Map<String, dynamic>);
  }

  Future<DiscoveryPreferences> preferences() async {
    final json = await _client.get(ApiEndpoints.preferences);
    return DiscoveryPreferences.fromJson(json as Map<String, dynamic>);
  }

  /// Saves and returns the preferences plus how many people match them ("Show 42 people").
  Future<(DiscoveryPreferences, int)> savePreferences(DiscoveryPreferences prefs) async {
    final json = await _client.put(ApiEndpoints.preferences, data: prefs.toJson()) as Map<String, dynamic>;
    return (DiscoveryPreferences.fromJson(json), (json['match_count'] as num?)?.toInt() ?? 0);
  }

  Future<List<ReceivedLike>> receivedLikes() async {
    final json = await _client.get(ApiEndpoints.receivedLikes);
    return (json['items'] as List).map((e) => ReceivedLike.fromJson(e as Map<String, dynamic>)).toList();
  }
}
