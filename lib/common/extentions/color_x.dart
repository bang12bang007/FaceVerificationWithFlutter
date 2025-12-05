import 'dart:ui';

import 'package:flutter/material.dart';

extension ColorExtension on Color {
  ColorFilter get filter => ColorFilter.mode(Colors.white, BlendMode.srcIn);

  //Ex: #FFFFFF
  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}
