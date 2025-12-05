import 'package:flutter/material.dart';

import '../../../common/contranst/colors.dart';

enum StatusEnum {
  present,
  absent;

  String get name {
    switch (this) {
      case StatusEnum.present:
        return 'Có mặt';
      case StatusEnum.absent:
        return 'Vắng mặt';
    }
  }
  Color get color {
    switch (this) {
      case StatusEnum.present:
        return UIColors.green;
      case StatusEnum.absent:
        return UIColors.yellow;
    }
  }
}
