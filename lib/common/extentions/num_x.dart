import 'package:gap/gap.dart';

extension NumberExtension on num {
  Gap get gap => Gap(toDouble());
}