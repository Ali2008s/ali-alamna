import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../utils/colors.dart';
import '../../../../services/focus_sound_service.dart';
import '../../../genres/genres_controller.dart';
import '../../../genres/model/genres_model.dart';

class GenresCard extends StatelessWidget {
  final GenreModel cardDet;
  final double? height;
  final double? width;
  final Function(bool)? onFocusChange;
  final int? index;
  final FocusNode? focusNode;
  final String? categoryName;
  final GlobalKey? categoryKey;
  final GenresController? controller;

  GenresCard({super.key, required this.cardDet, this.height, this.width, this.onFocusChange, this.index, this.focusNode, this.categoryName, this.categoryKey, this.controller});

  final RxBool isFocused = false.obs;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      focusNode: focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        return controller?.handleGenreCardKeyEvent(event, index ?? -1, categoryName ?? '', cardDet) ?? KeyEventResult.ignored;
      },
      onFocusChange: (value) {
        onFocusChange?.call(value);
        isFocused(value);
        if (value) {
          FocusSoundService.play();
        }
      },
      child: Obx(
        () => Container(
          decoration: boxDecorationDefault(
            borderRadius: radius(4),
            color: cardColor,
            border: isFocused.value ? Border.all(color: white, width: 3) : null,
          ),
          child: Stack(
            children: [
              CachedImageWidget(url: cardDet.poster, height: height ?? 120, width: width ?? 200, fit: BoxFit.cover, alignment: Alignment.topCenter),
              IgnorePointer(
                ignoring: true,
                child: Container(
                  height: height ?? 120,
                  width: width ?? 200,
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [black.withValues(alpha: 0.0), black.withValues(alpha: 0.0), black.withValues(alpha: 0.5), black.withValues(alpha: 0.9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 2,
                right: 2,
                child: Center(
                  child: Marquee(
                    child: Text(cardDet.name, textAlign: TextAlign.center, style: boldTextStyle(size: 12)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
