import 'package:flutter/material.dart';

/// A page route that transitions by fading the new page in.
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 100),
          reverseTransitionDuration: const Duration(milliseconds: 100),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// A page route that transitions by sliding the new page in from the right.
/// This is typically used for forward navigation.
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          // Use a custom reverse transition to slide out to the right when popping.
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Animation for pushing the new screen
            final slideInAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.ease,
            ));

            // Animation for popping the current screen
            final slideOutAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.0, 0.0), // Slide out to the right
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.ease,
            ));

            return SlideTransition(
              position: animation.status == AnimationStatus.reverse
                  ? slideOutAnimation
                  : slideInAnimation,
              child: child,
            );
          },
        );
}

/// A page route that transitions by sliding the new page in from the left.
/// Typically used when opening a drawer or panel from the left side.
class SlideLeftRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideLeftRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Animation for pushing the new screen (from left)
            final slideInAnimation = Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.ease,
            ));

            // Animation for popping the current screen (to left)
            final slideOutAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.ease,
            ));

            return SlideTransition(
              position: animation.status == AnimationStatus.reverse
                  ? slideOutAnimation
                  : slideInAnimation,
              child: child,
            );
          },
        );
}
