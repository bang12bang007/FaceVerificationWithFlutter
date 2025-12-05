import 'package:flutter/material.dart';
import 'package:thesis/common/extentions/contenxt_x.dart';
import 'package:thesis/common/extentions/num_x.dart';

import '../../common/contranst/colors.dart';
import '../../shared/widgets/button.dart';



showAppBottomSheet(
    BuildContext context, {
      required Widget child,
    }) {
  showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext childContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xff0f0f0f),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              8.gap,
              Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: UIColors.text.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              16.gap,
              child,
              16.gap,
              context.bottomPadding.gap,
            ],
          ),
        );
      });
}

showAppFullScreenBottomSheet(
    BuildContext context, {
      required Widget child,
    }) {
  showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (BuildContext childContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 1,
          minChildSize: 0.5,
          expand: true,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                color: UIColors.bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  8.gap,
                  Container(
                    width: 32,
                    height: 2,
                    decoration: BoxDecoration(
                      color: UIColors.text.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  16.gap,
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            );
          },
        );
      });
}

showAppBottomSheetWithoutHeader(
    BuildContext context, {
      required Widget child,
    }) {
  showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext childContext) {
        return Column(
          children: [
            Expanded(
              child: AppButton.widget(
                child: Container(),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 0,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: UIColors.gray,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row(
                  //   children: [
                  //     8.gap,
                  //     Expanded(
                  //       child: AppText.semiBold(
                  //         title,
                  //         fontSize: 18,
                  //         maxLines: 2,
                  //       ),
                  //     ),
                  //     16.gap,
                  //     AppButton.widget(
                  //       child: Container(
                  //         width: 28,
                  //         height: 28,
                  //         decoration: BoxDecoration(
                  //           color: UIColors.text.withOpacity(0.1),
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         alignment: Alignment.center,
                  //         child: Assets.svg.watchList.icX.svg(),
                  //       ),
                  //       onTap: () {
                  //         Navigator.pop(context);
                  //       },
                  //     ),
                  //     8.gap,
                  //   ],
                  // ),
                  child,
                  context.bottomPadding.gap,
                ],
              ),
            ),
          ],
        );
      });
}
