import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/contenxt_x.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/common/extentions/router_x.dart';
import 'package:thesis/core/presentation/dialog.dart' show AppDialog;
import 'package:thesis/feature/start/presentation/cubit/start_cubit.dart';
import 'package:thesis/generated/assets.gen.dart';
import 'package:thesis/shared/router/router_key.dart';
import 'package:thesis/shared/widgets/button.dart';
import 'package:thesis/shared/widgets/text.dart';
import 'package:thesis/shared/widgets/text_field.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white12,
      body: BlocProvider(
        create: (context) => StartCubit()..fetchList(),
        child: BlocBuilder<StartCubit, StartState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Spacer(flex: 1),
                  Assets.svg.icLogoDark.svg(height: 150),
                  24.gap,
                  AppText.semiBold(
                    'Xác thực thẻ sinh viên',
                    color: UIColors.white,
                    fontSize: 18,
                    textAlign: TextAlign.center,
                  ),

                  AppText.medium(
                    'Student id card verification',
                    color: UIColors.redLight,
                    fontSize: 18,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(flex: 1),
                  AppText.semiBold(
                    'Mã số phòng thi',
                    color: UIColors.lightGray,
                  ),
                  8.gap,
                  AppTF.common(
                    keyboardType: TextInputType.number,
                    controller: context.read<StartCubit>().roomCodeController,
                    onChanged: (value) =>
                        context.read<StartCubit>().changeRoomCode(value),
                    hintText: 'Nhập mã số phòng thi',
                  ),
                  Spacer(flex: 2),
                  AppButton.fill(
                    onTap: () {
                      if (!state.isDisableButton) {
                        if (context.read<StartCubit>().isValidRoomCode(
                          state.roomCode,
                        )) {
                          context.pushWithPath(
                            RouterPath.introduce,
                            extra: {'id': state.roomCode},
                          );

                        } else {
                          context.showDialog(
                            horizontalMargin: 24,
                            AppDialog.simple(
                              title: 'Mã phòng thi không hợp lệ',
                              content: 'Vui lòng kiểm tra lại mã số phòng thi',
                              btnTitle: 'Đóng',
                            ),
                          );
                        }
                      } else {
                        context.showDialog(
                          horizontalMargin: 24,
                          AppDialog.simple(
                            title: 'Đã xảy ra lỗi',
                            content: 'Vui lòng nhập mã số phòng thi',
                            btnTitle: 'Đóng',
                          ),
                        );
                      }
                    },
                    enable: !state.isDisableButton,
                    color: UIColors.blue,
                    titleWidget: AppText.semiBold(
                      'Tiếp tục',
                      fontSize: 16,
                      color: UIColors.white,
                    ),
                  ),
                  context.paddingBottomForButton.gap,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
