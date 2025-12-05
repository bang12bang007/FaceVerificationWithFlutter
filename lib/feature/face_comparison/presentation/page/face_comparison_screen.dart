import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/contenxt_x.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/core/enums/bloc_status.dart';
import 'package:thesis/shared/widgets/appbar.dart';
import 'package:thesis/shared/widgets/button.dart';
import 'package:thesis/shared/widgets/text.dart';

import '../cubit/face_comparison_cubit.dart';
import '../../../face_scan/model/face_scan_model.dart';

class FaceComparisonScreen extends StatelessWidget {
  const FaceComparisonScreen({
    super.key,
    required this.cameraImageBytes,
    required this.apiImageUrl,
    this.similarity,
  });

  final Uint8List cameraImageBytes;
  final String apiImageUrl;
  final double? similarity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FaceComparisonCubit(modelService: FaceModelService())..initialize(
            cameraImageBytes: cameraImageBytes,
            apiImageUrl: apiImageUrl,
            similarity: similarity,
          ),
      child: Scaffold(
        backgroundColor: UIColors.bg,
        appBar: AppAppBar(title: 'So sánh khuôn mặt'),
        body: BlocBuilder<FaceComparisonCubit, FaceComparisonState>(
          builder: (context, state) {
            if (state.status == BlocStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  16.gap,
                  // Header
                  AppText.bold(
                    'Kết quả so sánh',
                    fontSize: 20,
                    textAlign: TextAlign.center,
                  ),
                  if (state.similarity != null) ...[
                    8.gap,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getSimilarityColor(
                          state.similarity!,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getSimilarityColor(state.similarity!),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            state.similarity! >= 0.65
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _getSimilarityColor(state.similarity!),
                            size: 24,
                          ),
                          8.gap,
                          AppText.bold(
                            'Độ tương đồng: ${(state.similarity! * 100).toStringAsFixed(1)}%',
                            fontSize: 18,
                            color: _getSimilarityColor(state.similarity!),
                          ),
                        ],
                      ),
                    ),
                  ],
                  24.gap,
                  // Comparison Images
                  Row(
                    children: [
                      // Camera Image
                      Expanded(
                        child: _ImageCard(
                          title: 'Ảnh từ Camera',
                          imageBytes: state.cameraImageBytes,
                        ),
                      ),
                      16.gap,
                      // API Image
                      Expanded(
                        child: _ImageCard(
                          title: 'Ảnh từ API',
                          imageBytes:
                              state.apiImageBytes,
                          imageUrl: state.apiImageUrl,
                        ),
                      ),
                    ],
                  ),
                  32.gap,
                  // Action Buttons
                  AppButton.fill(
                    onTap: () => Navigator.of(context).pop(),
                    titleWidget: AppText.semiBold(
                      'Đóng',
                      fontSize: 16,
                      color: UIColors.white,
                    ),
                  ),
                  context.paddingBottomForButton.gap,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.65) {
      return UIColors.green;
    } else if (similarity >= 0.5) {
      return UIColors.yellow;
    } else {
      return UIColors.redLight;
    }
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({this.title, this.imageBytes, this.imageUrl});

  final String? title;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UIColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: UIColors.lightGray.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: UIColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          if (title != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: UIColors.lightGray.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: AppText.semiBold(
                title ?? '',
                textAlign: TextAlign.center,
              ),
            ),
          // Image
          Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Ưu tiên hiển thị ảnh đã crop (apiImageBytes) nếu có
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (imageUrl != null) {
      // Fallback: hiển thị ảnh từ URL nếu chưa có ảnh đã crop
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: UIColors.green,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: UIColors.lightGray.withValues(alpha: 0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: UIColors.redLight, size: 40),
          8.gap,
          AppText.regular(
            'Không thể tải ảnh',
            fontSize: 12,
            color: UIColors.lightGray,
          ),
        ],
      ),
    );
  }
}
