import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/coming_soon/model/coming_soon_response.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../coming_soon_controller.dart';

class ComingSoonVerticalCard extends StatelessWidget {
  final ComingSoonModel comingSoonDet;
  final ComingSoonController comingSoonCont;

  const ComingSoonVerticalCard({
    super.key,
    required this.comingSoonDet,
    required this.comingSoonCont,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        comingSoonCont.navigateToDetailScreen(comingSoonDet);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // width: 160,
        // height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedImageWidget(
                url: comingSoonDet.thumbnailImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Gradient overlay (always visible for better readability)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      comingSoonDet.name.validate(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    6.height,
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
                    4.height,
                    if (comingSoonDet.duration.isNotEmpty || comingSoonDet.seasonName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 12),
                          4.width,
                          Text(
                            comingSoonDet.duration.isNotEmpty ? comingSoonDet.duration : comingSoonDet.seasonName,
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Coming Soon Badge (always visible)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: appColorPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  locale.value.comingSoon.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
