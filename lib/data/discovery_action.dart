import 'models/discovery.dart';

/// What the Full profile screen pops with: a swipe action, optionally with a compliment.
class DiscoveryActionResult {
  const DiscoveryActionResult(this.action, {this.comment});

  final SwipeAction action;
  final String? comment;

  bool get isLike => action != SwipeAction.pass;

  static DiscoveryActionResult? from(Object? result) => switch (result) {
    DiscoveryActionResult r => r,
    SwipeAction a => DiscoveryActionResult(a),
    _ => null,
  };
}
