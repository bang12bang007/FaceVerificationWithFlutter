import 'package:flutter/material.dart';
import 'package:thesis/shared/widgets/text.dart';

import '../../common/contranst/colors.dart';

class AppButton extends ElevatedButton {
  AppButton.widget({
    super.key,
    required Widget super.child,
    required VoidCallback onTap,
    bool enable = true,
    Alignment alignment = Alignment.centerLeft,
  }) : super(
         onPressed: enable ? onTap : null,
         style: ButtonStyle(
           padding: MaterialStateProperty.all(EdgeInsets.zero),
           foregroundColor: MaterialStateProperty.all(
             Colors.white.withOpacity(0),
           ),
           backgroundColor: MaterialStateProperty.all(
             Colors.white.withOpacity(0),
           ),
           overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0)),
           elevation: MaterialStateProperty.all(0),
           minimumSize: MaterialStateProperty.all(Size.zero),
           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
           alignment: alignment,
         ),
       );

  AppButton.fill({
    super.key,
    required VoidCallback onTap,
    String? title,
    bool enable = true,
    EdgeInsets titlePadding = EdgeInsets.zero,
    double? width,
    Widget? titleWidget,
    bool hideKeyboardWhenClick = false,
    Color? color,
  }) : super(
         onPressed: () {
           if (hideKeyboardWhenClick) {
             FocusManager.instance.primaryFocus?.unfocus();
           }
           onTap();
         },
         style: ButtonStyle(
           padding: WidgetStateProperty.all(EdgeInsets.zero),
           shape: WidgetStateProperty.all<RoundedRectangleBorder>(
             RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           ),
           backgroundColor: WidgetStateProperty.all(
             enable
                 ? (color ?? UIColors.blue)
                 : UIColors.black.withOpacity(0.2),
           ),
           elevation: WidgetStateProperty.all(0),
           overlayColor: WidgetStateProperty.all(Colors.black.withOpacity(0.2)),
         ),
         child: Container(
           height: 45,
           width: width,
           padding: titlePadding,
           alignment: Alignment.center,
           decoration: BoxDecoration(
             color: enable
                 ? (color ?? UIColors.blue)
                 : UIColors.lightGray.withOpacity(0.2),
             borderRadius: BorderRadius.circular(8),
           ),
           child: FittedBox(
             fit: BoxFit.scaleDown,
             child:
                 titleWidget ??
                 AppText.semiBold(
                   title ?? '',
                   color: enable ? Colors.white : Colors.white.withOpacity(0.4),
                   fontSize: 12,
                 ),
           ),
         ),
       );

  AppButton.outline({
    super.key,
    required VoidCallback onTap,
    required String title,
    bool isYellow = false,
    bool enable = true,
    EdgeInsets titlePadding = EdgeInsets.zero,
  }) : super(
         onPressed: () => onTap(),
         style: ButtonStyle(
           padding: WidgetStateProperty.all(EdgeInsets.zero),
           shape: WidgetStateProperty.all<RoundedRectangleBorder>(
             RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           ),
           backgroundColor: WidgetStateProperty.all(Colors.transparent),
           elevation: WidgetStateProperty.all(0),
           overlayColor: WidgetStateProperty.all(
             UIColors.blue.withOpacity(0.4),
           ),
         ),
         child: Container(
           height: 46,
           alignment: Alignment.center,
           decoration: BoxDecoration(
             border: Border.all(color: UIColors.blue, width: 2),
             borderRadius: BorderRadius.circular(12),
           ),
           child: FittedBox(
             fit: BoxFit.scaleDown,
             child: Padding(
               padding: titlePadding,
               child: AppText.semiBold(
                 title,
                 fontSize: 14,
                 color: UIColors.blue,
               ),
             ),
           ),
         ),
       );
}
