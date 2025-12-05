part of 'face_scan_cubit.dart';

final class FaceScanState extends Equatable {
  final BlocStatus status;
  final String? message;
  final double? similarity;
  final Uint8List? cameraImageBytes; // Ảnh đã crop từ camera

  const FaceScanState({
    this.status = BlocStatus.init,
    this.message,
    this.similarity,
    this.cameraImageBytes,
  });

  FaceScanState copyWith({
    BlocStatus? status,
    String? message,
    double? similarity,
    Uint8List? cameraImageBytes,
  }) {
    return FaceScanState(
      status: status ?? this.status,
      message: message ?? this.message,
      similarity: similarity ?? this.similarity,
      cameraImageBytes: cameraImageBytes ?? this.cameraImageBytes,
    );
  }

  @override
  List<Object?> get props => [status, message, similarity, cameraImageBytes];
}
