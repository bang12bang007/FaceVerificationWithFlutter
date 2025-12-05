import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/core/enums/bloc_status.dart';
import 'package:thesis/shared/widgets/text.dart';
import '../../model/face_scan_model.dart';
import '../cubit/face_scan_cubit.dart';
import '../widget/over_lay.dart';
import '../../../face_comparison/presentation/page/face_comparison_screen.dart';

class FaceScanPage extends StatefulWidget {
  final CameraDescription camera;
  final String avatar;

  const FaceScanPage({super.key, required this.camera, required this.avatar});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  late CameraController _controller;
  late FaceScanCubit _cubit;
  final FaceModelService _modelService = FaceModelService();
  bool _isCameraStreamActive = false;
  bool _pausedForComparison = false;
  StreamSubscription<FaceScanState>? _stateSubscription;
  DateTime? _lastFrameTime;
  static const _frameThrottleMs = 100;

  Future<void> _startCameraStream() async {
    if (!_controller.value.isInitialized || _isCameraStreamActive) return;
    try {
      await _controller.startImageStream((CameraImage image) {
        final now = DateTime.now();
        if (_lastFrameTime != null &&
            now.difference(_lastFrameTime!).inMilliseconds < _frameThrottleMs) {
          return; // Bỏ qua frame này
        }
        _lastFrameTime = now;

        // Kiểm tra mounted trước khi gọi
        if (mounted && !_cubit.isClosed) {
          _cubit.handleCameraImage(image, widget.camera, widget.avatar);
        }
      });
      _isCameraStreamActive = true;
    } catch (e) {
      debugPrint('[ERROR] Error starting camera stream: $e');
    }
  }

  Future<void> _stopCameraStream() async {
    if (!_isCameraStreamActive) return;
    try {
      await _controller.stopImageStream();
      _isCameraStreamActive = false;
    } catch (e) {
      debugPrint('[ERROR] Error stopping camera stream: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = FaceScanCubit(modelService: _modelService);
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller.initialize().then((_) {
      if (!mounted) return;
      _startCameraStream();
      setState(() {});
    });

    _stateSubscription = _cubit.stream.listen((state) {
      if (!mounted) return;

      if (state.status == BlocStatus.loading) {
        _stopCameraStream();
      } else if (state.status == BlocStatus.checking &&
          !_isCameraStreamActive &&
          !_pausedForComparison) {
        _startCameraStream();
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;

    if (_isCameraStreamActive) {
      _controller.stopImageStream();
    }

    _controller.dispose();

    if (!_cubit.isClosed) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<FaceScanCubit, FaceScanState>(
          builder: (context, state) {
            final isLoading = state.status == BlocStatus.loading;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (_controller.value.isInitialized && !isLoading)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.previewSize?.height,
                      height: _controller.value.previewSize?.width,
                      child: CameraPreview(_controller),
                    ),
                  ),
                if (!isLoading) const FaceOverlay(),
                if (isLoading)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Lottie.asset(
                              'assets/lottie/Take photo.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          20.gap,
                          AppText.semiBold('Đang xử lý...', fontSize: 18),
                        ],
                      ),
                    ),
                  ),

                // bottom feedback
                if (!isLoading)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: BlocBuilder<FaceScanCubit, FaceScanState>(
                      builder: (context, state) {
                        if (state.status == BlocStatus.checking ||
                            state.status == BlocStatus.hasData) {
                          return const SizedBox();
                        } else if (state.status == BlocStatus.success) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Xác thực thành công ✔ (sim = ${state.similarity?.toStringAsFixed(2)})",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              12.gap,
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (state.cameraImageBytes != null) {
                                    _pausedForComparison = true;
                                    await _stopCameraStream();

                                    Uint8List displayBytes =
                                        state.cameraImageBytes!;

                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FaceComparisonScreen(
                                              cameraImageBytes: displayBytes,
                                              apiImageUrl: widget.avatar,
                                              similarity: state.similarity,
                                            ),
                                      ),
                                    );

                                    // When back, allow stream to resume
                                    _pausedForComparison = false;
                                    if (mounted) {
                                      _startCameraStream();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.compare_arrows),
                                label: const Text('Xem so sánh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        } else if (state.status == BlocStatus.error) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Xác thực thất bại (sim = ${state.similarity?.toStringAsFixed(2)})",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (state.cameraImageBytes != null) {
                                    _pausedForComparison = true;
                                    await _stopCameraStream();
                                    Uint8List displayBytes =
                                        state.cameraImageBytes!;
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FaceComparisonScreen(
                                              cameraImageBytes: displayBytes,
                                              apiImageUrl: widget.avatar,
                                              similarity: state.similarity,
                                            ),
                                      ),
                                    );

                                    // When back, allow stream to resume
                                    _pausedForComparison = false;
                                    if (mounted) {
                                      _startCameraStream();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.compare_arrows),
                                label: const Text('Xem so sánh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
