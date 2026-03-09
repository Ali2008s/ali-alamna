import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/video_players/video_player_controller.dart';

import '../main.dart';

class SubtitleListComponent extends StatelessWidget {
  final VideoPlayersController controller;

  const SubtitleListComponent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isLoading: false.obs,
      scaffoldBackgroundColor: Colors.transparent,
      hasLeadingWidget: false,
      appBartitleText: locale.value.subtitle,
      appBarbackgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),
          16.height,
          Obx(
            () => AnimatedWrap(
              itemCount: controller.subtitleList.length,
              runSpacing: 8,
              itemBuilder: (_, index) {
                SubtitleModel data = controller.subtitleList[index];

                return Obx(
                  () => SubtitleItem(
                    key: ValueKey('subtitle_$index'),
                    data: data,
                    index: index,
                    controller: controller,
                    isSelectedSubtitle: data.id == controller.selectedSubtitleModel.value.id,
                    isFocused: controller.focusedSubtitleIndex.value == index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SubtitleItem extends StatelessWidget {
  SubtitleItem({
    super.key,
    required this.data,
    required this.index,
    required this.isSelectedSubtitle,
    required this.isFocused,
    required this.controller,
  });

  final SubtitleModel data;
  final int index;
  final RxBool hasFocus = false.obs;
  final bool isSelectedSubtitle;
  final bool isFocused;
  final VideoPlayersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        /// Sync focus state with controller's focused index immediately
        /// This ensures the UI reflects the correct focus state
        final shouldHaveFocus = isFocused;
        
        /// Update local focus state to match controller state
        if (shouldHaveFocus != hasFocus.value) {
          hasFocus(shouldHaveFocus);
        }

        return Focus(
          onFocusChange: (value) {
            /// Only update local focus state
            hasFocus(value);
            
            /// When this item gets focus, update controller's focused index
            if (value) {
              /// Use a post-frame callback to ensure the update happens after the current frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.focusedSubtitleIndex.value != index) {
                  controller.focusedSubtitleIndex(index);
                }
              });
            }
          },
          onKeyEvent: (node, event) {
            /// Don't handle key events here - let the controller handle them
            /// This prevents interference with the navigation logic
            return KeyEventResult.ignored;
          },
          child: Container(
            decoration: BoxDecoration(
              color: transparentColor,
              borderRadius: radius(4),
              border: hasFocus.value
                  ? Border.all(
                      color: Colors.white24,
                      width: 2,
                    )
                  : null,
            ),
            child: SettingItemWidget(
              title: data.language,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              titleTextStyle: hasFocus.value ? boldTextStyle() : primaryTextStyle(),
              trailing: isSelectedSubtitle
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
}
