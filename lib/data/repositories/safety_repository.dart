import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/settings.dart';

/// Privacy settings, blocking and reporting.
class SafetyRepository {
  SafetyRepository(this._client);

  final DioClient _client;

  Future<AppSettings> settings() async =>
      AppSettings.fromJson(await _client.get(ApiEndpoints.settings) as Map<String, dynamic>);

  Future<AppSettings> updateSetting(String key, bool value) async =>
      AppSettings.fromJson(await _client.patch(ApiEndpoints.settings, data: {key: value}) as Map<String, dynamic>);

  /// Blocks the person. They are not told, and the conversation is removed.
  Future<void> block(String userId) => _client.post(ApiEndpoints.block, data: {'user_id': userId});

  Future<void> report({required String userId, required ReportReason reason, String? details, bool alsoBlock = true}) =>
      _client.post(
        ApiEndpoints.report,
        data: {'user_id': userId, 'reason': reason.value, 'details': ?details, 'also_block': alsoBlock},
      );
}
