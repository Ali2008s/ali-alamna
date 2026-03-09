import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/colors.dart';
import 'cached_image_widget.dart';

class CustomIconButton extends StatelessWidget {
  final bool isTrue;
  final String icon;
  final String checkIcon;
  final Color? color;
  final Function() onTap;
  final double iconHeight;
  final double iconWidth;
  final EdgeInsets? padding;
  final Color? buttonColor;
  final double buttonHeight;
  final double buttonWidth;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isTrue = false,
    this.checkIcon = "",
    this.color,
    this.iconHeight = 18,
    this.iconWidth = 18,
    this.padding,
    this.buttonColor,
    this.buttonWidth = 18,
    this.buttonHeight = 18,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      onTap: onTap,
      splashColor: Colors.transparent,
      color: isTrue ? appColorPrimary : buttonColor ?? circleColor,
      padding: padding ?? const EdgeInsets.all(12),
      height: buttonHeight,
      width: buttonWidth,
      shapeBorder: RoundedRectangleBorder(borderRadius: radius(25)),
      child: CachedImageWidget(
        url: isTrue
            ? checkIcon.isNotEmpty
                ? checkIcon
                : icon
            : icon,
        height: iconHeight,
        width: iconWidth,
        color: isTrue ? white : iconColor,
      ),
    );
  }
}
