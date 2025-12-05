import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/contenxt_x.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/core/presentation/dialog.dart';
import 'package:thesis/core/presentation/loading.dart';
import 'package:thesis/feature/verification/presentation/cubit/verification_cubit.dart';
import 'package:thesis/shared/widgets/appbar.dart';
import 'package:thesis/shared/widgets/button.dart';
import 'package:thesis/shared/widgets/text.dart';

import '../../../face_scan/presentation/page/face_scan_screen.dart';
import '../../../instruction/domain/status_enum.dart';
import '../../../instruction/presentation/widget/info.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.mssv});

  final String mssv;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late final VerificationCubit _cubit;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _cubit = VerificationCubit();
    debugPrint('VerificationScreen initState with mssv: "${widget.mssv}"');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _cubit.fetchStudents(widget.mssv);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('VerificationScreen build called');
    return Scaffold(
      backgroundColor: UIColors.bg,
      appBar: AppAppBar(title: 'Xác thực sinh viên'),
      body: BlocProvider.value(
        value: _cubit,
        child: BlocBuilder<VerificationCubit, VerificationState>(
          builder: (context, state) {
            if (state.status.isLoading) {
              return Center(child: LoadingIndicator());
            } else if (state.status.isError) {
              return Center(
                child: DialogButton(
                  title: (state.mssv ?? '').length <= 8
                      ? 'Không tìm thấy \n Sinh viên với MSSV: ${state.mssv}'
                      : 'Đã xảy ra lỗi! Vui lòng thử lại',
                  onTap: () => context.pop(),
                  color: UIColors.redLight,
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    primary: false,
                    shrinkWrap: false,
                    cacheExtent: 200,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (state.detail?.status?.color ??
                                          UIColors.green)
                                      .withValues(alpha: 0.3),
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
                                    (state.detail?.status?.color ??
                                            UIColors.green)
                                        .withValues(alpha: 0.1),
                                    (state.detail?.status?.color ??
                                            UIColors.green)
                                        .withValues(alpha: 0.05),
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
                                  color:
                                      state.detail?.status?.color ??
                                      UIColors.green,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (state.detail?.status?.color ??
                                                UIColors.green)
                                            .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child:
                                    state.detail?.avatar != null &&
                                        (state.detail?.avatar! ?? '').isNotEmpty
                                    ? Image.network(
                                        state.detail?.avatar! ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      (state
                                                                  .detail
                                                                  ?.status
                                                                  ?.color ??
                                                              UIColors.green)
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      (state
                                                              .detail
                                                              ?.status
                                                              ?.color ??
                                                          UIColors.green),
                                                    ],
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color: UIColors.white,
                                                    ),
                                                    4.gap,
                                                    AppText.regular('Avatar',fontSize: 12,)
                                                  ],
                                                ),
                                              );
                                            },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      (state
                                                                  .detail
                                                                  ?.status
                                                                  ?.color ??
                                                              UIColors.green)
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      (state
                                                              .detail
                                                              ?.status
                                                              ?.color ??
                                                          UIColors.green),
                                                    ],
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
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
                                              (state.detail?.status?.color ??
                                                      UIColors.green)
                                                  .withValues(alpha: 0.8),
                                              (state.detail?.status?.color ??
                                                  UIColors.green),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 50,
                                              color: UIColors.white,
                                            ),
                                            4.gap,
                                            AppText.semiBold('No Avatar',fontSize: 12)
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
                                  color:
                                      state.detail?.status?.color ??
                                      UIColors.green,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (state.detail?.status?.color ??
                                                  UIColors.green)
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
                                      state.detail?.status == StatusEnum.present
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 12,
                                      color: UIColors.white,
                                    ),
                                    4.gap,
                                    Text(
                                      state.detail?.status?.name ?? 'Unknown',
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
                        state.detail?.name ?? '-',
                        fontSize: 16,
                        color: UIColors.white,
                      ),
                      16.gap,
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
                            color:
                                (state.detail?.status?.color ?? UIColors.green)
                                    .withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (state.detail?.status?.color ??
                                          UIColors.green)
                                      .withValues(alpha: 0.1),
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
                                    color:
                                        (state.detail?.status?.color ??
                                                UIColors.green)
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    color:
                                        state.detail?.status?.color ??
                                        UIColors.green,
                                    size: 20,
                                  ),
                                ),
                                12.gap,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                              value: state.detail?.id ?? '-',
                              color: UIColors.blue,
                            ),
                            8.gap,
                            StudentDetailWidget(
                              icon: Icons.cake_outlined,
                              title: 'Ngày sinh',
                              value: state.detail?.birthdate ?? '-',
                              color: UIColors.yellow,
                            ),
                            8.gap,
                            StudentDetailWidget(
                              icon: Icons.school_outlined,
                              title: 'Lớp',
                              value: state.detail?.classroom ?? '-',
                              color: UIColors.green,
                            ),
                            8.gap,
                            StudentDetailWidget(
                              icon: Icons.engineering_outlined,
                              title: 'Chuyên ngành',
                              value: state.detail?.major ?? '-',
                              color: UIColors.redLight,
                            ),
                            8.gap,
                            StudentDetailWidget(
                              icon: Icons.school,
                              title: 'Khoá học',
                              value: state.detail?.course ?? '-',
                              color: UIColors.blue,
                            ),
                            8.gap,
                            StudentDetailWidget(
                              icon: Icons.category_outlined,
                              title: 'Loại hình đào tạo',
                              value: state.detail?.type ?? '-',
                              color: UIColors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                16.gap,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppButton.fill(
                    onTap: () async {
                      try {
                        final cameras = await availableCameras();
                        if (cameras.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Không tìm thấy camera trên thiết bị.',
                              ),
                            ),
                          );
                          return;
                        }
                        final camera = cameras.firstWhere(
                          (camera) =>
                              camera.lensDirection == CameraLensDirection.front,
                          orElse: () => cameras.first,
                        );
                        final avatar = state.detail?.avatar ?? '';

                        if (avatar.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không có ảnh avatar để so sánh.'),
                            ),
                          );
                          return;
                        }
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FaceScanPage(camera: camera, avatar: avatar),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi mở camera: $e')),
                        );
                      }
                    },
                    titleWidget: AppText.semiBold(
                      'Xác thực khuôn mặt',
                      fontSize: 16,
                    ),
                  ),
                ),
                context.paddingBottomForButton.gap,
              ],
            );
          },
        ),
      ),
    );
  }
}
