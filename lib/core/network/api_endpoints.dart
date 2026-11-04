/// Every REST path the app calls. Mirrors docs/API_CONTRACT.md for the Python backend.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Profile
  static const String myProfile = '/profiles/me';
  static String profile(String id) => '/profiles/$id';

  // Discovery (swipe deck)
  static const String feed = '/discovery/feed';
  static const String swipe = '/discovery/swipe';
  static const String rewind = '/discovery/rewind';
  static const String preferences = '/discovery/preferences';

  // Likes you
  static const String receivedLikes = '/likes/received';

  // Matches & chat
  static const String matches = '/matches';
  static String match(String id) => '/matches/$id';
  static String messages(String matchId) => '/matches/$matchId/messages';

  // Relationship ("Us" couple space)
  static const String relationship = '/relationship';
  static const String relationshipRequest = '/relationship/request';
  static const String relationshipRespond = '/relationship/respond';
  static const String relationshipEnd = '/relationship/end';
  static const String datePlans = '/relationship/date-plans';
  static String datePlan(String id) => '/relationship/date-plans/$id';
  static const String memories = '/relationship/memories';
  static const String checkIns = '/relationship/check-ins';
}
