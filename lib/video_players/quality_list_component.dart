import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/video_players/video_player_controller.dart';

import '../components/app_scaffold.dart';
import '../main.dart';
import '../screens/content/model/content_model.dart';
import '../utils/app_common.dart';
import '../utils/constants.dart';

class QualityListComponent extends StatelessWidget {
  final VideoPlayersController controller;

  const QualityListComponent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isLoading: false.obs,
      scaffoldBackgroundColor: Colors.transparent,
      hasLeadingWidget: false,
      appBartitleText: locale.value.quality,
      appBarbackgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),
          16.height,
          Obx(() {
            final supportedQualities = controller.videoQualities
                .asMap()
                .entries
                .where((entry) => checkQualitySupported(
                    quality: entry.value.quality,
                    requirePlanLevel: controller.videoModel.value.details.requiredPlanLevel))
                .toList();

            return SizedBox(
              height: 300,
              child: ListView.builder(
                physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: supportedQualities.length,
                padding: EdgeInsets.zero,
                cacheExtent: 200,
                itemBuilder: (_, listIndex) {
                  final entry = supportedQualities[listIndex];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Obx(
                      () => QualityItem(
                        key: ValueKey('quality_${entry.key}'),
                        data: entry.value,
                        index: entry.key,
                        controller: controller,
                        isSelectedQuality:
                            entry.value.quality.toLowerCase() == controller.currentQuality.value.toLowerCase(),
                        isFocused: controller.focusedQualityIndex.value == entry.key,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class QualityItem extends StatelessWidget {
  QualityItem({
    super.key,
    required this.data,
    required this.index,
    required this.isSelectedQuality,
    required this.isFocused,
    required this.controller,
  });

  final VideoData data;
  final int index;
  final RxBool hasFocus = false.obs;
  final bool isSelectedQuality;
  final bool isFocused;
  final VideoPlayersController controller;

  void _scrollToItem(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
      } catch (e) {
        // Ignore if scroll fails
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (isFocused && !hasFocus.value) {
          hasFocus(true);
          _scrollToItem(context);
        } else if (!isFocused && hasFocus.value) {
          hasFocus(false);
        }

        return Focus(
          onFocusChange: (value) {
            hasFocus(value);
            if (value) {
              controller.focusedQualityIndex(index);
              _scrollToItem(context);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: transparentColor,
              borderRadius: radius(4),
              border: hasFocus.value ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: SettingItemWidget(
              title: _getQualityDisplayText(data.quality),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              titleTextStyle: primaryTextStyle(),
              trailing: isSelectedQuality
                  ? Container(
                      padding: EdgeInsets.all(4),
                      decoration: boxDecorationDefault(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 15, color: appColorPrimary),
                    )
                  : null,
              splashColor: transparentColor,
              borderRadius: 8,
              hoverColor: transparentColor,
              highlightColor: transparentColor,
            ),
          ),
        );
      },
    );
  }

  String _getQualityDisplayText(String quality) {
    if (quality.isEmpty || quality.toLowerCase() == QualityConstants.defaultQuality.toLowerCase()) {
      return 'Default';
    }
    return quality.capitalizeEachWord();
  }
}
