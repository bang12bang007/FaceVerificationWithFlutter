import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:thesis/common/extentions/color_x.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/common/extentions/router_x.dart';

import '../../../../generated/assets.gen.dart';
import '../../common/contranst/colors.dart';
import '../router/router_key.dart';
import 'button.dart';
import 'text.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.rightBtns,
    this.leftBtn,
    this.onBack,
  });

  final String title;
  final Widget? leftBtn;
  final List<Widget>? rightBtns;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(color: UIColors.black),
      child: Row(
        children: [
          (leftBtn != null)
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: leftBtn!,
                )
              : AppButton.widget(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Assets.svg.icBack.svg(
                      colorFilter: UIColors.white.filter,
                    ),
                  ),
                  onTap: () {
                    if (onBack != null) {
                      onBack!();
                    } else {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.replaceWithPath(RouterPath.home);
                      }
                    }
                  },
                ),
          Expanded(
            child: AppText.bold(
              title.isEmpty ? ' ' : title,
              fontSize: 16,
              color: UIColors.white,
              textAlign: TextAlign.center,
            ),
          ),
          (rightBtns != null)
              ? SizedBox(
                  height: 24,
                  child: ListView.separated(
                    shrinkWrap: true,
                    primary: false,
                    padding: const EdgeInsets.only(right: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return rightBtns![index];
                    },
                    separatorBuilder: (context, index) {
                      return 16.gap;
                    },
                    itemCount: rightBtns!.length,
                  ),
                )
              : 60.gap,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(46);
}
