import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/lume_tokens.dart';

/// Page transitions from the design's prototype links:
/// push 280ms ease-in-out (exit ~30% faster), dissolve 220ms, move-in 300ms ease-out.
/// With reduced motion every transition becomes a 150ms fade.
class LumeTransitions {
  LumeTransitions._();

  static Widget _reduced(BuildContext context, Animation<double> a, Widget child, Widget Function() full) =>
      LumeMotion.reduceMotion(context) ? FadeTransition(opacity: a, child: child) : full();

  /// Horizontal push with a slight parallax on the screen underneath.
  static Page<void> push(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: LumeMotion.push,
    reverseTransitionDuration: LumeMotion.pushExit,
    transitionsBuilder:
        (context, a, secondary, child) => _reduced(context, a, child, () {
          final inCurve = CurvedAnimation(parent: a, curve: Curves.easeInOut, reverseCurve: Curves.easeIn);
          final outCurve = CurvedAnimation(parent: secondary, curve: Curves.easeInOut);
          return SlideTransition(
            position: Tween(begin: Offset.zero, end: const Offset(-0.25, 0)).animate(outCurve),
            child: SlideTransition(
              position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(inCurve),
              child: DecoratedBox(decoration: const BoxDecoration(boxShadow: LumeShadows.card), child: child),
            ),
          );
        }),
  );

  static Page<void> dissolve(GoRouterState state, Widget child, {Duration duration = LumeMotion.dissolve}) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: LumeMotion.dissolve,
    transitionsBuilder: (context, a, _, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
  );

  /// Slides up from the bottom (filters, full profile).
  static Page<void> moveIn(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: LumeMotion.sheet,
    reverseTransitionDuration: LumeMotion.pushExit,
    transitionsBuilder:
        (context, a, _, child) => _reduced(context, a, child, () {
          final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
          return SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curve), child: child);
        }),
  );
}
