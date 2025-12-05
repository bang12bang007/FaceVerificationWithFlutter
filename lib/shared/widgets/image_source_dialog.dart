import 'package:flutter/material.dart';
import 'package:thesis/common/contranst/colors.dart';
import 'package:thesis/common/extentions/num_x.dart';
import 'package:thesis/shared/widgets/button.dart';
import 'package:thesis/shared/widgets/text.dart';

class ImageSourceDialog extends StatelessWidget {
  const ImageSourceDialog({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    this.onBarcodeTap,
  });

  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback? onBarcodeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              AppText.semiBold(
                'Chọn nguồn ảnh',
                fontSize: 18,
                color: UIColors.white,
                textAlign: TextAlign.center,
              ),
              16.gap,
              AppText.regular(
                'Vui lòng chọn cách bạn muốn chụp ảnh, chọn từ thư viện hoặc quét mã vạch thẻ sinh viên',
                fontSize: 15,
                color: UIColors.lightGray,
                textAlign: TextAlign.center,
                height: 1.4,
              ),
            ],
          ),
        ),
        Container(height: 1, color: UIColors.lightGray.withValues(alpha: 0.15)),
        ImageSourceButton(
          icon: Icons.camera_alt,
          title: 'Chụp ảnh',
          subtitle: 'Sử dụng camera để chụp ảnh thẻ sinh viên',
          onTap: () {
            Navigator.pop(context);
            onCameraTap();
          },
        ),
        Container(height: 1, color: UIColors.lightGray.withValues(alpha: 0.15)),
        ImageSourceButton(
          icon: Icons.photo_library,
          title: 'Chọn từ thư viện',
          subtitle: 'Chọn ảnh thẻ sinh viên từ thư viện ảnh',
          onTap: () {
            Navigator.pop(context);
            onGalleryTap();
          },
        ),
        Container(height: 1, color: UIColors.lightGray.withValues(alpha: 0.15)),
        if (onBarcodeTap != null)
          ImageSourceButton(
            icon: Icons.qr_code_scanner,
            title: 'Quét mã vạch',
            subtitle: 'Quét mã vạch trên thẻ sinh viên',
            onTap: () {
              Navigator.pop(context);
              onBarcodeTap!();
            },
          ),
        Container(height: 1, color: UIColors.lightGray.withValues(alpha: 0.15)),
        DialogButton(
          title: 'Huỷ',
          onTap: () {
            Navigator.pop(context);
          },
          color: UIColors.text.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class ImageSourceButton extends StatelessWidget {
  const ImageSourceButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppButton.widget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: UIColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: UIColors.green, size: 24),
            ),
            16.gap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.semiBold(title, fontSize: 16, color: UIColors.white),
                  4.gap,
                  AppText.regular(
                    subtitle,
                    fontSize: 14,
                    color: UIColors.lightGray,
                    height: 1.3,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: UIColors.lightGray, size: 16),
          ],
        ),
      ),
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
