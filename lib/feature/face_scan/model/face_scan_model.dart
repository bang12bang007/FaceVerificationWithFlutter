import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

class FaceImageResult {
  final Uint8List modelBytes;
  final Uint8List displayBytes;

  FaceImageResult({required this.modelBytes, required this.displayBytes});
}

class FaceModelService {
  Interpreter? _interpreter;
  final int inputSize = 112;
  final int embSize = 512;
  final double threshold = 0.9;

  Future<void> loadModel() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/model/arc_face_model.tflite',
    );

    print('[MODEL INFO] Model loaded successfully');
    final inputs = _interpreter!.getInputTensors();
    final outputs = _interpreter!.getOutputTensors();

    print('[MODEL INFO] Input tensors: ${inputs.length}');
    for (int i = 0; i < inputs.length; i++) {
      print(
        '[MODEL INFO]   Input $i: shape=${inputs[i].shape}, type=${inputs[i].type}',
      );
    }

    print('[MODEL INFO] Output tensors: ${outputs.length}');
    for (int i = 0; i < outputs.length; i++) {
      print(
        '[MODEL INFO]   Output $i: shape=${outputs[i].shape}, type=${outputs[i].type}',
      );
    }

    // Kiểm tra xem có phải embedding model không
    if (outputs[0].shape.length == 2) {
      final outputDim = outputs[0].shape[1];
      if (outputDim == 128) {
        print('[MODEL INFO] ✅ MobileFaceNet detected: Output shape [1, 128]');
      } else if (outputDim == 10) {
        print(
          '[MODEL INFO] ⚠️ WARNING: Output shape [1, 10] is very small for face embedding!',
        );
        print(
          '[MODEL INFO] Typical face embedding models use 128, 256, or 512 dimensions.',
        );
        print(
          '[MODEL INFO] Model might be a classification model, not an embedding model.',
        );
      } else {
        print(
          '[MODEL INFO] Output shape [1, $outputDim] - Please verify this matches your model.',
        );
      }
    }
  }

  /// Flip ảnh theo chiều ngang (mirror)
  img.Image _flipImageHorizontal(img.Image src) {
    final flipped = img.Image(src.width, src.height);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(src.width - 1 - x, y);
        flipped.setPixel(x, y, pixel);
      }
    }
    return flipped;
  }

  /// Crop mặt từ CameraImage theo boundingBox
  Future<Uint8List> cropFaceFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    Rect bbox,
  ) async {
    // 1. convert CameraImage (YUV420) -> RGB image.Image
    final img.Image fullImg = _convertCameraImageToImage(image);

    // ML Kit và Camera có orientation khác nhau -> có thể cần rotate theo camera.sensorOrientation
    final int rotation = camera.sensorOrientation;
    final img.Image rotated = _rotateImageIfNeeded(fullImg, rotation);

    // 2. crop bounding box
    final int left = bbox.left.round().clamp(0, rotated.width - 1);
    final int top = bbox.top.round().clamp(0, rotated.height - 1);
    final int right = bbox.right.round().clamp(0, rotated.width);
    final int bottom = bbox.bottom.round().clamp(0, rotated.height);

    final img.Image cropped = img.copyCrop(
      rotated,
      left,
      top,
      right - left,
      bottom - top,
    );

    // QUAN TRỌNG: Flip ảnh nếu là front camera
    img.Image flipped = cropped;
    if (camera.lensDirection == CameraLensDirection.front) {
      flipped = _flipImageHorizontal(cropped);
    }

    // 4. resize về inputSize x inputSize
    final img.Image resized = img.copyResizeCropSquare(flipped, inputSize);

    final Uint8List bytes = Uint8List.fromList(
      img.encodeJpg(
        resized,
        quality: 95,
      ), // Tăng quality để giữ màu sắc tốt hơn
    );
    return bytes;
  }

  /// Crop face từ ảnh API - đơn giản: crop square ở giữa (giống compareImageInCard)
  Future<Uint8List> cropFaceFromApiImage(Uint8List imageBytes) async {
    try {
      // 1. Decode ảnh
      final img.Image? fullImage = img.decodeImage(imageBytes);
      if (fullImage == null) {
        throw Exception('Failed to decode API image');
      }

      final img.Image resized;
      if (fullImage.width == fullImage.height) {
        resized = img.copyResize(
          fullImage,
          width: inputSize,
          height: inputSize,
        );
      } else {
        resized = img.copyResizeCropSquare(fullImage, inputSize);
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: 95));
    } catch (e) {
      print('[ERROR] Error cropping face from API image: $e');
      rethrow;
    }
  }

  /// Crop và align face từ CameraImage với landmarks
  Future<FaceImageResult> cropFaceFromCameraImageWithAlignment(
    CameraImage image,
    CameraDescription camera,
    Face face,
  ) async {
    final img.Image fullImg = _convertCameraImageToImage(image);

    final int rotation = camera.sensorOrientation;
    final img.Image rotated = _rotateImageIfNeeded(fullImg, rotation);

    // 3. Align face dựa trên landmarks
    final alignedImage = _alignFaceWithLandmarks(rotated, face, camera);

    img.Image finalImage;
    if (alignedImage == null) {
      final box = face.boundingBox;
      final cropped = img.copyCrop(
        rotated,
        box.left.round().clamp(0, rotated.width - 1),
        box.top.round().clamp(0, rotated.height - 1),
        box.width.round().clamp(1, rotated.width),
        box.height.round().clamp(1, rotated.height),
      );

      // Flip nếu front camera
      if (camera.lensDirection == CameraLensDirection.front) {
        finalImage = _flipImageHorizontal(cropped);
      } else {
        finalImage = cropped;
      }
    } else {
      finalImage = alignedImage;
    }

    // 4. Resize về inputSize
    final img.Image resized = img.copyResizeCropSquare(finalImage, inputSize);

    // 5. Encode model bytes (giữ nguyên orientation tốt cho model)
    final Uint8List modelBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: 95),
    );

    // 6. Encode display bytes (xoay -90 độ để hiển thị đúng UI)
    final img.Image displayImg = img.copyRotate(resized, -90);
    final Uint8List displayBytes = Uint8List.fromList(
      img.encodeJpg(displayImg, quality: 95),
    );

    return FaceImageResult(modelBytes: modelBytes, displayBytes: displayBytes);
  }

  /// Align face dựa trên landmarks (mắt, mũi, miệng)
  img.Image? _alignFaceWithLandmarks(
    img.Image image,
    Face face,
    CameraDescription camera,
  ) {
    try {
      // Lấy landmarks (chỉ cần mắt và mũi là đủ để align)
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];

      if (leftEye == null || rightEye == null || noseBase == null) {
        return null;
      }

      // Lấy vị trí các landmarks
      final eyeCenterLeft = leftEye.position;
      final eyeCenterRight = rightEye.position;
      final noseCenter = noseBase.position;

      // Tính góc xoay dựa trên 2 mắt (để align mắt về ngang)
      final dx = eyeCenterRight.x - eyeCenterLeft.x;
      final dy = eyeCenterRight.y - eyeCenterLeft.y;
      final angle = atan2(dy, dx) * 180 / pi;

      // Tính khoảng cách giữa 2 mắt để tính padding
      final eyeDistance = sqrt(dx * dx + dy * dy);

      // Tính center point giữa 2 mắt
      final centerX = (eyeCenterLeft.x + eyeCenterRight.x) / 2;
      final centerY = (eyeCenterLeft.y + eyeCenterRight.y) / 2;

      // Chiều cao ước tính dựa trên khoảng cách mắt-mũi
      final eyeToNoseDistance = (noseCenter.y - centerY).abs();
      final estimatedFaceHeight = eyeToNoseDistance * 2.5;

      // Crop khuôn mặt với padding dựa trên eye distance
      final boxSize = max(estimatedFaceHeight, eyeDistance * 2.5);
      final cropX = (centerX - boxSize / 2).round().clamp(0, image.width - 1);
      final cropY = (centerY - boxSize / 2).round().clamp(0, image.height - 1);
      final cropW = (boxSize.round()).clamp(1, image.width - cropX);
      final cropH = (boxSize.round()).clamp(1, image.height - cropY);

      // Crop trước (để landmarks vẫn đúng)
      final cropped = img.copyCrop(image, cropX, cropY, cropW, cropH);

      // Rotate phần đã crop để align mắt về ngang
      img.Image rotated = cropped;
      if (angle.abs() > 1.0) {
        rotated = img.copyRotate(cropped, -angle);
      }

      // Flip nếu front camera
      img.Image finalAligned = rotated;
      if (camera.lensDirection == CameraLensDirection.front) {
        finalAligned = _flipImageHorizontal(rotated);
      }

      return finalAligned;
    } catch (e) {
      return null;
    }
  }

  img.Image _rotateImageIfNeeded(img.Image src, int rotation) {
    switch (rotation) {
      case 90:
        return img.copyRotate(src, 90);
      case 180:
        return img.copyRotate(src, 180);
      case 270:
        return img.copyRotate(src, 270);
      default:
        return src;
    }
  }

  img.Image _convertCameraImageToImage(CameraImage cameraImage) {
    // Removed excessive debug prints to reduce memory usage

    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final img.Image imgImage = img.Image(width, height);

    // Nhận biết format
    final formatGroup = cameraImage.format.group;
    final numPlanes = cameraImage.planes.length;

    // iOS: BGRA8888 (1 plane)
    if (formatGroup == ImageFormatGroup.bgra8888 && numPlanes == 1) {
      final bytes = cameraImage.planes[0].bytes;
      int pixelIndex = 0;
      // BGRA theo từng pixel: B, G, R, A
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final b = bytes[pixelIndex] & 0xff;
          final g = bytes[pixelIndex + 1] & 0xff;
          final r = bytes[pixelIndex + 2] & 0xff;
          // final a = bytes[pixelIndex + 3] & 0xff; // không cần dùng
          imgImage.setPixelRgba(x, y, r, g, b);
          pixelIndex += 4;
        }
      }
      return imgImage;
    }

    // Trường hợp chỉ có Y plane (coi như grayscale)
    if (numPlanes < 2) {
      final planeY = cameraImage.planes[0].bytes;
      final yBytesPerRow = cameraImage.planes[0].bytesPerRow;

      for (int j = 0; j < height; j++) {
        for (int i = 0; i < width; i++) {
          final yIndex = j * yBytesPerRow + i;
          if (yIndex < planeY.length) {
            final y = planeY[yIndex] & 0xff;
            imgImage.setPixelRgba(i, j, y, y, y); // Grayscale
          }
        }
      }
      return imgImage;
    }

    // YUV420/NV21 (Android)
    final planeY = cameraImage.planes[0].bytes;
    final planeU = cameraImage.planes[1].bytes;

    // Plane V có thể là plane[2] hoặc interleaved với U
    final hasSeparateV = numPlanes >= 3;
    final planeV = hasSeparateV ? cameraImage.planes[2].bytes : planeU;

    final yBytesPerRow = cameraImage.planes[0].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;

    for (int j = 0; j < height; j++) {
      final yRowStart = j * yBytesPerRow;
      final uvRowStart = (j >> 1) * uvRowStride;

      for (int i = 0; i < width; i++) {
        // Y component
        final yIndex = yRowStart + i;
        if (yIndex >= planeY.length) continue;
        final y = planeY[yIndex] & 0xff;

        // U and V components
        final uvIndex = uvRowStart + ((i >> 1) * uvPixelStride);

        int u = 128; // Default neutral value
        int v = 128;

        if (hasSeparateV) {
          // Separate U and V planes
          if (uvIndex < planeU.length && uvIndex < planeV.length) {
            u = planeU[uvIndex] & 0xff;
            v = planeV[uvIndex] & 0xff;
          }
        } else {
          // Interleaved UV (NV12/NV21 format)
          if (uvIndex + 1 < planeU.length) {
            u = planeU[uvIndex] & 0xff;
            v = planeU[uvIndex + 1] & 0xff;
          }
        }

        // Convert YUV to RGB
        final r = (y + (1.370705 * (v - 128))).round().clamp(0, 255);
        final g = (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128)))
            .round()
            .clamp(0, 255);
        final b = (y + (1.732446 * (u - 128))).round().clamp(0, 255);

        imgImage.setPixelRgba(i, j, r, g, b);
      }
    }

    return imgImage;
  }

  /// Chạy model trên ảnh mặt đã crop (Uint8List) -> trả về embedding List<double>
  Future<List<double>> getEmbedding(
    Uint8List faceImageBytes, {
    String? source,
  }) async {
    await loadModel();

    try {
      // decode image
      final img.Image? image = img.decodeImage(faceImageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final img.Image input = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Lấy input/output tensors
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        throw Exception('Model has no input or output tensors');
      }

      final inputTensor = inputTensors[0];
      final outputTensor = outputTensors[0];

      // Log tensor shapes để kiểm tra
      print('[DEBUG] Input tensor shape: ${inputTensor.shape}');
      print('[DEBUG] Output tensor shape: ${outputTensor.shape}');
      print('[DEBUG] Expected inputSize: $inputSize, embSize: $embSize');

      // Kiểm tra input size có khớp không
      if (inputTensor.shape.length == 4) {
        final expectedHeight = inputTensor.shape[1];
        final expectedWidth = inputTensor.shape[2];
        if (expectedHeight != inputSize || expectedWidth != inputSize) {
          print(
            '[WARNING] Model expects ${expectedHeight}x${expectedWidth}, but code uses ${inputSize}x${inputSize}',
          );
        }
      }

      // Tạo input data array [1, height, width, 3] => [1,512]
      final List<List<List<List<double>>>> inputArray = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
        ),
      );

      // Fill input - RGB format
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = input.getPixel(x, y);
          final r = img.getRed(pixel).toDouble();
          final g = img.getGreen(pixel).toDouble();
          final b = img.getBlue(pixel).toDouble();

          // ArcFace normalization: (pixel / 255.0 - 0.5) / 0.5
          // Hoặc có thể dùng: pixel / 255.0 * 2.0 - 1.0 (tương đương)
          inputArray[0][y][x][0] = (r / 255.0 - 0.5) / 0.5; // Red
          inputArray[0][y][x][1] = (g / 255.0 - 0.5) / 0.5; // Green
          inputArray[0][y][x][2] = (b / 255.0 - 0.5) / 0.5; // Blue
        }
      }
      // Set input tensor
      inputTensor.setTo(inputArray);

      // Tạo output array với shape khớp với model output
      final outputShape = outputTensor.shape;
      final expectedOutputSize = outputShape.length == 2
          ? outputShape[1]
          : embSize;

      final List<List<double>> outputArray = List.generate(
        outputShape[0], // Thường là 1
        (_) => List.filled(expectedOutputSize, 0.0),
      );

      _interpreter!.run(inputArray, outputArray);

      // Lấy embedding từ output[0]
      final List<double> embedding = List<double>.from(outputArray[0]);

      // L2 Normalization: normalize embedding về unit vector
      double sumSquared = 0.0;
      for (int i = 0; i < embedding.length; i++) {
        sumSquared += embedding[i] * embedding[i];
      }
      final l2Norm = sqrt(sumSquared);

      // Normalize về unit vector (norm = 1.0)
      if (l2Norm > 1e-8) {
        for (int i = 0; i < embedding.length; i++) {
          embedding[i] = embedding[i] / l2Norm;
        }
      }

      return embedding;
    } catch (e, stackTrace) {
      print('[ERROR] Error in getEmbedding ($source): $e');
      print('[ERROR] StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<double> compareImageInCard(
    List<double> liveEmb,
    String studentImageUrl,
  ) async {
    try {
      print('[DEBUG] ========== START COMPARE ==========');
      print('[DEBUG] Live embedding (from camera frame):');
      print('[DEBUG]   Length: ${liveEmb.length}');
      print(
        '[DEBUG]   Values: [${liveEmb.map((e) => e.toStringAsFixed(4)).join(", ")}]',
      );

      // 1. Tải ảnh từ API
      print('[DEBUG] Loading image from API: $studentImageUrl');
      final response = await http.get(Uri.parse(studentImageUrl));
      if (response.statusCode != 200) {
        print('[ERROR] Failed to load image: Status ${response.statusCode}');
        return 0.0;
      }

      final Uint8List studentBytes = response.bodyBytes;
      print('[DEBUG] Image loaded: ${studentBytes.length} bytes');

      // 2. Decode & resize ảnh
      final img.Image? studentImage = img.decodeImage(studentBytes);
      if (studentImage == null) {
        print('[ERROR] Failed to decode student image');
        return 0.0;
      }

      print(
        '[DEBUG] Student image decoded: ${studentImage.width}x${studentImage.height}',
      );

      // QUAN TRỌNG: Xử lý giống hệt như camera image
      // QUAN TRỌNG: Resize giống như camera image
      // Không dùng copyResizeCropSquare, mà dùng copyResize để giữ tỷ lệ
      final img.Image resized;
      if (studentImage.width == studentImage.height) {
        resized = img.copyResize(
          studentImage,
          width: inputSize,
          height: inputSize,
        );
      } else {
        // Nếu không vuông, resize và crop square ở giữa
        resized = img.copyResizeCropSquare(studentImage, inputSize);
      }

      print(
        '[DEBUG] Student image resized to: ${resized.width}x${resized.height}',
      );

      // Log sample pixels để so sánh với camera
      print('[DEBUG] API image sample pixels:');
      for (int i = 0; i < 3 && i < inputSize; i++) {
        for (int j = 0; j < 3 && j < inputSize; j++) {
          final pixel = resized.getPixel(j, i);
          print(
            '[DEBUG]   Pixel[$i,$j]: R=${img.getRed(pixel)}, G=${img.getGreen(pixel)}, B=${img.getBlue(pixel)}',
          );
        }
      }

      // 3. Tạo embedding của ảnh mục tiêu - THÊM source tag
      final List<double> targetEmb = await getEmbedding(
        Uint8List.fromList(img.encodeJpg(resized, quality: 85)),
        source: 'API_IMAGE',
      );

      print('[DEBUG] Target embedding (from API image):');
      print('[DEBUG]   Length: ${targetEmb.length}');
      print(
        '[DEBUG]   Values: [${targetEmb.map((e) => e.toStringAsFixed(4)).join(", ")}]',
      );

      // So sánh chi tiết từng giá trị
      print('[DEBUG] ========== DETAILED COMPARISON ==========');
      print('[DEBUG] Index | Camera      | Target    | Diff      | Product');
      print('[DEBUG] ----- | --------- | --------- | --------- | ---------');
      double dotProduct = 0;
      double sumLiveSq = 0;
      double sumTargetSq = 0;

      for (int i = 0; i < liveEmb.length; i++) {
        final diff = (liveEmb[i] - targetEmb[i]).abs();
        final product = liveEmb[i] * targetEmb[i];
        dotProduct += product;
        sumLiveSq += liveEmb[i] * liveEmb[i];
        sumTargetSq += targetEmb[i] * targetEmb[i];

        print(
          '[DEBUG]   $i    | ${liveEmb[i].toStringAsFixed(4).padLeft(8)} | ${targetEmb[i].toStringAsFixed(4).padLeft(8)} | ${diff.toStringAsFixed(4).padLeft(8)} | ${product.toStringAsFixed(4).padLeft(8)}',
        );
      }

      final normA = sqrt(sumLiveSq);
      final normB = sqrt(sumTargetSq);

      // Cosine similarity
      // Vì đã L2 normalize embeddings trong getEmbedding, norm của chúng nên = 1.0
      // Cosine similarity = dot product / (normA * normB)
      final similarity = dotProduct / (normA * normB);

      print('[DEBUG] ----- | --------- | --------- | --------- | ---------');
      print(
        '[DEBUG] Sum   |           |           |           | ${dotProduct.toStringAsFixed(6)}',
      );
      print(
        '[DEBUG] Norm A (live, should be ~1.0 after L2 norm): ${normA.toStringAsFixed(6)}',
      );
      print(
        '[DEBUG] Norm B (target, should be ~1.0 after L2 norm): ${normB.toStringAsFixed(6)}',
      );
      print('[DEBUG] Cosine similarity: ${similarity.toStringAsFixed(6)}');

      // Tính Euclidean distance
      double euclideanDist = 0;
      for (int i = 0; i < liveEmb.length; i++) {
        euclideanDist +=
            (liveEmb[i] - targetEmb[i]) * (liveEmb[i] - targetEmb[i]);
      }
      euclideanDist = sqrt(euclideanDist);
      print('[DEBUG] Euclidean distance: ${euclideanDist.toStringAsFixed(6)}');
      print('[DEBUG] ============================================');

      // So sánh 2 embeddings có giống nhau không
      bool areIdentical = true;
      double maxDiff = 0;
      int maxDiffIndex = -1;
      for (int i = 0; i < liveEmb.length; i++) {
        final diff = (liveEmb[i] - targetEmb[i]).abs();
        if (diff > maxDiff) {
          maxDiff = diff;
          maxDiffIndex = i;
        }
        if (diff > 0.0001) {
          areIdentical = false;
        }
      }
      print('[DEBUG] Are embeddings identical? $areIdentical');
      print(
        '[DEBUG] Max difference: ${maxDiff.toStringAsFixed(6)} at index $maxDiffIndex',
      );

      print('[DEBUG] ========== END COMPARE ==========');

      return similarity;
    } catch (e, stackTrace) {
      print('[ERROR] Error in compareImageInCard: $e');
      print('[ERROR] StackTrace: $stackTrace');
      return 0.0;
    }
  }

  /// Test model với cùng 1 ảnh 2 lần - nếu embeddings khác nhau => model/preprocessing có vấn đề
  Future<void> testModelConsistency() async {
    print('[TEST] ========== TESTING MODEL CONSISTENCY ==========');

    // Tạo một ảnh test đơn giản
    final testImage = img.Image(inputSize, inputSize);
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        testImage.setPixelRgba(x, y, 128, 128, 128); // Gray image
      }
    }

    final testBytes = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));

    // Test 1: Cùng 1 ảnh, chạy 2 lần
    print('[TEST] Running same image twice...');
    final emb1 = await getEmbedding(testBytes, source: 'TEST_1');
    final emb2 = await getEmbedding(testBytes, source: 'TEST_2');

    double diff = 0;
    for (int i = 0; i < emb1.length; i++) {
      diff += (emb1[i] - emb2[i]).abs();
    }
    print(
      '[TEST] Difference between 2 runs of same image: ${diff.toStringAsFixed(6)}',
    );
    print('[TEST] Expected: 0.0 (should be identical)');

    // Test 2: So sánh embeddings của ảnh khác nhau
    final testImage2 = img.Image(inputSize, inputSize);
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        testImage2.setPixelRgba(x, y, 200, 100, 50); // Different color
      }
    }
    final testBytes2 = Uint8List.fromList(
      img.encodeJpg(testImage2, quality: 90),
    );
    final emb3 = await getEmbedding(testBytes2, source: 'TEST_3');

    double diff2 = 0;
    for (int i = 0; i < emb1.length; i++) {
      diff2 += (emb1[i] - emb3[i]).abs();
    }
    print(
      '[TEST] Difference between different images: ${diff2.toStringAsFixed(6)}',
    );
    print('[TEST] Expected: > 0.1 (should be different)');

    print(
      '[TEST] Checking if raw embeddings (before normalization) are different...',
    );
    print('[TEST] This requires checking raw output from model');

    print('[TEST] ============================================');
  }

  void testPreprocessing(img.Image image) {
    print('[TEST] ========== TESTING PREPROCESSING ==========');

    final pixel1 = image.getPixel(0, 0);
    final r1 = img.getRed(pixel1);
    final g1 = img.getGreen(pixel1);
    final b1 = img.getBlue(pixel1);

    final normalizedR = (r1 - 127.5) / 128.0;
    final normalizedG = (g1 - 127.5) / 128.0;
    final normalizedB = (b1 - 127.5) / 128.0;

    print('[TEST] Original pixel: R=$r1, G=$g1, B=$b1');
    print(
      '[TEST] Normalized: R=${normalizedR.toStringAsFixed(4)}, G=${normalizedG.toStringAsFixed(4)}, B=${normalizedB.toStringAsFixed(4)}',
    );
    print('[TEST] Expected range: [-1.0, ~1.0]');
    print('[TEST] ============================================');
  }
}
