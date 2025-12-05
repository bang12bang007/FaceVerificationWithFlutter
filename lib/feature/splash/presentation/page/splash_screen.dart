import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/core/svg/util_svg.dart';
import 'package:thesis/feature/splash/presentation/cubit/splash_cubit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => SplashCubit()..fetch(context),
        child: BlocBuilder<SplashCubit, SplashState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [UIColors.blue, UIColors.white, UIColors.redLight],
                ),
              ),
              child: Center(child: SvgPicture.asset(UtilSvg.logo)),
            );
          },
        ),
      ),
    );
  }
}
