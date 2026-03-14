import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';

class CachedImageWidget extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String firstName;
  final String lastName;
  final Color? color;
  final String? placeHolderImage;
  final AlignmentGeometry? alignment;
  final bool usePlaceholderIfUrlEmpty;
  final bool circle;
  final double? radius;
  final int bottomLeftRadius;
  final int bottomRightRadius;
  final int topLeftRadius;
  final int topRightRadius;
  final bool enableCompression;
  final int compressionWidth;

  const CachedImageWidget({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit,
    this.firstName = "",
    this.lastName = "",
    this.color,
    this.placeHolderImage,
    this.alignment,
    this.usePlaceholderIfUrlEmpty = true,
    this.circle = false,
    this.radius,
    this.bottomLeftRadius = 0,
    this.bottomRightRadius = 0,
    this.topLeftRadius = 0,
    this.topRightRadius = 0,
    this.enableCompression = true,
    this.compressionWidth = 512,
  });

  double scaleForTV(BuildContext context, double value) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 1280 ? value * 1.5 : value;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final scaledHeight = scaleForTV(context, height ?? 100);
    final scaledWidth = scaleForTV(context, width ?? 100);
    final initials = "${firstName.firstLetter.toUpperCase()}${lastName.firstLetter.toUpperCase()}";

    return PlaceHolderWidget(
      height: scaledHeight,
      width: scaledWidth,
      alignment: alignment ?? Alignment.center,
      child: circle
          ? Text(
              initials,
              style: primaryTextStyle(size: (scaledHeight * 0.3).toInt(), decoration: TextDecoration.none),
            )
          : null,
    )
        .cornerRadiusWithClipRRectOnly(
          topLeft: topLeftRadius,
          topRight: topRightRadius,
          bottomLeft: bottomLeftRadius,
          bottomRight: bottomRightRadius,
        )
        .cornerRadiusWithClipRRect(radius ?? (circle ? (scaledHeight / 2) : 0));
  }

  @override
  Widget build(BuildContext context) {
    final scaledHeight = scaleForTV(context, height ?? 100);
    final scaledWidth = scaleForTV(context, width ?? 100);
    if (url.validate().isEmpty) {
      return _buildPlaceholder(context);
    } else if (url.validate().startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        height: scaledHeight,
        width: scaledWidth,
        fit: fit,
        color: color,
        alignment: alignment as Alignment? ?? Alignment.center,
        placeholder: (_, __) => _buildPlaceholder(context).visible(usePlaceholderIfUrlEmpty),
        errorWidget: (_, __, ___) => _buildPlaceholder(context),
        imageBuilder: (context, imageProvider) {
          return Image(
            image:
                enableCompression ? ResizeImage.resizeIfNeeded(compressionWidth, null, imageProvider) : imageProvider,
            height: scaledHeight,
            width: scaledWidth,
            fit: fit,
            color: color,
            alignment: alignment ?? Alignment.center,
          );
        },
      )
          .cornerRadiusWithClipRRectOnly(
            topLeft: topLeftRadius,
            topRight: topRightRadius,
            bottomLeft: bottomLeftRadius,
            bottomRight: bottomRightRadius,
          )
          .cornerRadiusWithClipRRect(radius ?? (circle ? (scaledHeight / 2) : 0));
    } else if (url.startsWith("assets/")) {
      return Image.asset(
        url,
        height: scaledHeight,
        width: scaledWidth,
        fit: fit,
        color: color,
        alignment: alignment ?? Alignment.center,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      ).cornerRadiusWithClipRRect(radius ?? (circle ? (scaledHeight / 2) : 0));
    } else {
      if (kIsWeb) {
        return _buildPlaceholder(context);
      }
      return Image.file(
        File(url),
        height: scaledHeight,
        width: scaledWidth,
        fit: fit,
        color: color,
        alignment: alignment ?? Alignment.center,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      ).cornerRadiusWithClipRRect(radius ?? (circle ? (scaledHeight / 2) : 0));
    }
  }
}
