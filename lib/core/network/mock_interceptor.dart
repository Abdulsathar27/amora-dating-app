import 'dart:math';

import 'package:dio/dio.dart';

/// In-memory fake of the Python backend so the app runs end-to-end before the
/// server exists. Disable with --dart-define=USE_MOCK_API=false.
///
/// It speaks exactly the JSON described in docs/API_CONTRACT.md.
class MockInterceptor extends Interceptor {
  MockInterceptor() : _db = _MockDb();

  final _MockDb _db;
  static const _latency = Duration(milliseconds: 350);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future<void>.delayed(_latency);
    try {
      final result = _route(options);
      handler.resolve(Response(requestOptions: options, statusCode: result.$1, data: result.$2), true);
    } on _MockError catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: e.code, data: {'detail': e.message}),
        ),
        true,
      );
    }
  }

  (int, dynamic) _route(RequestOptions o) {
    final m = o.method.toUpperCase();
    final p = o.path;
    final body = (o.data is Map) ? Map<String, dynamic>.from(o.data as Map) : <String, dynamic>{};
    final seg = p.split('/').where((s) => s.isNotEmpty).toList();

    // ---- auth ----
    if (m == 'POST' && p == '/auth/login') return (200, _db.login(body));
    if (m == 'POST' && p == '/auth/register') return (201, _db.register(body));
    if (m == 'POST' && p == '/auth/refresh') return (200, _db.tokens());
    if (m == 'POST' && p == '/auth/logout') return (204, null);

    if (!(o.headers['Authorization']?.toString().startsWith('Bearer ') ?? false)) {
      throw const _MockError(401, 'Not authenticated');
    }
    if (m == 'GET' && p == '/auth/me') return (200, _db.user);

    // ---- profile ----
    if (p == '/profiles/me') {
      if (m == 'GET') return (200, _db.me);
      if (m == 'PATCH') return (200, _db.updateMe(body));
    }
    if (m == 'GET' && seg.length == 2 && seg[0] == 'profiles') return (200, _db.profileById(seg[1]));

    // ---- discovery ----
    if (m == 'GET' && p == '/discovery/feed') return (200, {'items': _db.feed()});
    if (m == 'POST' && p == '/discovery/swipe') return (200, _db.swipe(body));
    if (m == 'POST' && p == '/discovery/rewind') return (200, _db.rewind());
    if (p == '/discovery/preferences') {
      if (m == 'GET') return (200, _db.prefs);
      if (m == 'PUT') return (200, _db.prefs = {..._db.prefs, ...body});
    }
    if (m == 'GET' && p == '/likes/received') return (200, {'items': _db.receivedLikes()});

    // ---- matches & chat ----
    if (m == 'GET' && p == '/matches') return (200, {'items': _db.matchList()});
    if (seg.length == 2 && seg[0] == 'matches' && m == 'DELETE') {
      _db.unmatch(seg[1]);
      return (204, null);
    }
    if (seg.length == 3 && seg[0] == 'matches' && seg[2] == 'messages') {
      if (m == 'GET') return (200, {'items': _db.messagesFor(seg[1])});
      if (m == 'POST') return (201, _db.send(seg[1], body['text'] as String));
    }

    // ---- relationship ----
    if (p == '/relationship' && m == 'GET') return (200, _db.relationshipJson());
    if (p == '/relationship/request' && m == 'POST') return (200, _db.requestRelationship(body['match_id'] as String));
    if (p == '/relationship/respond' && m == 'POST') return (200, _db.respond(body['accept'] == true));
    if (p == '/relationship/end' && m == 'POST') {
      _db.relationship = null;
      return (204, null);
    }
    if (p == '/relationship/date-plans') {
      if (m == 'GET') return (200, {'items': _db.datePlans});
      if (m == 'POST') return (201, _db.addTo(_db.datePlans, {...body, 'status': 'planned'}));
    }
    if (seg.length == 3 && seg[1] == 'date-plans' && m == 'PATCH') {
      final plan = _db.datePlans.firstWhere((e) => e['id'] == seg[2], orElse: () => throw const _MockError(404, 'Not found'));
      plan.addAll(body);
      return (200, plan);
    }
    if (p == '/relationship/memories') {
      if (m == 'GET') return (200, {'items': _db.memories});
      if (m == 'POST') return (201, _db.addTo(_db.memories, body));
    }
    if (p == '/relationship/check-ins') {
      if (m == 'GET') return (200, {'items': _db.checkIns});
      if (m == 'POST') {
        return (201, _db.addTo(_db.checkIns, {...body, 'user_id': _db.user['id'], 'created_at': _now()}));
      }
    }

    throw _MockError(404, 'Mock route not found: $m $p');
  }
}

String _now() => DateTime.now().toUtc().toIso8601String();

class _MockError implements Exception {
  const _MockError(this.code, this.message);
  final int code;
  final String message;
}

class _MockDb {
  _MockDb() {
    likedMe.addAll(['p2', 'p4', 'p6']);
    final m = _createMatch('p7', daysAgo: 3);
    messages[m['id'] as String] = [
      _msg(m['id'] as String, 'p7', 'Hey! Your hiking photo is amazing 🏔️', minutesAgo: 90),
      _msg(m['id'] as String, 'me', 'Thanks! That was Munnar last spring', minutesAgo: 80),
      _msg(m['id'] as String, 'p7', 'No way, I have been wanting to go. Tips?', minutesAgo: 5),
    ];
    _createMatch('p8', daysAgo: 0);
  }

  final _rand = Random();
  int _seq = 100;
  String _id(String prefix) => '$prefix${_seq++}';

  Map<String, dynamic> user = {'id': 'me', 'name': 'You', 'email': 'you@amora.app', 'is_onboarded': false};

  Map<String, dynamic> me = {
    'id': 'me',
    'name': 'You',
    'age': 26,
    'bio': '',
    'gender': 'man',
    'intent': 'long_term',
    'city': 'Kochi',
    'photos': <String>['https://randomuser.me/api/portraits/men/32.jpg'],
    'prompts': <Map<String, dynamic>>[],
    'interests': <String>[],
    'is_verified': false,
  };

  Map<String, dynamic> prefs = {
    'min_age': 21,
    'max_age': 35,
    'max_distance_km': 30,
    'interested_in': 'everyone',
    'verified_only': false,
  };

  final List<Map<String, dynamic>> profiles = [
    _p('p1', 'Ananya', 25, 'women/44', 'Product designer', 'long_term', 3.2, ['Design', 'Coffee', 'Travel'],
        'A perfect Sunday', 'Filter coffee, a bookstore and a long walk by the beach.'),
    _p('p2', 'Meera', 27, 'women/68', 'Doctor', 'marriage', 5.0, ['Yoga', 'Cooking', 'Music'],
        'I geek out on', 'Kerala food history and old Malayalam songs.'),
    _p('p3', 'Riya', 24, 'women/12', 'Software engineer', 'figuring_out', 1.4, ['Gaming', 'Anime', 'Running'],
        'Two truths and a lie', 'I ran a marathon, I can juggle, I hate biryani.'),
    _p('p4', 'Sara', 28, 'women/90', 'Architect', 'long_term', 8.7, ['Photography', 'Hiking', 'Art'],
        'My love language is', 'Planning surprise weekend trips.'),
    _p('p5', 'Aditya', 29, 'men/45', 'Chef', 'long_term', 4.1, ['Food', 'Cricket', 'Movies'],
        'Best way to win me over', 'Bring dessert. Always dessert.'),
    _p('p6', 'Nisha', 26, 'women/33', 'Teacher', 'marriage', 12.0, ['Reading', 'Dance', 'Pets'],
        'I am looking for', 'Someone kind to animals and patient with my plant obsession.'),
    _p('p7', 'Fathima', 25, 'women/21', 'Marketing lead', 'long_term', 2.0, ['Hiking', 'Podcasts', 'Tea'],
        'Green flags I look for', 'Good listener, laughs at their own jokes.'),
    _p('p8', 'Kavya', 27, 'women/55', 'Data analyst', 'short_term', 6.3, ['Board games', 'Baking'],
        'Unpopular opinion', 'Pineapple belongs on pizza.'),
  ];

  final Set<String> swiped = {};
  final Set<String> likedMe = {};
  String? lastPassed;
  final Map<String, Map<String, dynamic>> matches = {};
  final Map<String, List<Map<String, dynamic>>> messages = {};
  Map<String, dynamic>? relationship;
  DateTime? _requestedAt;
  final List<Map<String, dynamic>> datePlans = [];
  final List<Map<String, dynamic>> memories = [];
  final List<Map<String, dynamic>> checkIns = [];

  static Map<String, dynamic> _p(String id, String name, int age, String photo, String job, String intent,
          double km, List<String> interests, String q, String a) =>
      {
        'id': id,
        'name': name,
        'age': age,
        'bio': 'Hi, I am $name. $job by day, explorer by weekend.',
        'gender': photo.startsWith('men') ? 'man' : 'woman',
        'intent': intent,
        'job_title': job,
        'city': 'Kochi',
        'distance_km': km,
        'height_cm': 160 + age % 20,
        'is_verified': age.isOdd,
        'photos': [
          'https://randomuser.me/api/portraits/$photo.jpg',
          'https://picsum.photos/seed/$id-a/600/800',
          'https://picsum.photos/seed/$id-b/600/800',
        ],
        'prompts': [
          {'question': q, 'answer': a},
        ],
        'interests': interests,
      };

  Map<String, dynamic> tokens() => {
        'access_token': 'mock-access-${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock-refresh',
        'token_type': 'bearer',
      };

  Map<String, dynamic> login(Map<String, dynamic> b) {
    if ((b['password'] as String? ?? '').length < 6) throw const _MockError(401, 'Incorrect email or password');
    user = {...user, 'email': b['email'], 'is_onboarded': true};
    if ((me['bio'] as String).isEmpty) me['bio'] = 'Coffee, code and long drives.';
    return {...tokens(), 'user': user};
  }

  Map<String, dynamic> register(Map<String, dynamic> b) {
    user = {'id': 'me', 'name': b['name'], 'email': b['email'], 'is_onboarded': false};
    me['name'] = b['name'];
    return {...tokens(), 'user': user};
  }

  Map<String, dynamic> updateMe(Map<String, dynamic> b) {
    final complete = b.remove('complete_onboarding') == true;
    me.addAll(b);
    if (b['name'] != null) user['name'] = b['name'];
    if (complete) user['is_onboarded'] = true;
    return me;
  }

  Map<String, dynamic> profileById(String id) =>
      id == 'me' ? me : profiles.firstWhere((e) => e['id'] == id, orElse: () => throw const _MockError(404, 'Profile not found'));

  List<Map<String, dynamic>> feed() {
    final minAge = prefs['min_age'] as int;
    final maxAge = prefs['max_age'] as int;
    final km = (prefs['max_distance_km'] as num).toDouble();
    final want = prefs['interested_in'];
    return profiles.where((p) {
      if (swiped.contains(p['id']) || matches.values.any((m) => m['profile']['id'] == p['id'])) return false;
      final age = p['age'] as int;
      if (age < minAge || age > maxAge) return false;
      if ((p['distance_km'] as num) > km) return false;
      if (want == 'men' && p['gender'] != 'man') return false;
      if (want == 'women' && p['gender'] != 'woman') return false;
      if (prefs['verified_only'] == true && p['is_verified'] != true) return false;
      return true;
    }).toList();
  }

  Map<String, dynamic> swipe(Map<String, dynamic> b) {
    final id = b['target_id'] as String;
    final action = b['action'] as String;
    swiped.add(id);
    if (action == 'pass') {
      lastPassed = id;
      return {'is_match': false, 'match': null};
    }
    lastPassed = null;
    final mutual = likedMe.remove(id) || _rand.nextDouble() < 0.35;
    if (!mutual) return {'is_match': false, 'match': null};
    return {'is_match': true, 'match': _createMatch(id)};
  }

  Map<String, dynamic> rewind() {
    final id = lastPassed;
    if (id == null) throw const _MockError(409, 'Nothing to rewind');
    swiped.remove(id);
    lastPassed = null;
    return profileById(id);
  }

  List<Map<String, dynamic>> receivedLikes() => likedMe
      .where((id) => !swiped.contains(id))
      .map((id) => {
            'profile': profileById(id),
            'liked_at': DateTime.now().subtract(const Duration(hours: 5)).toUtc().toIso8601String(),
            'is_super_like': id == 'p2',
            'comment': id == 'p4' ? 'Love your travel photos!' : null,
          })
      .toList();

  Map<String, dynamic> _createMatch(String profileId, {int daysAgo = 0}) {
    final id = _id('m');
    final at = DateTime.now().subtract(Duration(days: daysAgo));
    matches[id] = {
      'id': id,
      'profile': profileById(profileId),
      'matched_at': at.toUtc().toIso8601String(),
      'expires_at': at.add(const Duration(hours: 24)).toUtc().toIso8601String(),
      'can_send_first_message': true,
    };
    swiped.add(profileId);
    return matchJson(id);
  }

  Map<String, dynamic> matchJson(String id) {
    final m = matches[id]!;
    final msgs = messages[id] ?? const [];
    return {
      ...m,
      'last_message': msgs.isEmpty ? null : msgs.last,
      'unread_count': msgs.where((e) => e['sender_id'] != 'me' && e['is_read'] != true).length,
      if (msgs.isNotEmpty) 'expires_at': null,
    };
  }

  List<Map<String, dynamic>> matchList() {
    final list = matches.keys.map(matchJson).toList();
    String key(Map<String, dynamic> m) => (m['last_message']?['sent_at'] ?? m['matched_at']) as String;
    list.sort((a, b) => key(b).compareTo(key(a)));
    return list;
  }

  void unmatch(String id) {
    matches.remove(id);
    messages.remove(id);
  }

  Map<String, dynamic> _msg(String matchId, String sender, String text, {int minutesAgo = 0}) => {
        'id': _id('msg'),
        'match_id': matchId,
        'sender_id': sender,
        'text': text,
        'sent_at': DateTime.now().subtract(Duration(minutes: minutesAgo)).toUtc().toIso8601String(),
        'is_read': sender == 'me',
      };

  List<Map<String, dynamic>> messagesFor(String matchId) {
    if (!matches.containsKey(matchId)) throw const _MockError(404, 'Match not found');
    final list = messages[matchId] ?? [];
    for (final e in list) {
      e['is_read'] = true;
    }
    return List.of(list);
  }

  Map<String, dynamic> send(String matchId, String text) {
    if (!matches.containsKey(matchId)) throw const _MockError(404, 'Match not found');
    final msg = _msg(matchId, 'me', text);
    (messages[matchId] ??= []).add(msg);
    final partnerId = matches[matchId]!['profile']['id'] as String;
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!matches.containsKey(matchId)) return;
      const replies = ['Haha that is so true 😄', 'Tell me more!', 'Coffee this weekend?', 'Love that ❤️'];
      messages[matchId]!.add(_msg(matchId, partnerId, replies[_rand.nextInt(replies.length)]));
    });
    return msg;
  }

  Map<String, dynamic>? relationshipJson() {
    final r = relationship;
    // Simulate the partner accepting a few seconds after the request.
    if (r != null && r['status'] == 'pending_sent' && _requestedAt != null &&
        DateTime.now().difference(_requestedAt!) > const Duration(seconds: 8)) {
      r['status'] = 'active';
      r['started_at'] = _now();
    }
    return r ?? {'status': 'none'};
  }

  Map<String, dynamic> requestRelationship(String matchId) {
    final m = matches[matchId];
    if (m == null) throw const _MockError(404, 'Match not found');
    if (relationship != null) throw const _MockError(409, 'You are already in a relationship');
    _requestedAt = DateTime.now();
    return relationship = {'id': _id('rel'), 'status': 'pending_sent', 'partner': m['profile'], 'started_at': null};
  }

  Map<String, dynamic> respond(bool accept) {
    final r = relationship;
    if (r == null) throw const _MockError(404, 'No pending request');
    if (!accept) {
      relationship = null;
      return {'status': 'none'};
    }
    r['status'] = 'active';
    r['started_at'] = _now();
    return r;
  }

  Map<String, dynamic> addTo(List<Map<String, dynamic>> list, Map<String, dynamic> item) {
    final created = {'id': _id('x'), ...item};
    list.insert(0, created);
    return created;
  }
}
