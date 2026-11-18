import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/relationship.dart';

class RelationshipRepository {
  RelationshipRepository(this._client);

  final DioClient _client;

  Future<Relationship> current() async {
    final json = await _client.get(ApiEndpoints.relationship);
    return Relationship.fromJson(json as Map<String, dynamic>?);
  }

  /// Ask a match to become your partner in the app.
  Future<Relationship> request(String matchId) async {
    final json = await _client.post(ApiEndpoints.relationshipRequest, data: {'match_id': matchId});
    return Relationship.fromJson(json as Map<String, dynamic>);
  }

  Future<Relationship> respond({required bool accept}) async {
    final json = await _client.post(ApiEndpoints.relationshipRespond, data: {'accept': accept});
    return Relationship.fromJson(json as Map<String, dynamic>?);
  }

  Future<void> end() => _client.post(ApiEndpoints.relationshipEnd);

  Future<List<DatePlan>> datePlans() async {
    final json = await _client.get(ApiEndpoints.datePlans);
    return (json['items'] as List).map((e) => DatePlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DatePlan> addDatePlan({
    required String title,
    required DateTime scheduledAt,
    String? place,
    String? notes,
  }) async {
    final json = await _client.post(
      ApiEndpoints.datePlans,
      data: {'title': title, 'scheduled_at': scheduledAt.toUtc().toIso8601String(), 'place': place, 'notes': notes},
    );
    return DatePlan.fromJson(json as Map<String, dynamic>);
  }

  Future<DatePlan> updateDatePlanStatus(String id, DatePlanStatus status) async {
    final json = await _client.patch(ApiEndpoints.datePlan(id), data: {'status': status.value});
    return DatePlan.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Memory>> memories() async {
    final json = await _client.get(ApiEndpoints.memories);
    return (json['items'] as List).map((e) => Memory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Memory> addMemory({required String title, required DateTime date, String? note, String? photoUrl}) async {
    final json = await _client.post(
      ApiEndpoints.memories,
      data: {'title': title, 'date': date.toUtc().toIso8601String(), 'note': note, 'photo_url': photoUrl},
    );
    return Memory.fromJson(json as Map<String, dynamic>);
  }

  Future<List<CheckIn>> checkIns() async {
    final json = await _client.get(ApiEndpoints.checkIns);
    return (json['items'] as List).map((e) => CheckIn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CheckIn> addCheckIn(Mood mood, {String? note}) async {
    final json = await _client.post(ApiEndpoints.checkIns, data: {'mood': mood.value, 'note': note});
    return CheckIn.fromJson(json as Map<String, dynamic>);
  }
}
