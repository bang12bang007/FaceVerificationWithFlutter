import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/shared/widgets/text.dart';

class TestBarcodeScannerWidget extends StatefulWidget {
  const TestBarcodeScannerWidget({
    super.key,
    required this.onBarcodeDetected,
    required this.onCancel,
  });

  final Function(String barcode) onBarcodeDetected;
  final VoidCallback onCancel;

  @override
  State<TestBarcodeScannerWidget> createState() =>
      _TestBarcodeScannerWidgetState();
}

class _TestBarcodeScannerWidgetState extends State<TestBarcodeScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _hasScanned = false;

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
      if (scanData.code != null && !_hasScanned) {
        _hasScanned = true;
        debugPrint('Barcode scanned: ${scanData.code}');
        widget.onBarcodeDetected(scanData.code!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onCancel,
        ),
        title: const Text(
          'Quét mã vạch',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: UIColors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutWidth: 400,
                cutOutHeight: 300,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppText.semiBold(
                  'Đặt mã vạch vào khung để quét',
                  fontSize: 16,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                ),
                8.gap,
                AppText.regular(
                  'Quét mã vạch thẻ sinh viên',
                  fontSize: 14,
                  color: UIColors.lightGray,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
