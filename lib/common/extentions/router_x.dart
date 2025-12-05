import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

extension GoRouterX on BuildContext {
  Future<T?> pushWithPath<T extends Object?>(
      String path, {
        dynamic param,
        Map<String, dynamic>? extra,
      }) async {
    return await push(
      param == null ? path : '$path/$param',
      extra: extra,
    );
  }

  Future<void> goWithPath(
      String path, {
        dynamic param,
        Map<String, dynamic>? extra,
      }) async {
    return go(
      param == null ? path : '$path/$param',
      extra: extra,
    );
  }

  Future<void> replaceWithPath(
      String path, {
        Map<String, dynamic>? extra,
      }) async {
    return replace(
      path,
      extra: extra,
    );
  }

  void popUntilPath(String routePath) {
    final router = GoRouter.of(this);
    while (router
        .routerDelegate.currentConfiguration.matches.last.matchedLocation !=
        routePath) {
      if (!router.canPop()) {
        return;
      }
      router.pop();
    }
  }


  Future<T?> pushWithPrePath<T extends Object?>(
      String sub, {
        dynamic param,
        Map<String, dynamic>? extra,
      }) async {
    final current = '${GoRouterState.of(this).uri}';
    return await push(
      param != null ? '$current$sub/$param' : '$current$sub',
      extra: extra,
    );
  }

  Future<void> pushReplaceLastPath(
      String newLastPath, {
        Map<String, dynamic>? extra,
      }) async {
    final current = '${GoRouterState.of(this).uri}';
    final oldLastPath = current.split('/').last;
    return pushReplacement(
      current.replaceFirst(
        oldLastPath,
        newLastPath.replaceAll('/', ''),
      ),
      extra: extra,
    );
  }

// Future<void> back() async {
//   final current = '${GoRouterState.of(this).uri}';
//   final oldLastPath = current.split('/').last;
//   return pushReplacement(
//     current.replaceFirst(
//       oldLastPath,
//       '',
//     ),
//   );
// }
}
