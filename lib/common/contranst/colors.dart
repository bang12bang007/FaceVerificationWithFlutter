import 'package:flutter/material.dart';

import '../../../generated/colors.gen.dart';

class UIColors {
  UIColors._();
  //
  static Color get black => ColorName.black;
  static Color get white => ColorName.white;
  static Color get bg => ColorName.bgLight;
  static Color get text => ColorName.textLight;
  static Color get green => ColorName.greenLight;
  static Color get greenBg => ColorName.greenBgLight;
  static Color get yellow => ColorName.yellowLight;
  static Color get blue => ColorName.blue;
  static Color get violet => ColorName.violetLight;
  static Color get gray => ColorName.grayLight;
  static Color get separate => ColorName.separateLight;
  static Color get border => ColorName.borderLight;
  static Color get grey => ColorName.greyLight;
  static Color get textBody => ColorName.textBodyLight;
  static Color get lightGray => ColorName.lightGrayLight;
  static Color get redLight => ColorName.red;
}

class UIShadow {
  UIShadow._();

  static List<BoxShadow> get common => [
    BoxShadow(
      offset: const Offset(0, 4),
      color: ColorName.black.withOpacity(0.05),
      blurRadius: 15,
    ),
  ];
}
