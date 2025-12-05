import 'package:flutter/material.dart';
import 'package:thesis/common/extentions/num_x.dart';

import '../../../../common/contranst/colors.dart' show UIColors;
import '../../../../shared/widgets/text.dart';

class StudentDetailWidget extends StatelessWidget {
  const StudentDetailWidget({super.key, required this.title, required this.value, required this.icon, required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          8.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.semiBold(
                  title,
                  fontSize: 12,
                  color: UIColors.lightGray,
                ),
                4.gap,
                AppText.semiBold(value, color: UIColors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}