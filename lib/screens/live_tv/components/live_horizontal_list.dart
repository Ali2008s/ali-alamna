import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import 'package:streamit_laravel/utils/constants.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';

import '../../../utils/app_common.dart';
import '../../channel_list/channel_list_screen.dart';
import '../live_tv_details/live_tv_details_screen.dart';
import 'live_show_card_component.dart';

class LiveHorizontalComponent extends StatelessWidget {
  final CategoryData movieDet;
  final double? height;
  final double? width;

  LiveHorizontalComponent({super.key, required this.movieDet, this.height, this.width});

  final ScrollController listController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: movieDet.categorykey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        viewAllWidget(
            label: movieDet.name,
            showViewAll: false,
            onButtonPressed: () {
              Get.to(() => ChannelListScreen(title: movieDet.name.validate()), arguments: movieDet.id);
            },
            iconSize: 18),
        if (movieDet.channelData.isNotEmpty)
          HorizontalList(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: listController,
            runSpacing: 10,
            spacing: 10,
            itemCount: movieDet.channelData.length,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              ChannelModel show = movieDet.channelData[index];
              return FocusableChannelCard(
                liveShowDet: show,
                onFocusChange: (value) {
                  if (value && movieDet.categorykey.currentContext != null) {
                    Scrollable.ensureVisible(
                      alignment: 0.01,
                      movieDet.categorykey.currentContext!,
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                  if (value && listController.hasClients && listController.position.maxScrollExtent >= (listController.offset + 70)) {
                    listController.animateTo(index * (Get.width / 4.7), duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
                isFirst: index == 0,
              );
            },
          ),
        if (movieDet.channelData.isNotEmpty) 8.height,
      ],
    ).visible(movieDet.channelData.isNotEmpty);
  }
}

class FocusableChannelCard extends StatelessWidget {
  final bool isFirst;
  final Function(bool)? onFocusChange;
  final ChannelModel liveShowDet;

  FocusableChannelCard({
    super.key,
    required this.isFirst,
    this.onFocusChange,
    required this.liveShowDet,
  });

  final RxBool hasFocus = false.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Focus(
        canRequestFocus: true,
        focusNode: liveShowDet.itemFocusNode,
        onFocusChange: (value) {
          onFocusChange?.call(value);
          hasFocus(value);
        },
        onKeyEvent: (node, event) {
          try {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                LiveStream().emit(podPlayerPauseKey);
                Get.to(() => LiveShowDetailsScreen(), arguments: liveShowDet);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft && isFirst) {
                final controller = Get.find<DashboardController>();
                controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
                return KeyEventResult.handled;
              }
            }
          } catch (e) {
            log('error in ChannelCard KeyboardListener: $e');
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: () {
            LiveStream().emit(podPlayerPauseKey);
            Get.to(() => LiveShowDetailsScreen(), arguments: liveShowDet);
          },
          onFocusChange: (value) {
            // value is already handled by Focus widget
          },
          child: AnimatedContainer(
            margin: EdgeInsets.only(right: 16, top: 16),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..translate(0.0, hasFocus.value ? -8.0 : 0.0, 0.0)
              ..scale(hasFocus.value ? 1.05 : 1.0),
            child: Container(
              decoration: boxDecorationDefault(
                borderRadius: radius(4),
                color: cardColor,
                border: focusBorder(hasFocus.value),
                boxShadow: hasFocus.value ? [BoxShadow(color: white.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4), spreadRadius: 2)] : null,
              ),
              child: LiveShowCardComponent(width: Get.width / 4, liveShowDet: liveShowDet),
            ),
          ),
        ),
      ),
    );
  }
}