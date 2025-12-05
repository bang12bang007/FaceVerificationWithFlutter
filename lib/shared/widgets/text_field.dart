import 'package:flutter/material.dart';
import 'package:thesis/common/contranst/colors.dart';

import '../../../../generated/assets.gen.dart';
import '../../../../generated/fonts.gen.dart';
import 'button.dart';
import 'text.dart';

class AppTF extends Column {
  AppTF.common({
    super.key,
    required TextEditingController controller,
    String? label,
    String? hintText,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    bool showInfo = false,
    VoidCallback? onTapInfo,
    bool autofocus = false,
    FocusNode? focusNode,
    Widget? rightWidget,
  }) : super(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Container(
             height: 46,
             padding: const EdgeInsets.symmetric(horizontal: 16),
             decoration: BoxDecoration(
               color: UIColors.border,
               borderRadius: BorderRadius.circular(12),
             ),
             alignment: Alignment.centerLeft,
             child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     cursorWidth: 1,
                     autofocus: autofocus,
                     cursorHeight: 20,
                     cursorColor: UIColors.text,
                     controller: controller,
                     focusNode: focusNode,
                     keyboardAppearance: Brightness.dark,
                     decoration: InputDecoration(
                       contentPadding: const EdgeInsets.only(bottom: 2),
                       hintText: (hintText != null) ? hintText : null,
                       hintStyle: TextStyle(
                         color: UIColors.text.withOpacity(0.5),
                         fontSize: 14,
                       ),
                       border: InputBorder.none,
                     ),
                     autocorrect: false,
                     style: TextStyle(
                       color: UIColors.text,
                       fontWeight: FontWeight.w500,
                       fontSize: 14,
                     ),
                     textInputAction: TextInputAction.done,
                     keyboardType: keyboardType,
                     onChanged: onChanged,
                     onSubmitted: onSubmitted,
                   ),
                 ),
                 if (rightWidget != null)
                   Padding(
                     padding: const EdgeInsets.only(left: 16),
                     child: rightWidget,
                   ),
               ],
             ),
           ),
         ],
       );

  AppTF.disable({super.key, String? label, required String value})
    : super(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: UIColors.text.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: AppText.medium(value),
          ),
        ],
      );
}
