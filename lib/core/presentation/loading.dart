import 'dart:math';

import 'package:flutter/material.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/color_x.dart';

import '../../../../generated/assets.gen.dart';


class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return RingSpinner(
      color: UIColors.redLight,
      lineWidth: 2,
      size: 65,
      centerWidget: Assets.svg.icLogo.svg(
        width: 40,
        colorFilter: UIColors.white.filter,
      ),
    );
  }
}

class RingSpinner extends StatefulWidget {
  const RingSpinner({
    super.key,
    required this.color,
    this.lineWidth = 7.0,
    this.size = 100.0,
    this.duration = const Duration(milliseconds: 1200),
    this.centerWidget,
  });

  final Color color;
  final double size;
  final double lineWidth;
  final Duration duration;
  final Widget? centerWidget;

  @override
  State<RingSpinner> createState() => _RingSpinnerState();
}

class _RingSpinnerState extends State<RingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;
  late final Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );
    _animation2 = Tween(begin: -2 / 3, end: 1 / 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.linear),
      ),
    );
    _animation3 = Tween(begin: 0.25, end: 5 / 6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: _RingCurve()),
      ),
    );

    _controller
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size.square(widget.size),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Transform(
              transform: Matrix4.identity()
                ..rotateZ(_animation1.value * 5 * pi / 6),
              alignment: FractionalOffset.center,
              child: CustomPaint(
                foregroundPainter: RingPainter(
                  paintWidth: widget.lineWidth,
                  trackColor: widget.color,
                  progressPercent: _animation3.value,
                  startAngle: pi * _animation2.value,
                ),
              ),
            ),
          ),
          if (widget.centerWidget != null)
            Align(
              alignment: Alignment.center,
              child: widget.centerWidget,
            ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({
    required this.paintWidth,
    this.progressPercent,
    this.startAngle,
    required this.trackColor,
  }) : trackPaint = Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = paintWidth
          ..strokeCap = StrokeCap.square;

  final double paintWidth;
  final Paint trackPaint;
  final Color trackColor;
  final double? progressPercent;
  final double? startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - paintWidth) / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle!,
      2 * pi * progressPercent!,
      false,
      trackPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _RingCurve extends Curve {
  const _RingCurve();

  @override
  double transform(double t) => (t <= 0.5) ? 2 * t : 2 * (1 - t);
}
