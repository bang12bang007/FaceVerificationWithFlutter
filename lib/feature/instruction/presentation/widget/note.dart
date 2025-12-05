import 'package:flutter/material.dart';
import 'package:thesis/common/extentions/num_x.dart';

import '../../../../common/contranst/colors.dart';
import '../../../../shared/widgets/text.dart';

class InfoExamWidget extends StatelessWidget {
  const InfoExamWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            color: UIColors.green,
            shape: BoxShape.circle,
          ),
          
        ),
        6.gap,
        AppText.regular('Có mặt', fontSize: 12, color: UIColors.green),
        18.gap,
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            color: UIColors.yellow,
            shape: BoxShape.circle,
          ),
          
        ),
        6.gap,
        AppText.regular('Vắng mặt', fontSize: 12, color: UIColors.yellow),
      ],
    );
  }
}
