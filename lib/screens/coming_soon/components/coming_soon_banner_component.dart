import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/coming_soon/model/coming_soon_response.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/utils/focusable_read_more_text.dart';
import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../coming_soon_controller.dart';

class ComingSoonBannerComponent extends StatelessWidget {
  final ComingSoonModel comingSoonDet;
  final ComingSoonController comingSoonCont;

  const ComingSoonBannerComponent({
    super.key,
    required this.comingSoonDet,
    required this.comingSoonCont,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      comingSoonCont.startTimer(comingSoonDet.releaseDate);
    });

    return Container(
      width: Get.width,
      decoration: boxDecorationDefault(
        borderRadius: BorderRadius.circular(12),
        color: canvasColor,
      ),
      clipBehavior: Clip.none,
      child: Stack(
        children: [
          // Background Image - Extended upward
          Positioned(
            left: 120,
            top: -50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedImageWidget(
                fit: BoxFit.cover,
                url: comingSoonDet.thumbnailImage,
                width: Get.width,
                height: 300,
              ),
            ),
          ),

          // Dark Overlay - Extended upward for tab bar area
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.15, 0.4, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Additional overlay for horizontal gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.7, 0.8],
                ),
              ),
            ),
          ),

          // Content
          Container(
            width: Get.width * 0.5,
            padding: const EdgeInsets.only(left: 24, top: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  comingSoonDet.name.validate(),
                  style: commonW500PrimaryTextStyle(
                    size: 22,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                8.height,

                // Description
                if (comingSoonDet.description.isNotEmpty)
                  FocusableReadMoreText(
                    parseHtmlString(comingSoonDet.description), 
                    focusNode: comingSoonCont.descriptionFocusNode, 
                    style: commonSecondaryTextStyle(color: descriptionTextColor),
                    trimExpandedText: locale.value.readLess.prefixText(value: ' '),
                    trimCollapsedText: locale.value.readMore,
                    onKeyEvent: comingSoonCont.handleDescriptionKeyEvent,
                  ),

                8.height,
                Row(
                  children: [
                    // Genres
                    if (comingSoonDet.genres.validate().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          comingSoonDet.genres.take(3).map((genre) => genre.name).join(' • '),
                          style: commonSecondaryTextStyle(
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                    if (comingSoonDet.releaseDate.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 12),
                          4.width,
                          Text(
                            formatReleaseDate(comingSoonDet.releaseDate),
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                  ],
                ),

                12.height,

                // Countdown Timer
                Obx(() {
                  if (comingSoonCont.timeRemaining.value > Duration.zero) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            _buildCountdownItem(
                              comingSoonCont.timeRemaining.value.inDays.toString(),
                              locale.value.days.toUpperCase(),
                            ),
                            8.width,
                            _buildCountdownItem(
                              comingSoonCont.timeRemaining.value.inHours.remainder(24).toString().padLeft(2, '0'),
                              locale.value.hour.toUpperCase(),
                            ),
                            8.width,
                            _buildCountdownItem(
                              comingSoonCont.timeRemaining.value.inMinutes.remainder(60).toString().padLeft(2, '0'),
                              locale.value.minute.toUpperCase(),
                            ),
                            8.width,
                            _buildCountdownItem(
                              comingSoonCont.timeRemaining.value.inSeconds.remainder(60).toString().padLeft(2, '0'),
                              locale.value.sec.toUpperCase(),
                            ),
                          ],
                        ),
                        12.height,
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Watch Trailer Button
                Focus(
                  focusNode: comingSoonCont.trailerButtonFocusNode,
                  onFocusChange: (hasFocus) {
                    comingSoonCont.isTrailerButtonFocused.value = hasFocus;
                  },
                  child: Obx(() {
                    final isFocused = comingSoonCont.isTrailerButtonFocused.value;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isFocused ? Colors.white : appColorPrimary,
                        border: isFocused ? Border.all(color: appColorPrimary, width: 2) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: isFocused ? appColorPrimary : Colors.white,
                            size: 16,
                          ),
                          6.width,
                          Text(
                            locale.value.trailer,
                            style: TextStyle(
                              fontSize: 12,
                              color: isFocused ? appColorPrimary : Colors.white,
                              fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: commonW500PrimaryTextStyle(
            size: 18,
            color: Colors.white,
          ),
        ),
        4.height,
        Text(
          label.toUpperCase(),
          style: commonSecondaryTextStyle(
            size: 10,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
