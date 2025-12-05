import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:thesis/common/extentions/num_x.dart';

import '../../common/contranst/colors.dart';
import '../../shared/widgets/button.dart';
import '../../shared/widgets/text.dart';
import 'dividend.dart';
import 'package:thesis/shared/router/router_key.dart';

Future<void> showAppDialog(
  BuildContext context, {
  required Widget child,
  double? horizontalMargin,
}) async {
  await showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Scaffold(
        backgroundColor: UIColors.black.withOpacity(0.7),
        body: AppButton.widget(
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 32),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: UIColors.bg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: UIColors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: UIColors.lightGray.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      );
    },
  );
}

class AppDialog extends Column {
  AppDialog.simple({
    super.key,
    required String title,
    required String content,
    required String btnTitle,
    VoidCallback? onTap,
    Color? btnColor,
  }) : super(
         mainAxisSize: MainAxisSize.min,
         children: [
           Padding(
             padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
             child: Column(
               children: [
                 _DialogTitle(title: title),
                 20.gap,
                 _DialogContent(content: content),
               ],
             ),
           ),
           Container(height: 1, color: UIColors.lightGray.withOpacity(0.15)),
           DialogButton(
             title: btnTitle,
             onTap: () {
               if (onTap != null) {
                 onTap();
               } else {
                 GlobalKeyManager.instance.root.currentState?.pop();
               }
             },
             color: btnColor ?? UIColors.redLight,
           ),
         ],
       );

  AppDialog.common({
    super.key,
    required String title,
    required String content,
    String? leftBtnTitle,
    VoidCallback? onTapLeftBtn,
    Color? leftBtnColor,
    required String rightBtnTitle,
    required VoidCallback onTapRightBtn,
    Color? rightBtnColor,
  }) : super(
         mainAxisSize: MainAxisSize.min,
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
             child: Column(
               children: [
                 _DialogTitle(title: title),
                 16.gap,
                 _DialogContent(content: content),
               ],
             ),
           ),
           AppDivider(color: UIColors.text.withOpacity(0.2)),
           Row(
             children: [
               Expanded(
                 child: DialogButton(
                   title: leftBtnTitle ?? 'Huỷ',
                   onTap: () {
                     if (onTapLeftBtn != null) {
                       onTapLeftBtn();
                     } else {
                       GlobalKeyManager.instance.root.currentState?.pop();
                     }
                   },
                   color: leftBtnColor ?? UIColors.green,
                   fontWeight: FontWeight.normal,
                 ),
               ),
               Container(
                 height: 52,
                 width: 0.5,
                 color: UIColors.text.withOpacity(0.2),
               ),
               Expanded(
                 child: DialogButton(
                   title: rightBtnTitle,
                   onTap: () {
                     GlobalKeyManager.instance.root.currentState?.pop();
                     onTapRightBtn();
                   },
                   color: rightBtnColor ?? UIColors.green,
                 ),
               ),
             ],
           ),
         ],
       );

  AppDialog.multi({
    super.key,
    required String title,
    required String content,
    required List<DialogButton> btns,
  }) : super(
         mainAxisSize: MainAxisSize.min,
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
             child: Column(
               children: [
                 _DialogTitle(title: title),
                 16.gap,
                 _DialogContent(content: content),
               ],
             ),
           ),
           AppDivider(color: UIColors.text.withOpacity(0.2)),
           ListView.separated(
             shrinkWrap: true,
             primary: false,
             physics: const NeverScrollableScrollPhysics(),
             itemBuilder: (context, index) {
               return btns[index];
             },
             separatorBuilder: (context, state) {
               return AppDivider(color: UIColors.text.withOpacity(0.2));
             },
             itemCount: btns.length,
           ),
           AppDivider(color: UIColors.text.withOpacity(0.2)),
           DialogButton(
             title: 'Huỷ',
             onTap: () {
               GlobalKeyManager.instance.root.currentState?.pop();
             },
             color: UIColors.text.withOpacity(0.5),
           ),
         ],
       );

  AppDialog.complex({
    super.key,
    required String title,
    required Widget child,
    String? leftBtnTitle,
    VoidCallback? onTapLeftBtn,
    Color? leftBtnColor,
    required String rightBtnTitle,
    required VoidCallback onTapRightBtn,
    Color? rightBtnColor,
  }) : super(
         mainAxisSize: MainAxisSize.min,
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
             child: Column(
               children: [
                 _DialogTitle(title: title),
                 16.gap,
                 child,
               ],
             ),
           ),
           AppDivider(color: UIColors.text.withOpacity(0.2)),
           Row(
             children: [
               Expanded(
                 child: DialogButton(
                   title: leftBtnTitle ?? 'Huỷ',
                   onTap: () {
                     if (onTapLeftBtn != null) {
                       onTapLeftBtn();
                     } else {
                       GlobalKeyManager.instance.root.currentState?.pop();
                     }
                   },
                   color: leftBtnColor ?? UIColors.text,
                 ),
               ),
               Container(
                 height: 52,
                 width: 0.5,
                 color: UIColors.text.withOpacity(0.2),
               ),
               Expanded(
                 child: DialogButton(
                   title: rightBtnTitle,
                   onTap: () {
                     onTapRightBtn();
                   },
                   color: rightBtnColor ?? UIColors.green,
                 ),
               ),
             ],
           ),
         ],
       );
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppText.semiBold(
      title,
      fontSize: 18,
      color: UIColors.white,
      maxLines: 2,
      textAlign: TextAlign.center,
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return AppText.regular(
      content,
      fontSize: 15,
      color: UIColors.lightGray,
      maxLines: 10,
      textAlign: TextAlign.center,
      height: 1.4,
    );
  }
}

class DialogButton extends StatelessWidget {
  const DialogButton({
    super.key,
    required this.title,
    required this.onTap,
    required this.color,
    this.fontWeight,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return AppButton.widget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        child: AppText.semiBold(
          title,
          fontSize: 16,
          color: color,
          textAlign: TextAlign.center,
          fontWeight: fontWeight ?? FontWeight.w600,
        ),
      ),
    );
  }
}
