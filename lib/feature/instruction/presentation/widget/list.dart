import 'package:flutter/material.dart';
import 'package:thesis/common/extentions/color_x.dart';
import 'package:thesis/generated/assets.gen.dart';

import '../../../../common/contranst/colors.dart' show UIColors;
import '../../../../shared/widgets/text.dart';
import '../../domain/status_enum.dart';

class ListStudentWidget extends StatelessWidget {
  const ListStudentWidget({
    super.key,
    required this.name,
    required this.status,
  });
  final String name;
  final StatusEnum status;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: UIColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UIColors.lightGray),
      ),
      child: Row(
        children: [
          AppText.semiBold(name, fontSize: 14, color: UIColors.white),
          Spacer(),
          Assets.svg.icStudentDetail.svg(color: status.color),
        ],
      ),
    );
  }
}
