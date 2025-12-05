import 'package:flutter/material.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/shared/router/app_router.dart'; // import AppRouter của bạn
import 'package:thesis/core/presentation/live_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.shareInstance.router; // gọi router từ singleton

    return MaterialApp.router(
      title: 'Student ID Card Verification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: UIColors.black),
        useMaterial3: true,
      ),
      builder: (context, child) {
        LiveData.mainContext = context;
        return child ?? const SizedBox.shrink();
      },
      routerConfig: router, // dùng router của GoRouter
    );
  }
}
