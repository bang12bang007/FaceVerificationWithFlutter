import 'package:flutter/material.dart';

import '../../core/presentation/bottom_sheet.dart';
import '../../core/presentation/dialog.dart';


extension ContextExtension on BuildContext {
  MediaQueryData get _mediaQuery => MediaQuery.of(this);

  double get screenHeight => MediaQuery.sizeOf(this).height;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get keyboardHeight => _mediaQuery.viewInsets.bottom;

  double get appBarHeight {
    return MediaQuery.paddingOf(this).top + 46;
  }

  double get topPadding => _mediaQuery.padding.top;

  double get bottomPadding =>
      _mediaQuery.padding.bottom > 0 ? _mediaQuery.padding.bottom : 24;

  double get paddingBottomForButton => bottomPadding > 0 ? bottomPadding : 16;

  double get numberKeyboardHeight =>
      keyboardHeight == 0 ? 0 : keyboardHeight + 50;

  double get correctHeightAboveKeyboard =>
      keyboardHeight == 0 ? 35 : (keyboardHeight + 16);

  double get correctHeightAboveNumberKeyboard =>
      keyboardHeight == 0 ? 35 : (keyboardHeight + 56);


  Future<void> showDialog(
      Widget child, {
        double? horizontalMargin,
      }) async =>
      await showAppDialog(
        this,
        child: child,
        horizontalMargin: horizontalMargin,
      );

  void showBottomSheet({
    required Widget child,
  }) =>
      showAppBottomSheet(
        this,
        child: child,
      );

  void showBottomSheetWithoutHeader({
    required Widget child,
  }) =>
      showAppBottomSheetWithoutHeader(
        this,
        child: child,
      );

  void showFullScreenBottomSheet({
    required Widget child,
  }) =>
      showAppFullScreenBottomSheet(
        this,
        child: child,
      );
}
