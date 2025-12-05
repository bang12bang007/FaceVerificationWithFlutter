import 'package:flutter/material.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/feature/instruction/infractructure/model/student_model.dart';
import 'package:thesis/shared/widgets/text.dart';
import 'package:thesis/feature/instruction/domain/status_enum.dart';

import '../widget/info.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      shrinkWrap: false,
      cacheExtent: 200,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (student.status?.color ?? UIColors.green).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (student.status?.color ?? UIColors.green).withValues(
                        alpha: 0.1,
                      ),
                      (student.status?.color ?? UIColors.green).withValues(
                        alpha: 0.05,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 180,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: student.status?.color ?? UIColors.green,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (student.status?.color ?? UIColors.green)
                          .withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: student.avatar != null && student.avatar!.isNotEmpty
                      ? Image.network(
                          student.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (student.status?.color ?? UIColors.green)
                                        .withValues(alpha: 0.8),
                                    (student.status?.color ?? UIColors.green),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 50,
                                    color: UIColors.white,
                                  ),
                                  4.gap,
                                  AppText.semiBold(
                                    'Avatar',
                                    color: UIColors.white,
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (student.status?.color ?? UIColors.green)
                                        .withValues(alpha: 0.8),
                                    (student.status?.color ?? UIColors.green),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: UIColors.white,
                                      strokeWidth: 3,
                                    ),
                                    8.gap,
                                    AppText.semiBold(
                                      'Loading...',
                                      color: UIColors.white,
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                (student.status?.color ?? UIColors.green)
                                    .withValues(alpha: 0.8),
                                (student.status?.color ?? UIColors.green),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 50,
                                color: UIColors.white,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No Avatar',
                                style: TextStyle(
                                  color: UIColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              // Status indicator
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: student.status?.color ?? UIColors.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (student.status?.color ?? UIColors.green)
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        student.status == StatusEnum.present
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 12,
                        color: UIColors.white,
                      ),
                      4.gap,
                      Text(
                        student.status?.name ?? 'Unknown',
                        style: TextStyle(
                          color: UIColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        8.gap,
        AppText.semiBold(
          student.name ?? '-',
          fontSize: 16,
          color: UIColors.white,
        ),
        16.gap,
        // Student info card with gradient background
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UIColors.bg.withValues(alpha: 0.8),
                UIColors.bg.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(
              color: (student.status?.color ?? UIColors.green).withValues(
                alpha: 0.3,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (student.status?.color ?? UIColors.green).withValues(
                  alpha: 0.1,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (student.status?.color ?? UIColors.green)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: student.status?.color ?? UIColors.green,
                      size: 20,
                    ),
                  ),
                  12.gap,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bold(
                          'Thông tin chi tiết',
                          fontSize: 16,
                          color: UIColors.white,
                        ),
                        AppText.regular(
                          'Detail information',
                          color: UIColors.lightGray,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              16.gap,
              // Info items with enhanced styling
              StudentDetailWidget(
                icon: Icons.badge_outlined,
                title: 'Mã sinh viên',
                value: student.id ?? '-',
                color: UIColors.blue,
              ),
              8.gap,
              StudentDetailWidget(
                icon: Icons.cake_outlined,
                title: 'Ngày sinh',
                value: student.birthdate ?? '-',
                color: UIColors.yellow,
              ),
              8.gap,
              StudentDetailWidget(
                icon: Icons.school_outlined,
                title: 'Lớp',
                value: student.classroom ?? '-',
                color: UIColors.green,
              ),
              8.gap,
              StudentDetailWidget(
                icon: Icons.engineering_outlined,
                title: 'Chuyên ngành',
                value: student.major ?? '-',
                color: UIColors.redLight,
              ),
              8.gap,
              StudentDetailWidget(
                icon: Icons.school,
                title: 'Khoá học',
                value: student.course ?? '-',
                color: UIColors.blue,
              ),
              8.gap,
              StudentDetailWidget(
                icon: Icons.category_outlined,
                title: 'Loại hình đào tạo',
                value: student.type ?? '-',
                color: UIColors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
