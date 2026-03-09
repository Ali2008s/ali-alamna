import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/cached_image_widget.dart';
import 'package:streamit_laravel/screens/tv_show/trailer_clip_video_player.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_detail_controller.dart';

class TrailersClipsItemComponent extends StatelessWidget {
  final dynamic item;
  final String title;
  final double width;
  final double height;
  final FocusNode focusNode;
  final TvShowPreviewController controller;

  TrailersClipsItemComponent({super.key, required this.item, required this.title, required this.width, required this.height, required this.focusNode, required this.controller});

  final RxBool isFocused = false.obs;
  final GlobalKey cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Focus(
        canRequestFocus: true,
        focusNode: focusNode,
        onFocusChange: (has) {
          isFocused(has);
          if (has) {
            try {
              final ctx = cardKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 150),
                  alignment: 0.5,
                );
              }
            } catch (_) {}
          }
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              controller.selectedOption('clips');
              controller.optionClipsFocus.requestFocus();
              return KeyEventResult.handled;
            }
          }
          if(event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            TrailerClipPlayerWidget(videoModel: item, aspectRatio: 16/9,onEnded: () {
              Get.back();
            }).launch(context);
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => AnimatedContainer(
                key: cardKey,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: radius(8),
                  border: isFocused.value ? Border.all(color: white, width: 2) : null,
                  boxShadow: isFocused.value ? [BoxShadow(color: white.withValues(alpha: 0.25), blurRadius: 8, spreadRadius: 1)] : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(borderRadius: radius(8), child: CachedImageWidget(url: item.posterImage, fit: BoxFit.cover)),
              ),
            ),
            8.height,
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: primaryTextStyle(color: white)),
          ],
        ),
      ),
    );
  }
}
