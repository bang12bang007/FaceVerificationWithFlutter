import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../common/extentions/notification.dart';

class LiveData {
  LiveData._();
  static late BuildContext mainContext;
  static showError({BuildContext? context, String? msg}) async {
    NotificationBanner.error(message: msg).show(context ?? mainContext);
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 20);
    }
  }

  static showSuccess({BuildContext? context, String? msg}) async {
    NotificationBanner.success(message: msg).show(context ?? mainContext);
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 20);
    }
  }
}
