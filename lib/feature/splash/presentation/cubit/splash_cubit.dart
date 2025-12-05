import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/common/extentions/router_x.dart';

import '../../../../shared/router/router_key.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashState());

  fetch(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        context.goWithPath(RouterPath.home);
      }
    });
  }
}
