part of 'face_comparison_cubit.dart';

final class FaceComparisonState extends Equatable {
  final BlocStatus status;
  final String? message;
  final Uint8List? cameraImageBytes;
  final Uint8List? apiImageBytes; // Ảnh đã crop từ API
  final String? apiImageUrl; // URL gốc (để fallback)
  final double? similarity;

  const FaceComparisonState({
    this.status = BlocStatus.init,
    this.message,
    this.cameraImageBytes,
    this.apiImageBytes,
    this.apiImageUrl,
    this.similarity,
  });

  FaceComparisonState copyWith({
    BlocStatus? status,
    String? message,
    Uint8List? cameraImageBytes,
    Uint8List? apiImageBytes,
    String? apiImageUrl,
    double? similarity,
  }) {
    return FaceComparisonState(
      status: status ?? this.status,
      message: message ?? this.message,
      cameraImageBytes: cameraImageBytes ?? this.cameraImageBytes,
      apiImageBytes: apiImageBytes ?? this.apiImageBytes,
      apiImageUrl: apiImageUrl ?? this.apiImageUrl,
      similarity: similarity ?? this.similarity,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    cameraImageBytes,
    apiImageBytes,
    apiImageUrl,
    similarity,
  ];
}
