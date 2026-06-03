import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Login Screen (NestJS REST auth integration)')),
      ),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        // Here we'd embed the AdaptiveScaffold wrapping the child view
        return Scaffold(
          body: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Center(child: Text('Welcome to QRIMS')),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const Center(child: Text('Shopping Cart & Scanning')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Center(child: Text('Settings (Offline Drift Cache)')),
        ),
      ],
    ),
  ],
);
