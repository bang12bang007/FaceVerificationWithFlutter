import 'package:flutter/material.dart';

class GlobalKeyManager {
  static final instance = GlobalKeyManager();
  final GlobalKey<NavigatorState> root =
  GlobalKey<NavigatorState>(debugLabel: 'root_key');
  final GlobalKey<NavigatorState> home =
  GlobalKey<NavigatorState>(debugLabel: 'home_key');
}

class RouterPath {
  static const splashScreen = '/splash_screen';
  static const home = '/home';
  static const introduce = '/introduce';
  static const verification = '/verification';
}
