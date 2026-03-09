import 'package:flutter/material.dart';

// ignore: avoid_classes_with_only_static_members
/// A centralized utility class for responsive sizing, spacing, and typography.
///
/// Use this class to maintain consistency across all screen sizes by
/// calculating sizes relative to the screen dimensions.
class CommonResponsiveUtilities {
  /// ---------- 📱 Base Ratio Constants ----------
  static const baseWidth = 3840;
  static const subTitleRatio = 60 / baseWidth;
  static const sectionHeaderFontSize = 90 / baseWidth;
  static const sectionSpace = 50 / baseWidth;
  static const counterSize = 50 / baseWidth;

  static const subTitleSize = 85 / baseWidth;
  static const sectionHeaderSize = 128 / baseWidth;

  static const double channelImageWidthRatio = 964 / baseWidth;
  static const double channelImageHeightRatio = 516 / baseWidth;
  static const double channelSectionHeightRatio = 708 / baseWidth;
  static const double channelSpacingRatio = 50 / baseWidth;
  static const double channelSectionWithTimerHeightRatio = 884 / baseWidth;
  static const double specialSectionHeight = 600 / baseWidth;

  static const double channelRadius = 20 / baseWidth;
  static const double imageTextSpacingRatio = 16 / baseWidth; // Spacing between image and text

  static const double specialGroupSectionHeightRatio = 350 / 926;
  static const double movieImageHeightRatio = 884 / baseWidth;
  static const double movieImageWidthRatio = 644 / baseWidth;
  static const double movieSectionHeightRatio = 1076 / baseWidth;
  static const double movieSpacingRatio = 8 / baseWidth;
  static const double movieRadius = 20 / baseWidth;

  static const double timerFontRatio = 8 / 1000;
  static const backButtonSizeRatio = 40 / 960;
  static const backButtonFontSizeRatio = 16 / 960;
  static const backButtonPaddingHorizontalRatio = 12 / 960;
  static const backButtonPaddingVerticalRatio = 8 / 960;

  static const mainMenuCardWidthRatio = 1520 / baseWidth;
  static const mainMenuCardHeightRatio = 855 / baseWidth;
  static const mainMenuCardWidthRatioFocused = 2080 / baseWidth;
  static const mainMenuCardHeightRatioFocused = 1170 / baseWidth;
  static const mainMenuSectionHeightWithFocusRatio = 1270 / baseWidth;
  static const mainMenuSectionHeightRatio = 955 / baseWidth;

  static const leftPaddingRatio = 200 / 960;

  static const searchTextFontSizeRatio = 16 / 960;

  static const searchBarWidthRatio = 400 / 960;
  static const searchBarHeightRatio = 400 / 960;

  static const appBarHeightRatio = 960 / 960;

  static const logoWidthRatio = 120 / 960;
  static const logoHeightRatio = 59 / 960;

  static const profileButtonWidthRatio = 40 / 960;
  static const profileButtonHeightRatio = 40 / 960;

  static const movieSectionWithTimerHeight = 1204;

  /// ---------- 📏 Screen Dimensions ----------
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  /// ---------- 🔹 Responsive Computations ----------
  static double width(BuildContext context, double ratio) => screenWidth(context) * ratio;

  static double height(BuildContext context, double ratio) => screenWidth(context) * ratio;

  static double fontSize(BuildContext context, double ratio) => screenWidth(context) * ratio;

  static double ratio(BuildContext context, double ratio) => screenWidth(context) * ratio;

  /// ---------- 🧩 Responsive Paddings ----------
  static EdgeInsets paddingAll(BuildContext context, double ratio) {
    final value = screenWidth(context) * ratio;
    return EdgeInsets.all(value);
  }

  static EdgeInsets paddingSymmetric(BuildContext context, {double horizontalRatio = 0, double verticalRatio = 0}) {
    return EdgeInsets.symmetric(horizontal: screenWidth(context) * horizontalRatio, vertical: screenWidth(context) * verticalRatio);
  }

  /// ---------- 🟪 Border Radius ----------
  static BorderRadius radius(BuildContext context, double ratio) => BorderRadius.circular(screenWidth(context) * ratio);

  /// ---------- 🎬 Common Component Dimensions ----------
  static double subTitleFontSize(BuildContext context) => fontSize(context, subTitleRatio);

  static double sectionHeaderFont(BuildContext context) => fontSize(context, sectionHeaderFontSize);

  static double sectionSpacing(BuildContext context) => height(context, sectionSpace);

  static double headerSectionSize(BuildContext context) => fontSize(context, sectionHeaderSize);

  static double subSectionSize(BuildContext context) => fontSize(context, subTitleSize);

  static double counterFontSize(BuildContext context) => width(context, counterSize);

  static double channelImageWidth(BuildContext context) => width(context, channelImageWidthRatio);

  static double channelImageHeight(BuildContext context) => height(context, channelImageHeightRatio);
  static double specialGroupHeight(BuildContext context) => height(context, specialSectionHeight);

  static double channelSectionHeight(BuildContext context) => height(context, channelSectionHeightRatio);

  static double channelSpacing(BuildContext context) => height(context, channelSpacingRatio);

  static double channelSectionWithTimerHeight(BuildContext context) => height(context, channelSectionWithTimerHeightRatio);

  static double mainMenuSectionHeightWithFocus(BuildContext context) => height(context, mainMenuSectionHeightWithFocusRatio);
  static double mainMenuSectionHeight(BuildContext context) => height(context, mainMenuSectionHeightRatio);
  static double specialGroupSectionHeight(BuildContext context) => height(context, specialGroupSectionHeightRatio);

  static double movieImageHeight(BuildContext context) => height(context, movieImageHeightRatio);

  static double movieImageWidth(BuildContext context) => width(context, movieImageWidthRatio);

  static double movieSectionHeight(BuildContext context) => height(context, movieSectionHeightRatio);

  static double movieSpacing(BuildContext context) => height(context, movieSpacingRatio);

  static double timerFontSize(BuildContext context) => fontSize(context, timerFontRatio);

  static double backButtonSize(BuildContext context) => width(context, backButtonSizeRatio);

  static double backButtonFontSize(BuildContext context) => fontSize(context, backButtonFontSizeRatio);

  static double backButtonPaddingHorizontal(BuildContext context) => width(context, backButtonPaddingHorizontalRatio);

  static double backButtonPaddingVertical(BuildContext context) => height(context, backButtonPaddingVerticalRatio);

  static double mainMenuCardWidth(BuildContext context) => width(context, mainMenuCardWidthRatio);

  static double mainMenuCardHeight(BuildContext context) => height(context, mainMenuCardHeightRatio);

  static double mainMenuCardWidthFocused(BuildContext context) => width(context, mainMenuCardWidthRatioFocused);

  static double mainMenuCardHeightFocused(BuildContext context) => height(context, mainMenuCardHeightRatioFocused);

  static double leftPadding(BuildContext context) => width(context, leftPaddingRatio);

  static double searchTextFontSize(BuildContext context) => fontSize(context, searchTextFontSizeRatio);

  static double searchBarWidth(BuildContext context) => width(context, searchBarWidthRatio);

  static double searchBarHeight(BuildContext context) => height(context, searchBarHeightRatio);

  static double appBarHeight(BuildContext context) => height(context, appBarHeightRatio);

  static double logoWidth(BuildContext context) => width(context, logoWidthRatio);

  static double logoHeight(BuildContext context) => height(context, logoHeightRatio);

  static double profileButtonWidth(BuildContext context) => width(context, profileButtonWidthRatio);

  static double profileButtonHeight(BuildContext context) => height(context, profileButtonHeightRatio);

  static BorderRadius channelImageHeightRadius(BuildContext context) => radius(context, channelRadius);

  static double imageTextSpacing(BuildContext context) => height(context, imageTextSpacingRatio);
}
