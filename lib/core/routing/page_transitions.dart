import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomPageTransitions {
  /// Standard page transition: Fade + Vertical Slide (16px) + Scale (0.98 -> 1.0)
  static CustomTransitionPage<T> buildFadeScaleSlidePage<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
        );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);
        final scaleAnimation = Tween<double>(
          begin: 0.97,
          end: 1.0,
        ).animate(curvedAnimation);
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 20.0 / 800.0), // ~20px
          end: Offset.zero,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
    );
  }

  /// iOS-style Drill Down Push Transition (Slide from right)
  static CustomTransitionPage<T> buildDrillDownPage<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }
}
