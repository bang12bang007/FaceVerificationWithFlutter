import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/shared/widgets/button.dart';
import 'package:thesis/shared/widgets/text.dart';

class AlternativeBarcodeScannerWidget extends StatefulWidget {
  const AlternativeBarcodeScannerWidget({
    super.key,
    required this.onBarcodeDetected,
    required this.onCancel,
  });

  final Function(String barcode) onBarcodeDetected;
  final VoidCallback onCancel;

  @override
  State<AlternativeBarcodeScannerWidget> createState() =>
      _AlternativeBarcodeScannerWidgetState();
}

class _AlternativeBarcodeScannerWidgetState
    extends State<AlternativeBarcodeScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;
  bool isScanning = true;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (isScanning && scanData.code != null) {
        setState(() {
          isScanning = false;
        });
        debugPrint('Alternative barcode scanned: ${scanData.code}');
        widget.onBarcodeDetected(scanData.code!);
      }
    });
  }

  void _toggleFlash() async {
    if (controller != null) {
      setState(() {
        isFlashOn = !isFlashOn;
      });
      await controller!.toggleFlash();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // QR Scanner view
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: UIColors.green,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 250,
            ),
          ),

          // Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton.widget(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: UIColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  AppButton.widget(
                    onTap: _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: isFlashOn ? UIColors.yellow : UIColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.semiBold(
                    'Quét mã vạch thẻ sinh viên',
                    fontSize: 18,
                    color: UIColors.white,
                    textAlign: TextAlign.center,
                  ),
                  8.gap,
                  AppText.regular(
                    'Đặt mã vạch vào khung để quét',
                    fontSize: 14,
                    color: UIColors.lightGray,
                    textAlign: TextAlign.center,
                  ),
                  24.gap,
                  Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: UIColors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
