import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final DioClient _client;

  Future<Profile> myProfile() async {
    final json = await _client.get(ApiEndpoints.myProfile);
    return Profile.fromJson(json as Map<String, dynamic>);
  }

  /// Partial update; send only changed fields. `complete_onboarding: true` flips is_onboarded.
  Future<Profile> updateMyProfile(Map<String, dynamic> changes) async {
    final json = await _client.patch(ApiEndpoints.myProfile, data: changes);
    return Profile.fromJson(json as Map<String, dynamic>);
  }

  Future<Profile> profileById(String id) async {
    final json = await _client.get(ApiEndpoints.profile(id));
    return Profile.fromJson(json as Map<String, dynamic>);
  }
}
