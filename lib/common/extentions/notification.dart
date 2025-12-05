import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/text.dart';
import '../contranst/colors.dart';


class NotificationBanner extends Flushbar {
  NotificationBanner.error({
    super.key,
    required String? message,
  }) : super(
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.GROUNDED,
    reverseAnimationCurve: Curves.decelerate,
    forwardAnimationCurve: Curves.easeInOutCubic,
    backgroundColor: Colors.red,
    duration: Duration(seconds: 4),
    titleText: AppText.semiBold(
      'Đã xảy ra lỗi. Vui lòng thử lại sau',
      color: UIColors.white,
    ),
    messageText: AppText.regular(
      (message ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau')
          .toLowerCase(),
      color: UIColors.white,
      maxLines: 4,
    ),
    animationDuration: Duration(microseconds: 300),
    onTap: (value) {
      value.dismiss();
    },
    padding: const EdgeInsets.only(
      top: 8,
      left: 20,
      right: 20,
      bottom: 16,
    ),
  );

  NotificationBanner.success({
    super.key,
    required String? message,
  }) : super(
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.GROUNDED,
    reverseAnimationCurve: Curves.decelerate,
    forwardAnimationCurve: Curves.easeInOutCubic,
    backgroundColor: UIColors.green,
    duration: Duration(seconds: 4),
    titleText: AppText.semiBold(
      'Thành công',
      color: UIColors.white,
    ),
    messageText: AppText.regular(
      message ?? '',
      color: UIColors.white,
      maxLines: 3,
    ),
    animationDuration:Duration(microseconds: 300),
    onTap: (value) {
      value.dismiss();
    },
    padding: const EdgeInsets.only(
      top: 8,
      left: 20,
      right: 20,
      bottom: 16,
    ),
  );
}
