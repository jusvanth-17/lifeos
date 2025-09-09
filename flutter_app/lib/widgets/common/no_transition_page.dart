import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A custom page that removes all transition animations
class NoTransitionPage<T> extends CustomTransitionPage<T> {
  const NoTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionsBuilder: _transitionsBuilder,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Return the child directly without any animation
    return child;
  }
}

/// Helper function to create a NoTransitionPage
NoTransitionPage<void> buildNoTransitionPage({
  required Widget child,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
}) {
  return NoTransitionPage<void>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    child: child,
  );
}
