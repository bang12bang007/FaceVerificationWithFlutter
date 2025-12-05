import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../../core/enums/bloc_status.dart';
import '../../../face_scan/model/face_scan_model.dart';

part 'face_comparison_state.dart';

class FaceComparisonCubit extends Cubit<FaceComparisonState> {
  FaceComparisonCubit({required this.modelService})
    : super(const FaceComparisonState());

  final FaceModelService modelService;

  Future<void> initialize({
    required Uint8List cameraImageBytes,
    required String apiImageUrl,
    double? similarity,
  }) async {
    emit(
      state.copyWith(
        status: BlocStatus.loading,
        cameraImageBytes: cameraImageBytes,
        apiImageUrl: apiImageUrl,
        similarity: similarity,
      ),
    );

    try {
      // 1. Tải ảnh từ API
      final response = await http.get(Uri.parse(apiImageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      final apiImageBytes = response.bodyBytes;

      final croppedApiImageBytes = await modelService.cropFaceFromApiImage(
        apiImageBytes,
      );
      emit(
        state.copyWith(
          status: BlocStatus.success,
          apiImageBytes: croppedApiImageBytes,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BlocStatus.error,
          message: 'Lỗi khi xử lý ảnh API: $e',
        ),
      );
    }
  }

  /// Reset state
  void reset() {
    emit(const FaceComparisonState());
  }
}
