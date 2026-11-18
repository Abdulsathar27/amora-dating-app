import 'package:equatable/equatable.dart';

import 'profile.dart';

enum RelationshipStatus {
  none('none'),
  pendingSent('pending_sent'),
  pendingReceived('pending_received'),
  active('active');

  const RelationshipStatus(this.value);
  final String value;

  static RelationshipStatus fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => RelationshipStatus.none);
}

/// Two matched users who agreed to be a couple in the app.
class Relationship extends Equatable {
  const Relationship({required this.id, required this.status, this.partner, this.startedAt});

  static const empty = Relationship(id: '', status: RelationshipStatus.none);

  final String id;
  final RelationshipStatus status;
  final Profile? partner;
  final DateTime? startedAt;

  int get daysTogether => startedAt == null ? 0 : DateTime.now().difference(startedAt!).inDays;

  /// Next yearly anniversary of [startedAt].
  DateTime? get nextAnniversary {
    if (startedAt == null) return null;
    final now = DateTime.now();
    var next = DateTime(now.year, startedAt!.month, startedAt!.day);
    if (!next.isAfter(now)) next = DateTime(now.year + 1, startedAt!.month, startedAt!.day);
    return next;
  }

  factory Relationship.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty;
    return Relationship(
      id: json['id']?.toString() ?? '',
      status: RelationshipStatus.fromValue(json['status'] as String?),
      partner: json['partner'] == null ? null : Profile.fromJson(json['partner'] as Map<String, dynamic>),
      startedAt: json['started_at'] == null ? null : DateTime.parse(json['started_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, status, partner, startedAt];
}

enum DatePlanStatus {
  planned('planned'),
  done('done'),
  cancelled('cancelled');

  const DatePlanStatus(this.value);
  final String value;

  static DatePlanStatus fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => DatePlanStatus.planned);
}

class DatePlan extends Equatable {
  const DatePlan({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.place,
    this.notes,
    this.status = DatePlanStatus.planned,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final String? place;
  final String? notes;
  final DatePlanStatus status;

  factory DatePlan.fromJson(Map<String, dynamic> json) => DatePlan(
    id: json['id'].toString(),
    title: json['title'] as String,
    scheduledAt: DateTime.parse(json['scheduled_at'] as String),
    place: json['place'] as String?,
    notes: json['notes'] as String?,
    status: DatePlanStatus.fromValue(json['status'] as String?),
  );

  @override
  List<Object?> get props => [id, title, scheduledAt, place, notes, status];
}

class Memory extends Equatable {
  const Memory({required this.id, required this.title, required this.date, this.note, this.photoUrl});

  final String id;
  final String title;
  final DateTime date;
  final String? note;
  final String? photoUrl;

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
    id: json['id'].toString(),
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String?,
    photoUrl: json['photo_url'] as String?,
  );

  @override
  List<Object?> get props => [id, title, date, note, photoUrl];
}

enum Mood {
  great('great', '😍'),
  good('good', '😊'),
  okay('okay', '😐'),
  low('low', '😔'),
  upset('upset', '😤');

  const Mood(this.value, this.emoji);
  final String value;
  final String emoji;

  static Mood fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => Mood.okay);
}

/// Daily mood check-in shared between partners.
class CheckIn extends Equatable {
  const CheckIn({required this.id, required this.userId, required this.mood, required this.createdAt, this.note});

  final String id;
  final String userId;
  final Mood mood;
  final DateTime createdAt;
  final String? note;

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    mood: Mood.fromValue(json['mood'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    note: json['note'] as String?,
  );

  @override
  List<Object?> get props => [id, userId, mood, createdAt, note];
}
