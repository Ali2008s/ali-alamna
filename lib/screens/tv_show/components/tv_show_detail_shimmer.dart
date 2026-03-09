import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/shimmer_widget.dart';
import '../../../utils/colors.dart';
import '../../../utils/shimmer/shimmer.dart';

class TvShowHeroBackdropShimmer extends StatelessWidget {
  const TvShowHeroBackdropShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Shimmer.fromColors(
        baseColor: shimmerPrimaryBaseColor,
        highlightColor: shimmerHighLightBaseColor,
        direction: ShimmerDirection.ttb,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF2A2A2A), const Color(0xFF121212), Colors.black.withValues(alpha: 0.9)],
            ),
          ),
        ),
      ),
    );
  }
}

class TvShowSynopsisShimmer extends StatelessWidget {
  const TvShowSynopsisShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = Get.width * 0.45;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 230, 50, 0),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget(height: 38, width: width * 0.8, radius: 6),
              12.height,
              ShimmerWidget(height: 20, width: width * 0.6, radius: 4),
              8.height,
              ShimmerWidget(height: 20, width: width * 0.35, radius: 4),
              16.height,
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ShimmerWidget(height: 16, width: width, radius: 4),
                ),
              ),
              24.height,
              ShimmerWidget(height: 56, width: width * 0.95, radius: 8),
              8.height,
            ],
          ),
        ),
      ),
    );
  }
}

class TvShowOptionsRowShimmer extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const TvShowOptionsRowShimmer({super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    Widget buildPill() => ShimmerWidget(height: 40, width: Get.width / 7.5, radius: 8);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          buildPill(),
          16.width,
          buildPill(),
          16.width,
          buildPill(),
        ],
      ),
    );
  }
}
