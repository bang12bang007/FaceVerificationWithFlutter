import 'package:flutter/material.dart';

import '../../common/contranst/colors.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height,
    this.color,
  });

  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? 0.5,
      thickness: height ?? 0.5,
      color: color ?? UIColors.gray,
    );
  }
}
