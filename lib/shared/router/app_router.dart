import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:thesis/feature/instruction/presentation/page/instruction_screen.dart';
import 'package:thesis/feature/splash/presentation/page/splash_screen.dart';
import 'package:thesis/feature/verification/presentation/page/verification_screen.dart';
import 'package:thesis/shared/router/router_key.dart';
import 'package:go_router/go_router.dart';

import '../../feature/start/presentation/page/start_screen.dart';
import 'fade_transition.dart';

class AppRouter {
  AppRouter._();

  static AppRouter? _instance;

  static AppRouter get shareInstance {
    _instance ??= AppRouter._();
    return _instance!;
  }

  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKeyManager.instance.root;
  late final router = GoRouter(
    initialLocation: initRouter(),
    navigatorKey: GlobalKeyManager.instance.root,
    debugLogDiagnostics: kDebugMode,
    routes: <RouteBase>[
      GoRoute(
        path: RouterPath.splashScreen,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return buildFadeTransition(
            context: context,
            state: state,
            child: const SplashScreen(),
          );
        },
      ),
      GoRoute(
        path: RouterPath.home,
        builder: (BuildContext context, GoRouterState state) {
          return const StartScreen();
        },
      ),

      GoRoute(
        path: RouterPath.introduce,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['id'] as String?;
          return buildFadeTransition(
            context: context,
            state: state,
            child: InstructionScreen(id: id ?? ''),
          );
        },
      ),
      GoRoute(
        path: RouterPath.verification,
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>?;
          final mssv = extra?['mssv'] as String? ?? '';
          return VerificationScreen(mssv: mssv);
        },
      ),
    ],
  );
}

String? initRouter() {
  return RouterPath.splashScreen;
}
