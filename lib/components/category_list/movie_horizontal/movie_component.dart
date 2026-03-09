import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/content_list_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/screens/watch_list/watch_list_screen.dart';
import 'package:streamit_laravel/utils/common_base.dart';

import '../../../screens/channel_list/channel_list_screen.dart';
import '../../../utils/app_common.dart';
import 'horizontal_movie_controller.dart';
import 'poster_card_component.dart';

class HorizontalMovieComponent extends StatelessWidget {
  final CategoryListModel movieDet;
  final bool isTop10;
  final bool isTopChannel;
  final bool isSearch;
  final bool isLoading;
  final bool isWatchList;
  final String type;
  final bool isPlayTrailer;
  final bool isFirstCategory;

  final bool isPaddingRequired;

  const HorizontalMovieComponent({
    super.key,
    required this.movieDet,
    this.isTop10 = false,
    required this.isSearch,
    this.isLoading = false,
    this.isWatchList = false,
    this.isTopChannel = false,
    required this.type,
    this.isPaddingRequired = true,
    this.isPlayTrailer = false,
    this.isFirstCategory = false,
  });

  HorizontalMovieController get controller => Get.put(
        HorizontalMovieController(movieDet: movieDet, isFirstCategory: isFirstCategory, isTopChannel: isTopChannel, isTop10: isTop10),
        tag: '${movieDet.name}_${movieDet.hashCode}',
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      key: movieDet.categorykey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if(movieDet.name.validate().isNotEmpty)
        viewAllWidget(
          label: movieDet.isEachWordCapitalized ? movieDet.name.capitalizeEachWord() : movieDet.name, 
          showViewAll: false,
          onButtonPressed: () {
            if (isWatchList) {
              Get.to(() => WatchListScreen());
            } else if (isTopChannel) {
              Get.to(() => ChannelListScreen(title: movieDet.name.validate()));
            } else {
              if (type case DashboardCategoryType.video) {
                Get.to(() => ContentListScreen(title: movieDet.name.validate()));
              } else if (type case DashboardCategoryType.movie) {
                Get.to(() => ContentListScreen(title: movieDet.name.validate()));
              } else if (type case DashboardCategoryType.tvShow) {
                Get.to(() => ContentListScreen(title: movieDet.name.validate()));
              }
            }
          },
          iconSize: 18,
        ),
        Focus(
          onFocusChange: controller.onFocusChange,
          child: SizedBox(
            height: 160,
            child: AnimatedListView(
              physics: isLoading ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              controller: controller.listController,
              itemCount: isTopChannel ? movieDet.data.take(10).length : movieDet.data.length,
              shrinkWrap: false,
              itemBuilder: (context, index) {
                PosterDataModel movie = movieDet.data[index];

                return Stack(
                  key: ValueKey('${movieDet.name}_${movie.id}_$index'),
                  clipBehavior: Clip.none,
                  children: [
                    PosterCardComponent(
                      key: ValueKey('${movieDet.name}_poster_${movie.id}_$index'),
                      videoData: null,
                      index: index,
                      focusNode: controller.getItemFocusNode(index),
                      onFocusChange: (value) => controller.onItemFocusChange(value, movieDet.categorykey),
                      control: controller.listController,
                      contentDetail: movie,
                      isTop10: isTop10,
                      isSearch: isSearch,
                      isLoading: isLoading,
                      width: Get.width / 4,
                      isTopChannel: isTopChannel,
                      height: 150,
                      isPlayTrailer: isPlayTrailer,
                      isLastIndex: controller.isLastIndex(index),
                      onArrowUp: controller.onArrowUp,
                      onArrowDown: controller.onArrowDown,
                      onArrowRight: () => controller.onArrowRight(index),
                      onArrowLeft: () => controller.onArrowLeft(index),
                      categoryKey: key.hashCode.toString(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ).paddingSymmetric(vertical: 4);
  }
}
