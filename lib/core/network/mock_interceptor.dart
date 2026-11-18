import 'dart:math';

import 'package:dio/dio.dart';

/// In-memory fake of the Python backend, seeded with the people and
/// conversations from the Lumé design. Disable with --dart-define=USE_MOCK_API=false.
///
/// Demo sign-in: any phone number, verification code 482613.
class MockInterceptor extends Interceptor {
  MockInterceptor() : _db = _MockDb();

  static const demoCode = '482613';

  final _MockDb _db;
  static const _latency = Duration(milliseconds: 450);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future<void>.delayed(_latency);
    try {
      final r = _route(options);
      handler.resolve(Response(requestOptions: options, statusCode: r.$1, data: r.$2), true);
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
    if (m == 'POST' && p == '/auth/phone/start') return (200, {'resend_in': 24});
    if (m == 'POST' && p == '/auth/phone/verify') return (200, _db.verify(body));
    if (m == 'POST' && p == '/auth/login') return (200, _db.verify({'code': demoCode}));
    if (m == 'POST' && p == '/auth/refresh') return (200, _db.tokens());
    if (m == 'POST' && p == '/auth/logout') return (204, null);

    if (!(o.headers['Authorization']?.toString().startsWith('Bearer ') ?? false)) {
      throw const _MockError(401, 'Not authenticated');
    }
    if (m == 'GET' && p == '/auth/me') return (200, _db.user);
    if (m == 'DELETE' && p == '/auth/account') return (204, null);

    // ---- profile ----
    if (p == '/profiles/me') {
      if (m == 'GET') return (200, _db.me);
      if (m == 'PATCH') return (200, _db.updateMe(body));
    }
    if (m == 'GET' && seg.length == 2 && seg[0] == 'profiles') return (200, _db.person(seg[1]));

    // ---- discovery ----
    if (m == 'GET' && p == '/discovery/feed') return (200, {'items': _db.feed()});
    if (m == 'POST' && p == '/discovery/swipe') return (200, _db.swipe(body));
    if (p == '/discovery/preferences') {
      if (m == 'GET') return (200, _db.prefs);
      if (m == 'PUT') {
        _db.prefs = {..._db.prefs, ...body};
        return (200, {..._db.prefs, 'match_count': 42});
      }
    }
    if (m == 'GET' && p == '/likes/received') return (200, {'items': _db.likes()});

    // ---- matches & chat ----
    if (m == 'GET' && p == '/matches') return (200, {'items': _db.matchList()});
    if (seg.length == 2 && seg[0] == 'matches') {
      if (m == 'GET') return (200, _db.matchJson(seg[1]));
      if (m == 'DELETE') {
        _db.unmatch(seg[1]);
        return (204, null);
      }
      if (m == 'PATCH') {
        _db.matches[seg[1]]?.addAll(body);
        return (200, _db.matchJson(seg[1]));
      }
    }
    if (seg.length == 3 && seg[0] == 'matches' && seg[2] == 'messages') {
      if (m == 'GET') return (200, {'items': _db.messagesFor(seg[1])});
      if (m == 'POST') return (201, _db.send(seg[1], body));
    }
    if (seg.length == 3 && seg[0] == 'messages') {
      final msg = _db.findMessage(seg[1]);
      if (seg[2] == 'reaction') msg['reaction'] = body['reaction'];
      if (seg[2] == 'reveal') msg['is_hidden'] = false;
      return (200, msg);
    }

    // ---- settings & safety ----
    if (p == '/settings') {
      if (m == 'PATCH') _db.settings.addAll(body);
      return (200, _db.settings);
    }
    if (m == 'POST' && p == '/safety/block') {
      _db.block(body['user_id'] as String);
      return (204, null);
    }
    if (m == 'POST' && p == '/safety/report') {
      if (body['also_block'] == true) _db.block(body['user_id'] as String);
      return (204, null);
    }

    // ---- relationship ----
    if (seg.isNotEmpty && seg[0] == 'relationship') return _db.relationshipRoute(m, seg, body);

    throw _MockError(404, 'Mock route not found: $m $p');
  }
}

class _MockError implements Exception {
  const _MockError(this.code, this.message);
  final int code;
  final String message;
}

String _iso(DateTime d) => d.toUtc().toIso8601String();
String _ago({int minutes = 0, int hours = 0, int days = 0}) =>
    _iso(DateTime.now().subtract(Duration(minutes: minutes, hours: hours, days: days)));

class _MockDb {
  _MockDb() {
    _seedConversations();
  }

  final _rand = Random();
  int _seq = 100;
  String _id(String prefix) => '$prefix${_seq++}';

  Map<String, dynamic> user = {'id': 'me', 'name': 'Maya', 'email': '', 'is_onboarded': true};

  Map<String, dynamic> me = {
    ..._maya,
    'id': 'me',
    'photos': ['assets/images/maya.jpg', 'assets/images/dunes.jpg', 'assets/images/cafe.jpg', 'assets/images/sea.jpg'],
    'photo_reviews': ['approved', 'approved', 'in_review', 'rejected'],
    'bio': 'Ceramicist by weekend…',
    'prompts': [
      {'question': 'A perfect Sunday looks like', 'answer': 'Farmers market, then calling my sister.'},
    ],
    'interests': ['Ceramics', 'Bookshops', 'Indie folk'],
    'verified_at': '2026-11-02T10:00:00Z',
  };

  Map<String, dynamic> prefs = {
    'min_age': 25,
    'max_age': 34,
    'max_distance_km': 15,
    'interested_in': 'men',
    'looking_for': ['life_partner', 'relationship'],
    'verified_only': true,
    'has_voice_intro': false,
  };

  Map<String, dynamic> settings = {
    'show_in_discover': true,
    'show_online': false,
    'read_receipts': true,
    'approximate_distance': true,
    'hide_photos_until_approved': true,
    'voice_from_matches_only': true,
    'two_step': true,
    'phone_masked': '+44 ••••• ••0123',
    'email': null,
    'blocked_count': 2,
  };

  final Set<String> swiped = {};
  final Set<String> blocked = {};
  final Map<String, Map<String, dynamic>> matches = {};
  final Map<String, List<Map<String, dynamic>>> messages = {};
  Map<String, dynamic>? relationship;
  final List<Map<String, dynamic>> datePlans = [];
  final List<Map<String, dynamic>> memories = [];
  final List<Map<String, dynamic>> checkIns = [];

  // ----------------------------------------------------------------- people
  static const _maya = <String, dynamic>{
    'id': 'u_maya',
    'name': 'Maya',
    'age': 27,
    'gender': 'woman',
    'intent': 'life_partner',
    'job_title': 'Product designer',
    'city': 'London',
    'distance_km': 3,
    'is_verified': true,
    'compatibility': 'In tune',
    'quote': '“Looking for someone to get lost in bookshops with.”',
    'bio': 'Ceramicist by weekend, product designer by weekday. I ask too many questions, and I remember the answers.',
    'photos': ['assets/images/maya.jpg', 'assets/images/cafe.jpg', 'assets/images/dunes.jpg', 'assets/images/sea.jpg'],
    'video_thumb': 'assets/images/sea.jpg',
    'voice': {'prompt': '“The small thing that made me smile today…”', 'seconds': 14},
    'prompts': [
      {
        'question': 'A perfect Sunday looks like',
        'answer': 'Farmers market, an overly ambitious recipe, then calling my sister.',
      },
    ],
    'interests': ['Ceramics', 'Bookshops', 'Indie folk', 'Film photography', 'Cooking', 'Road trips'],
    'activities': ['Throwing pottery', 'Sunrise walks', 'Second-hand bookshops', 'Long dinners'],
    'lifestyle': {
      'sleep': 'Night owl',
      'drinks': 'Sometimes',
      'diet': 'Vegetarian',
      'exercise': 'Twice a week',
      'kids': 'Open to kids',
    },
    'personality': [
      {'left': 'Homebody', 'right': 'Adventurer', 'value': 0.6},
      {'left': 'Planner', 'right': 'Spontaneous', 'value': 0.3},
      {'left': 'Listener', 'right': 'Storyteller', 'value': 0.44},
    ],
    'on_repeat': [
      {'title': 'Slow-burn indie folk', 'note': 'Current mood'},
      {'title': 'Late-night jazz', 'note': 'For cooking'},
      {'title': 'Nineties R&B', 'note': 'Guilty pleasure'},
    ],
    'relationship_goal': 'A life partner. Someone curious and kind, who wants to build something slowly.',
    'starters': [
      'Which bookshop should I visit first?',
      'What’s the last thing you made in the studio?',
      'Pick the album for our road trip.',
    ],
  };

  static Map<String, dynamic> _person(
    String id,
    String name,
    int age,
    String gender,
    String intent,
    double km, {
    String? quote,
    List<String> interests = const [],
    Map<String, String> lifestyle = const {},
    String? voice,
    int voiceSecs = 12,
  }) => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'intent': intent,
    'distance_km': km,
    'is_verified': true,
    'quote': quote,
    'bio': quote?.replaceAll(RegExp('[“”]'), '') ?? '',
    'photos': ['assets/images/${name.toLowerCase()}.jpg', 'assets/images/sea.jpg', 'assets/images/cafe.jpg'],
    'interests': interests,
    'lifestyle': lifestyle,
    'voice': voice == null ? null : {'prompt': voice, 'seconds': voiceSecs},
    'prompts': [
      {'question': 'A perfect Sunday looks like', 'answer': 'Long walk, good coffee, no plans after 4.'},
    ],
    'starters': ['What’s your perfect Sunday?', 'Best song you heard this week?', 'Coffee or tea, and why?'],
  };

  late final Map<String, Map<String, dynamic>> people = {
    'u_maya': _maya,
    'u_leo': _person(
      'u_leo',
      'Leo',
      31,
      'man',
      'relationship',
      5,
      quote: '“Will trade homemade pasta for your best playlist.”',
      interests: ['Cooking', 'Vinyl', 'Cycling'],
      lifestyle: {'exercise': 'Active', 'drinks': 'Socially', 'sleep': 'Early bird'},
      voice: '“My most controversial food opinion…”',
    ),
    'u_daniel': _person(
      'u_daniel',
      'Daniel',
      33,
      'man',
      'life_partner',
      7,
      quote: '“Ask me about the best bakery in every city I’ve visited.”',
      interests: ['Baking', 'Museums', 'Hiking'],
      lifestyle: {'sleep': 'Early bird', 'drinks': 'Rarely', 'diet': 'Everything'},
    ),
    'u_priya': _person(
      'u_priya',
      'Priya',
      29,
      'woman',
      'relationship',
      4,
      quote: '“I laugh at my own jokes. Fair warning.”',
      interests: ['Poetry', 'Yoga', 'Live music'],
      lifestyle: {'sleep': 'Night owl', 'drinks': 'Sometimes', 'diet': 'Vegetarian'},
      voice: '“I laugh at my own jokes. Fair warning.”',
    ),
    'u_amara': _person(
      'u_amara',
      'Amara',
      26,
      'woman',
      'life_partner',
      6,
      quote: '“Sunrise hikes, then a very long breakfast.”',
      interests: ['Hiking', 'Film photography'],
    ),
    'u_kai': _person(
      'u_kai',
      'Kai',
      29,
      'man',
      'relationship',
      9,
      quote: '“Record shops are my love language.”',
      interests: ['Vinyl', 'Board games'],
    ),
    'u_noor': _person(
      'u_noor',
      'Noor',
      28,
      'woman',
      'life_partner',
      2,
      quote: '“Tell me your favourite poem.”',
      interests: ['Poetry', 'Baking'],
    ),
    'u_sofia': _person(
      'u_sofia',
      'Sofia',
      30,
      'woman',
      'new_connections',
      8,
      quote: '“Plant mum, bad singer, great listener.”',
      interests: ['Dogs', 'Yoga'],
    ),
  };

  Map<String, dynamic> person(String id) =>
      id == 'me' ? me : people[id] ?? (throw const _MockError(404, 'Profile not found'));

  // ------------------------------------------------------------------ seeds
  void _seedConversations() {
    final maya = _createMatch('u_maya', daysAgo: 0, online: true);
    final mid = maya['id'] as String;
    messages[mid] = [
      _msg(mid, 'me', 'Which bookshop should I visit first?', minutesAgo: 36),
      _msg(
        mid,
        'u_maya',
        'Okay, big question. The tiny one on Canal Street, without a doubt.',
        minutesAgo: 34,
        reaction: 'heart',
      ),
      _msg(mid, 'me', 'Sold. Do they have a shop cat?', minutesAgo: 32),
      _msg(mid, 'u_maya', '', minutesAgo: 30, type: 'voice', voiceSeconds: 21),
      _msg(mid, 'me', 'Your laugh in that voice note!', minutesAgo: 29),
      _msg(mid, 'u_maya', 'I took this at the studio', minutesAgo: 8),
      _msg(mid, 'u_maya', '', minutesAgo: 8, type: 'photo', media: 'assets/images/cafe.jpg', hidden: true),
      _msg(mid, 'u_maya', 'Saturday at 11, then?', minutesAgo: 4, read: false),
      _msg(mid, 'u_maya', 'Okay, Canal Street it is.', minutesAgo: 2, read: false),
    ];
    final sofia = _createMatch('u_sofia', daysAgo: 3)['id'] as String;
    messages[sofia] = [_msg(sofia, 'u_sofia', '', minutesAgo: 60, type: 'voice', voiceSeconds: 18)];
    final amara = _createMatch('u_amara', daysAgo: 8)['id'] as String;
    messages[amara] = [_msg(amara, 'u_amara', 'That hike looks unreal', minutesAgo: 60 * 24 * 2)];
    final kai = _createMatch('u_kai', daysAgo: 9)['id'] as String;
    messages[kai] = [_msg(kai, 'me', 'Vinyl or streaming?', minutesAgo: 60 * 24 * 3)];
    _createMatch('u_noor', daysAgo: 0);
    _createMatch('u_priya', daysAgo: 1);
    swiped.clear();
  }

  // ------------------------------------------------------------------- auth
  Map<String, dynamic> tokens() => {
    'access_token': 'mock-access-${DateTime.now().millisecondsSinceEpoch}',
    'refresh_token': 'mock-refresh',
    'token_type': 'bearer',
  };

  Map<String, dynamic> verify(Map<String, dynamic> b) {
    if (b['code'] != MockInterceptor.demoCode) {
      throw const _MockError(400, 'That code didn’t match. Check it and try again, or request a new one.');
    }
    // A phone sign-in starts the "Create your profile" flow, as in the design.
    user = {...user, 'is_onboarded': false};
    return {...tokens(), 'user': user};
  }

  Map<String, dynamic> updateMe(Map<String, dynamic> b) {
    final complete = b.remove('complete_onboarding') == true;
    me.addAll(b);
    if (b['name'] != null) user['name'] = b['name'];
    if (complete) user['is_onboarded'] = true;
    return me;
  }

  // -------------------------------------------------------------- discovery
  List<Map<String, dynamic>> feed() {
    const order = ['u_maya', 'u_leo', 'u_daniel'];
    return [
      for (final id in order)
        if (!swiped.contains(id) && !blocked.contains(id)) people[id]!,
    ];
  }

  Map<String, dynamic> swipe(Map<String, dynamic> b) {
    final id = b['target_id'] as String;
    final action = b['action'] as String;
    swiped.add(id);
    if (action == 'pass') return {'is_match': false, 'match': null};
    final existing = matches.values.where((m) => m['profile']['id'] == id);
    if (existing.isNotEmpty) return {'is_match': true, 'match': matchJson(existing.first['id'] as String)};
    final mutual = id == 'u_maya' || action == 'super_like' || _rand.nextDouble() < 0.5;
    if (!mutual) return {'is_match': false, 'match': null};
    return {'is_match': true, 'match': matchJson(_createMatch(id)['id'] as String)};
  }

  List<Map<String, dynamic>> likes() => [
    if (!swiped.contains('u_amara'))
      {
        'profile': people['u_amara'],
        'liked_at': _ago(hours: 3),
        'kind': 'super_like',
        'reason': 'Liked your voice intro',
      },
    if (!swiped.contains('u_daniel'))
      {
        'profile': people['u_daniel'],
        'liked_at': _ago(hours: 6),
        'kind': 'compliment',
        'reason': 'Liked your Sunday answer',
        'comment': 'An overly ambitious recipe is my favourite kind.',
      },
    if (!swiped.contains('u_kai'))
      {'profile': people['u_kai'], 'liked_at': _ago(days: 1), 'kind': 'like', 'reason': 'Liked your photo'},
    if (!swiped.contains('u_leo'))
      {'profile': people['u_leo'], 'liked_at': _ago(days: 2), 'kind': 'like', 'reason': 'Liked your photo'},
  ];

  // ---------------------------------------------------------------- matches
  Map<String, dynamic> _createMatch(String profileId, {int daysAgo = 0, bool online = false}) {
    final id = _id('m');
    matches[id] = {
      'id': id,
      'profile': person(profileId),
      'matched_at': _ago(days: daysAgo),
      'is_online': online,
      'is_muted': false,
    };
    swiped.add(profileId);
    return matches[id]!;
  }

  Map<String, dynamic> matchJson(String id) {
    final m = matches[id] ?? (throw const _MockError(404, 'Match not found'));
    final msgs = messages[id] ?? const [];
    return {
      ...m,
      'last_message': msgs.isEmpty ? null : msgs.last,
      'unread_count': msgs.where((e) => e['sender_id'] != 'me' && e['is_read'] != true).length,
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

  void block(String userId) {
    blocked.add(userId);
    swiped.add(userId);
    matches.removeWhere((_, m) => m['profile']['id'] == userId);
    settings['blocked_count'] = (settings['blocked_count'] as int) + 1;
  }

  Map<String, dynamic> _msg(
    String matchId,
    String sender,
    String text, {
    int minutesAgo = 0,
    String type = 'text',
    String? media,
    int? voiceSeconds,
    String? reaction,
    bool hidden = false,
    bool read = true,
  }) => {
    'id': _id('msg'),
    'match_id': matchId,
    'sender_id': sender,
    'type': type,
    'text': text,
    'media_url': media,
    'voice_seconds': voiceSeconds,
    'reaction': reaction,
    'is_hidden': hidden,
    'sent_at': _ago(minutes: minutesAgo),
    'is_read': read,
  };

  List<Map<String, dynamic>> messagesFor(String matchId) {
    if (!matches.containsKey(matchId)) throw const _MockError(404, 'Match not found');
    final list = messages[matchId] ?? [];
    for (final e in list) {
      e['is_read'] = true;
    }
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> findMessage(String id) {
    for (final list in messages.values) {
      for (final msg in list) {
        if (msg['id'] == id) return msg;
      }
    }
    throw const _MockError(404, 'Message not found');
  }

  Map<String, dynamic> send(String matchId, Map<String, dynamic> b) {
    if (!matches.containsKey(matchId)) throw const _MockError(404, 'Match not found');
    final msg = _msg(
      matchId,
      'me',
      b['text'] as String? ?? '',
      type: b['type'] as String? ?? 'text',
      media: b['media_url'] as String?,
    );
    (messages[matchId] ??= []).add(msg);
    final partnerId = matches[matchId]!['profile']['id'] as String;
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!matches.containsKey(matchId)) return;
      const replies = ['Haha, I love that.', 'Tell me more!', 'Okay, you’ve convinced me.', 'Saturday works for me ☺️'];
      messages[matchId]!.add(_msg(matchId, partnerId, replies[_rand.nextInt(replies.length)], read: false));
    });
    return msg;
  }

  // ----------------------------------------------------------- relationship
  (int, dynamic) relationshipRoute(String m, List<String> seg, Map<String, dynamic> b) {
    final sub = seg.length > 1 ? seg[1] : '';
    if (sub.isEmpty && m == 'GET') return (200, relationship ?? {'status': 'none'});
    if (sub == 'request') {
      final match = matches[b['match_id']] ?? (throw const _MockError(404, 'Match not found'));
      relationship = {
        'id': _id('rel'),
        'status': 'active',
        'partner': match['profile'],
        'started_at': _iso(DateTime.now()),
      };
      return (200, relationship);
    }
    if (sub == 'respond') return (200, relationship ?? {'status': 'none'});
    if (sub == 'end') {
      relationship = null;
      return (204, null);
    }
    final list = switch (sub) {
      'date-plans' => datePlans,
      'memories' => memories,
      _ => checkIns,
    };
    if (m == 'GET') return (200, {'items': list});
    if (seg.length == 3) {
      final item = list.firstWhere((e) => e['id'] == seg[2], orElse: () => throw const _MockError(404, 'Not found'));
      item.addAll(b);
      return (200, item);
    }
    final created = {
      'id': _id('x'),
      ...b,
      if (sub == 'date-plans') 'status': 'planned',
      if (sub == 'check-ins') ...{'user_id': 'me', 'created_at': _iso(DateTime.now())},
    };
    list.insert(0, created);
    return (201, created);
  }
}
