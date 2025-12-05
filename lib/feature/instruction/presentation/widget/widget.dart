import 'package:flutter/material.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/shared/widgets/text.dart';

class InstructionWidget extends StatelessWidget {
  const InstructionWidget({
    super.key,
    required this.title,
    required this.value,
  });
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText.semiBold(title, fontSize: 14, color: UIColors.white),

        Spacer(),
        AppText.bold(value, color: UIColors.white),
      ],
    );
  }
}
