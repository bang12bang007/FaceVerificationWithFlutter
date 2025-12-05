import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/core/enums/bloc_status.dart';
import '../cubit/face_scan_cubit.dart';

class FaceOverlay extends StatefulWidget {
  const FaceOverlay({super.key});

  @override
  State<FaceOverlay> createState() => _FaceOverlayState();
}

class _FaceOverlayState extends State<FaceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static Color _getColorByStatus(BlocStatus status) {
    switch (status) {
      case BlocStatus.checking:
        return Colors.white;
      case BlocStatus.hasData:
        return Colors.greenAccent;
      case BlocStatus.loading:
        return Colors.blueAccent;
      case BlocStatus.success:
        return Colors.green;
      case BlocStatus.error:
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  static String _getMessageByStatus(BlocStatus status) {
    switch (status) {
      case BlocStatus.checking:
        return "Vui lòng đưa khuôn mặt vào khung hình";
      case BlocStatus.hasData:
        return "Giữ nguyên khuôn mặt...";
      case BlocStatus.loading:
        return "Đang xác thực...";
      case BlocStatus.success:
        return "";
      case BlocStatus.error:
        return "";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceScanCubit, FaceScanState>(
      builder: (context, state) {
        final status = state.status;
        final color = _getColorByStatus(status);
        final message = _getMessageByStatus(status);

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _OverlayPainter(
                    color: color,
                    status: status,
                    scanValue: _animationController.value,
                  ),
                );
              },
            ),
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Color color;
  final BlocStatus status;
  final double scanValue;

  _OverlayPainter({
    required this.color,
    required this.status,
    required this.scanValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);

    final width = size.width * 0.75;
    final height = width * 1.35;
    
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    // Use RRect with large radius to make it an oval/rounded rectangle
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width));

    // 1. Draw dark background with cutout (The "Mask")
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.85);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect);
    
    canvas.drawPath(path, bgPaint);

    // 2. Draw border around the cutout
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawRRect(rrect, borderPaint);

    // 3. Draw scanning line animation
    if (status == BlocStatus.checking || status == BlocStatus.hasData) {
      final scanY = rect.top + (rect.height * scanValue);
      
      // Create a gradient for the scanning line
      final scanPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0.0),
            color.withOpacity(0.8),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(rect.left, scanY, rect.width, 5));
      
      // Draw the line
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 20, scanY, rect.width - 40, 5),
        scanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.status != status ||
        oldDelegate.scanValue != scanValue;
  }
}
