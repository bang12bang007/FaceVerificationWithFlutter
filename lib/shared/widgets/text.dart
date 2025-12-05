import 'package:flutter/material.dart';


import '../../../../generated/fonts.gen.dart';
import '../../common/contranst/colors.dart';


class AppText extends Text {
  AppText.light(
      String text, {
        Key? key,
        double? fontSize = 14,
        Color? color,
        FontWeight? fontWeight = FontWeight.w300,
        int? maxLines,
        TextAlign? textAlign,
        TextOverflow? textOverflow = TextOverflow.ellipsis,
        TextDecoration? decoration,
      }) : super(
    text,
    style: TextStyle(
      color: color ?? UIColors.text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
    ),
    maxLines: maxLines,
    key: key,
    textAlign: textAlign,
    overflow: textOverflow,
  );

  AppText.regular(
      String text, {
        Key? key,
        double? fontSize = 14,
        Color? color,
        FontWeight? fontWeight = FontWeight.w400,
        int? maxLines,
        TextAlign? textAlign,
        TextOverflow? textOverflow = TextOverflow.ellipsis,
        TextDecoration? decoration,
        double? height,
      }) : super(
    text,
    style: TextStyle(
      color: color ?? UIColors.text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      height: height,
      fontFamily: FontFamily.openSans,
    ),
    maxLines: maxLines,
    key: key,
    textAlign: textAlign,
    overflow: textOverflow,
  );

  AppText.medium(
      String text, {
        Key? key,
        double? fontSize = 14,
        Color? color,
        FontWeight? fontWeight = FontWeight.w500,
        int? maxLines,
        TextAlign? textAlign,
        TextOverflow? textOverflow = TextOverflow.ellipsis,
        Map<String, String>? namedArgs,
        TextDecoration? decoration,
        double? height,
      }) : super(
    text,
    style: TextStyle(
      color: color ?? UIColors.text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      height: height,
      fontFamily: FontFamily.openSans,
    ),
    maxLines: maxLines,
    key: key,
    textAlign: textAlign,
    overflow: textOverflow,
  );

  AppText.semiBold(
      String text, {
        Key? key,
        double? fontSize = 14,
        Color? color,
        FontWeight? fontWeight = FontWeight.w600,
        int? maxLines,
        TextAlign? textAlign,
        TextOverflow? textOverflow = TextOverflow.ellipsis,
        Map<String, String>? namedArgs,
        TextDecoration? decoration,
        double? height,
      }) : super(
    text,
    style: TextStyle(
      color: color ?? UIColors.text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      decorationColor: color ?? UIColors.text,
      decorationThickness: 0.5,
      height: height,
      fontFamily: FontFamily.openSans,
    ),
    maxLines: maxLines,
    key: key,
    textAlign: textAlign,
    overflow: textOverflow,
  );

  AppText.bold(
      String text, {
        Key? key,
        double? fontSize = 14,
        Color? color,
        FontWeight? fontWeight = FontWeight.w700,
        int? maxLines,
        TextOverflow? textOverflow = TextOverflow.ellipsis,
        TextAlign? textAlign,
        TextDecoration? decoration,
        double? height,
      }) : super(
    text,
    style: TextStyle(
      color: color ?? UIColors.text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      height: height,
      fontFamily: FontFamily.openSans,
    ),
    maxLines: maxLines,
    textAlign: textAlign,
    key: key,
    overflow: textOverflow,
  );
}
