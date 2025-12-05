import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/enums/bloc_status.dart';
import '../../model/face_scan_model.dart';

part 'face_scan_state.dart';

class FaceScanCubit extends Cubit<FaceScanState> {
  FaceScanCubit({required this.modelService}) : super(const FaceScanState());

  final FaceModelService modelService;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true, // BẬT LANDMARKS
      enableClassification: false,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
    ),
  );

  bool _isClosed = false;
  bool _isDetecting = false; // Flag cho phase detection
  bool _isVerifying =
      false; // Flag cho phase verification (đã chụp và đang xử lý)
  DateTime? _lastDetectTime;
  DateTime? _faceDetectedAt; // Thời điểm phát hiện face tốt
  CameraImage? _capturedImage; // Frame đã chụp để xử lý
  Face? _capturedFace; // Đổi từ Rect? thành Face? để lưu landmarks

  Duration detectionCooldown = const Duration(
    milliseconds: 1000,
  ); // Detect mỗi 1000ms (tăng lên để giảm memory usage)
  Duration faceStableDuration = const Duration(
    milliseconds: 1500,
  ); // Face phải ổn định 1.5s

  /// Phase 1: Chỉ detect face (nhẹ, nhanh) - gọi từ mọi frame
  Future<void> handleCameraImage(
    CameraImage image,
    CameraDescription camera,
    String img,
  ) async {
    // Nếu đã closed hoặc đang verify thì không detect nữa
    if (_isClosed || _isVerifying) {
      return;
    }

    // Throttle detection
    final now = DateTime.now();
    if (_lastDetectTime != null &&
        now.difference(_lastDetectTime!) < detectionCooldown) {
      return;
    }

    // Nếu đang detect frame trước, bỏ qua
    if (_isDetecting) {
      return;
    }

    _isDetecting = true;
    _lastDetectTime = now;

    try {
      // 1. Chuyển CameraImage -> InputImage cho ML Kit
      final inputImage = _cameraImageToInputImage(image, camera);

      // 2. Detect faces (nhanh, nhẹ)
      final faces = await _detector.processImage(inputImage);

      if (_isClosed || _isVerifying) {
        _isDetecting = false;
        return;
      }

      // 3. Kiểm tra có face không
      if (faces.isEmpty) {
        _faceDetectedAt = null; // Reset timer
        if (!_isClosed) {
          emit(
            state.copyWith(
              status: BlocStatus.checking,
              message: "Đưa mặt vào khung",
            ),
          );
        }
        _isDetecting = false;
        return;
      }

      // 4. Chọn face lớn nhất
      final face = _selectLargestFace(faces);
      final box = face.boundingBox;

      // 5. Kiểm tra quality của face
      if (box.width < 60 || box.height < 60) {
        _faceDetectedAt = null;
        if (!_isClosed) {
          emit(
            state.copyWith(
              status: BlocStatus.checking,
              message: "Đưa mặt gần hơn vào khung",
            ),
          );
        }
        _isDetecting = false;
        return;
      }

      // 6. KIỂM TRA LANDMARKS - QUAN TRỌNG
      final hasRequiredLandmarks = _checkRequiredLandmarks(face);
      if (!hasRequiredLandmarks) {
        _faceDetectedAt = null;
        if (!_isClosed) {
          emit(
            state.copyWith(
              status: BlocStatus.checking,
              message: "Di chuyển khuôn mặt để nhận diện rõ hơn",
            ),
          );
        }
        _isDetecting = false;
        return;
      }

      // 7. Face tốt rồi, check xem đã ổn định chưa
      final currentTime = DateTime.now();
      if (_faceDetectedAt == null) {
        // Lần đầu phát hiện face tốt
        _faceDetectedAt = currentTime;
        if (!_isClosed) {
          emit(
            state.copyWith(status: BlocStatus.hasData, message: "Giữ yên..."),
          );
        }
      } else {
        // Face đã được phát hiện trước đó, check xem đã ổn định đủ lâu chưa
        final stableDuration = currentTime.difference(_faceDetectedAt!);

        if (stableDuration >= faceStableDuration && !_isVerifying) {
          // Face đã ổn định, chụp frame và bắt đầu verify
          _capturedImage = image;
          _capturedFace = face; // Lưu Face thay vì chỉ Rect
          _faceDetectedAt = null; // Reset
          _isVerifying = true;

          // Bắt đầu phase 2: Verification
          _verifyFace(camera, img);
        } else {
          // Vẫn đang đợi face ổn định
          final remaining =
              (faceStableDuration.inMilliseconds -
                  stableDuration.inMilliseconds) /
              1000;
          if (!_isClosed) {
            emit(
              state.copyWith(
                status: BlocStatus.hasData,
                message: "Giữ yên... (${remaining.toStringAsFixed(1)}s)",
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] Error in face detection: $e');
      debugPrint('[ERROR] StackTrace: $stackTrace');
      if (!_isClosed && !_isVerifying) {
        emit(state.copyWith(status: BlocStatus.checking, message: "Lỗi: $e"));
      }
    } finally {
      _isDetecting = false;
    }
  }

  /// Phase 2: Verify face với model (chỉ 1 lần sau khi chụp)
  Future<void> _verifyFace(CameraDescription camera, String img) async {
    debugPrint('[DEBUG] Bắt đầu verify face...');

    if (_isClosed || _capturedImage == null || _capturedFace == null) {
      debugPrint(
        '[ERROR] Verify failed: _isClosed=$_isClosed, _capturedImage=${_capturedImage != null}, _capturedFace=${_capturedFace != null}',
      );
      _isVerifying = false;
      return;
    }

    // Emit loading
    if (!_isClosed) {
      emit(
        state.copyWith(status: BlocStatus.loading, message: "Đang xác thực..."),
      );
    }

    // Lưu captured image vào biến local và clear ngay để giải phóng memory
    final capturedImageToProcess = _capturedImage;
    final capturedFaceToProcess = _capturedFace;

    // Clear captured data ngay để giải phóng memory
    _capturedImage = null;
    _capturedFace = null;

    if (capturedImageToProcess == null || capturedFaceToProcess == null) {
      debugPrint('[ERROR] Captured image or face is null');
      _isVerifying = false;
      return;
    }

    try {
      // 1. Crop và align face
      final faceResult = await modelService.cropFaceFromCameraImageWithAlignment(
        capturedImageToProcess,
        camera,
        capturedFaceToProcess,
      );

      if (_isClosed) {
        _isVerifying = false;
        return;
      }

      // 2. Get embedding từ model (dùng modelBytes)
      final embedding = await modelService.getEmbedding(
        faceResult.modelBytes,
        source: 'CAMERA_FRAME',
      );

      if (_isClosed) {
        _isVerifying = false;
        return;
      }

      // 3. Compare với avatar
      final double sim = await modelService.compareImageInCard(embedding, img);

      if (_isClosed) {
        _isVerifying = false;
        return;
      }

      // 4. Kết quả
      if (!_isClosed) {
        if (sim >= modelService.threshold) {
          emit(
            state.copyWith(
              status: BlocStatus.success,
              similarity: sim,
              message: "Xác thực thành công",
              cameraImageBytes: faceResult.displayBytes, // Dùng displayBytes cho UI
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: BlocStatus.error,
              similarity: sim,
              message: "Xác thực thất bại",
              cameraImageBytes: faceResult.displayBytes, // Dùng displayBytes cho UI
            ),
          );
          // Reset để có thể thử lại
          Future.delayed(const Duration(seconds: 2), () {
            if (!_isClosed) {
              _isVerifying = false;
              _faceDetectedAt = null;
              emit(
                state.copyWith(
                  status: BlocStatus.checking,
                  message: "Đưa mặt vào khung",
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[ERROR] Error in verify: $e');
      if (!_isClosed) {
        emit(state.copyWith(status: BlocStatus.error, message: "Lỗi: $e"));
        // Reset sau 2s
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isClosed) {
            _isVerifying = false;
            _faceDetectedAt = null;
            emit(
              state.copyWith(
                status: BlocStatus.checking,
                message: "Đưa mặt vào khung",
              ),
            );
          }
        });
      }
    } finally {
      // Đảm bảo _isVerifying được reset
      if (!_isClosed && _isVerifying) {
        // Chỉ reset nếu chưa có delay reset ở trên
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isClosed && _isVerifying) {
            _isVerifying = false;
          }
        });
      }
    }
  }

  Face _selectLargestFace(List<Face> faces) {
    faces.sort(
      (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
        a.boundingBox.width * a.boundingBox.height,
      ),
    );
    return faces.first;
  }

  /// Kiểm tra xem face có đủ landmarks cần thiết không
  bool _checkRequiredLandmarks(Face face) {
    // Kiểm tra các landmarks cần thiết (mắt và mũi là đủ để align)
    final hasLeftEye = face.landmarks[FaceLandmarkType.leftEye] != null;
    final hasRightEye = face.landmarks[FaceLandmarkType.rightEye] != null;
    final hasNoseBase = face.landmarks[FaceLandmarkType.noseBase] != null;

    debugPrint('[DEBUG] Landmarks check:');
    debugPrint('[DEBUG]   Left eye: $hasLeftEye');
    debugPrint('[DEBUG]   Right eye: $hasRightEye');
    debugPrint('[DEBUG]   Nose base: $hasNoseBase');

    final allRequired = hasLeftEye && hasRightEye && hasNoseBase;

    if (!allRequired) {
      debugPrint('[DEBUG] ⚠️ Missing required landmarks!');
    }

    return allRequired;
  }

  InputImage _cameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      // Log thông tin image để debug
      debugPrint(
        '[DEBUG] CameraImage format: ${image.format.group.name} (${image.format.raw})',
      );
      debugPrint('[DEBUG] CameraImage planes: ${image.planes.length}');
      debugPrint('[DEBUG] Camera orientation: ${camera.sensorOrientation}');

      // 1. Xác định format chính xác
      InputImageFormat format;
      if (Platform.isAndroid) {
        // Android: Thường dùng NV21 hoặc YUV_420_888
        if (image.format.group == ImageFormatGroup.yuv420) {
          format = InputImageFormat.nv21;
        } else if (image.format.group == ImageFormatGroup.yuv420) {
          format = InputImageFormat.yuv420; // ML Kit có thể convert
        } else {
          format = InputImageFormat.nv21; // Default
        }
      } else {
        // iOS: Thường dùng BGRA hoặc YUV420
        format = InputImageFormat.bgra8888;
        // Hoặc thử yuv420 cho iOS
        // format = InputImageFormat.yuv420;
      }

      debugPrint('[DEBUG] InputImageFormat: $format');

      // 2. Xác định rotation - QUAN TRỌNG!
      // ML Kit cần rotation chính xác để detect đúng
      InputImageRotation rotation;
      final sensorOrientation = camera.sensorOrientation;

      // Front camera thường có orientation khác back camera
      if (camera.lensDirection == CameraLensDirection.front) {
        // Front camera: cần adjust rotation
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 180:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
        // Front camera cần flip horizontally
        // rotation = InputImageRotation.rotation270deg; // Thử với front camera
      } else {
        // Back camera
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 180:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      }

      debugPrint(
        '[DEBUG] Rotation: $rotation (sensor: $sensorOrientation, lens: ${camera.lensDirection})',
      );

      // 3. Chuyển đổi bytes - CÁCH ĐÚNG CHO YUV420/NV21
      Uint8List bytes;

      if (image.format.group == ImageFormatGroup.yuv420) {
        // YUV420 format: Cần combine Y, U, V planes đúng cách
        final WriteBuffer allBytes = WriteBuffer();
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes.length > 2
            ? image.planes[2]
            : image.planes[1];

        // NV21 format: Y plane + interleaved VU
        allBytes.putUint8List(yPlane.bytes);

        // Interleave V và U bytes cho NV21
        final uvRowStride = uPlane.bytesPerRow;
        final uvPixelStride = uPlane.bytesPerPixel ?? 1;
        
        // Tính toán kích thước buffer cần thiết
        final int uvWidth = image.width ~/ 2;
        final int uvHeight = image.height ~/ 2;
        final int totalUVBytes = uvWidth * uvHeight * 2;
        
        final Uint8List vuBytes = Uint8List(totalUVBytes);
        int pos = 0;

        for (int i = 0; i < uPlane.bytes.length / uvPixelStride; i++) {
          final uIndex = i * uvPixelStride;
          final vIndex = i * uvPixelStride;

          if (vIndex < vPlane.bytes.length && uIndex < uPlane.bytes.length && pos + 1 < totalUVBytes) {
            vuBytes[pos++] = vPlane.bytes[vIndex];
            vuBytes[pos++] = uPlane.bytes[uIndex];
          }
        }
        allBytes.putUint8List(vuBytes);
        bytes = allBytes.done().buffer.asUint8List();
      } else {
        // Format khác (BGRA8888 trên iOS): thường chỉ có 1 plane
        if (image.planes.length == 1) {
           bytes = image.planes[0].bytes;
        } else {
           // Fallback nếu có nhiều planes mà không phải YUV420
           final WriteBuffer allBytes = WriteBuffer();
           for (final plane in image.planes) {
             allBytes.putUint8List(plane.bytes);
           }
           bytes = allBytes.done().buffer.asUint8List();
        }
      }
      
      debugPrint('[DEBUG] Total bytes: ${bytes.length}');

      // 4. Lấy bytesPerRow - QUAN TRỌNG cho YUV
      final bytesPerRow = image.planes.isNotEmpty
          ? image.planes[0].bytesPerRow
          : image.width;

      debugPrint(
        '[DEBUG] BytesPerRow: $bytesPerRow, Image size: ${image.width}x${image.height}',
      );

      // 5. Tạo metadata
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      );

      // 6. Tạo InputImage
      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

      debugPrint('[DEBUG] ✅ InputImage created successfully');
      return inputImage;
    } catch (e, stackTrace) {
      debugPrint('[ERROR] Error creating InputImage: $e');
      debugPrint('[ERROR] StackTrace: $stackTrace');

      // Fallback: Thử cách đơn giản hơn
      return _fallbackCameraImageToInputImage(image, camera);
    }
  }

  // Fallback method nếu cách chính không hoạt động
  InputImage _fallbackCameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    debugPrint('[DEBUG] Using fallback conversion method');

    // Cách đơn giản: copy trực tiếp
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final bytesPerRow = image.planes.isNotEmpty
        ? image.planes[0].bytesPerRow
        : image.width;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  @override
  Future<void> close() {
    _isClosed = true; // Đánh dấu đã closed
    _detector.close();
    return super.close();
  }
}
