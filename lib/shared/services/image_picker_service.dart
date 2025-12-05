import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thesis/common/extentions/router_x.dart';
import 'package:thesis/shared/router/router_key.dart';
import '../widgets/image_source_dialog.dart';
import '../widgets/alternative_barcode_scanner_widget.dart';
import '../widgets/test_barcode_scanner_widget.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Chụp ảnh từ camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Chọn ảnh từ gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Hiển thị dialog chọn nguồn ảnh
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    if (Platform.isIOS) {
      return await _showIOSActionSheet(context);
    } else {
      return await _showAndroidDialog(context);
    }
  }

  /// Hiển thị barcode scanner với fallback mechanism
  static Future<void> showBarcodeScanner(BuildContext context) async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TestBarcodeScannerWidget(
            onBarcodeDetected: (barcode) {
              debugPrint('Barcode detected in service: $barcode');
              // Pop scanner first, then navigate
              Navigator.of(context).pop();
              context.pushWithPath(
                RouterPath.verification,
                extra: {'mssv': barcode},
              );
            },
            onCancel: () => context.pop(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Test scanner error: $e');

      // Fallback: Thử alternative scanner
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AlternativeBarcodeScannerWidget(
              onBarcodeDetected: (barcode) {
                debugPrint('Alternative barcode detected in service: $barcode');
                // Pop scanner first, then navigate
                Navigator.of(context).pop();
                context.pushWithPath(
                  RouterPath.verification,
                  extra: {'mssv': barcode},
                );
              },
              onCancel: () => context.pop(),
            ),
          ),
        );
      } catch (alternativeError) {
        debugPrint('Alternative scanner error: $alternativeError');
      }
    }
  }

  /// Hiển thị ActionSheet cho iOS
  static Future<File?> _showIOSActionSheet(BuildContext context) async {
    File? selectedImage;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Chọn nguồn ảnh'),
          message: const Text(
            'Vui lòng chọn cách bạn muốn chụp hoặc chọn ảnh thẻ sinh viên',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                selectedImage = await pickImageFromGallery();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.photo, color: CupertinoColors.systemBlue),
                  SizedBox(width: 8),
                  Text('Chọn từ thư viện'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await showBarcodeScanner(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 8),
                  Text('Quét mã vạch'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
        );
      },
    );

    return selectedImage;
  }

  /// Hiển thị Dialog cho Android
  static Future<File?> _showAndroidDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7)),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // UIColors.bg equivalent
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(
                    0xFF333333,
                  ).withValues(alpha: 0.1), // UIColors.lightGray equivalent
                  width: 1,
                ),
              ),
              child: ImageSourceDialog(
                onCameraTap: () async {
                  final image = await pickImageFromCamera();
                  Navigator.of(context).pop(image);
                },
                onGalleryTap: () async {
                  final image = await pickImageFromGallery();
                  Navigator.of(context).pop(image);
                },
                onBarcodeTap: () async {
                  await showBarcodeScanner(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
