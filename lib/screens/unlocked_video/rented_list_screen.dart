// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/components/content_list_shimmer.dart';
import 'package:streamit_laravel/screens/unlocked_video/rented_content_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/animatedscroll_view_widget.dart';
import '../../utils/app_common.dart';
import '../../utils/empty_error_state_widget.dart';
import '../content/content_details_screen.dart';
import '../tv_show/tv_show_detail_screen.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';

class RentedListScreen extends StatelessWidget {
  String? title = locale.value.movies;

  RentedListScreen({
    super.key,
    this.title,
  });

  final RentedContentController movieListCont = Get.put(RentedContentController(), tag: UniqueKey().toString());
  final DashboardController dashboardController = Get.find<DashboardController>();
  final RxBool hasFocus = false.obs;

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      hasLeadingWidget: false,
      isLoading: movieListCont.page.value == 1 ? false.obs : movieListCont.isLoading,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      topBarBgColor: transparentColor,
      hideAppBar: true,
      body: Obx(
        () => SnapHelperWidget(
          future: movieListCont.rentedContentFuture.value,
          initialData: cachedRentedContentList.isNotEmpty ? cachedRentedContentList : null,
          loadingWidget: const NewShimmerMovieList(hideAboveSection: true),
          errorBuilder: (error) {
            return NoDataWidget(
              titleTextStyle: secondaryTextStyle(color: white),
              subTitleTextStyle: primaryTextStyle(color: white),
              title: error,
              retryText: locale.value.reload,
              imageWidget: const ErrorStateWidget(),
              onRetry: () {
                movieListCont.page(1);
                movieListCont.getRentedContentDetails();
              },
            );
          },
          onSuccess: (res) {
            return Obx(
              () => AnimatedScrollView(
                      padding: EdgeInsets.only(bottom: 90),
                      children: [
                        24.height,
                        Text(
                          locale.value.unlockedVideo,
                          style: boldTextStyle(size: 20, color: white),
                        ).paddingSymmetric(horizontal: 24),
                        8.height,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  'all', 
                                  locale.value.all, 
                                  movieListCont, 
                                  focusNode: movieListCont.allFocusNode,
                                  onNextPageFocusNode: appConfigs.value.enableMovie ? movieListCont.movieFocusNode : appConfigs.value.enableVideo ? movieListCont.videoFocusNode : appConfigs.value.enableTvShow ? movieListCont.episodeFocusNode : null,
                                  onPreviousPageFocusNode: dashboardController.bottomNavItems[dashboardController.selectedBottomNavIndex.value].focusNode,
                                ),
                                if(appConfigs.value.enableMovie)...[
                                  12.width,
                                  _buildFilterChip(
                                    'movie', 
                                    locale.value.movies, 
                                    movieListCont,
                                    focusNode: movieListCont.movieFocusNode,
                                    onNextPageFocusNode: appConfigs.value.enableVideo ? movieListCont.videoFocusNode : appConfigs.value.enableTvShow ? movieListCont.episodeFocusNode : null,
                                    onPreviousPageFocusNode: movieListCont.allFocusNode,
                                  ),
                                ],
                                if(appConfigs.value.enableVideo)...[
                                  12.width,
                                  _buildFilterChip(
                                    'video',
                                    locale.value.videos,
                                    movieListCont,
                                    focusNode: movieListCont.videoFocusNode,
                                    onNextPageFocusNode: appConfigs.value.enableTvShow ? movieListCont.episodeFocusNode : null,
                                    onPreviousPageFocusNode: appConfigs.value.enableMovie ? movieListCont.movieFocusNode : movieListCont.allFocusNode,
                                  ),
                                ],
                                if(appConfigs.value.enableTvShow)...[
                                  12.width,
                                  _buildFilterChip(
                                    'episodes',
                                    locale.value.episode,
                                    movieListCont,
                                    focusNode: movieListCont.episodeFocusNode,
                                    onNextPageFocusNode: null,
                                    onPreviousPageFocusNode:appConfigs.value.enableVideo ? movieListCont.videoFocusNode : appConfigs.value.enableMovie ? movieListCont.movieFocusNode : movieListCont.allFocusNode,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if(movieListCont.filteredRentedContentList.isEmpty)...[
                          NoDataWidget(
                            titleTextStyle: boldTextStyle(color: white),
                            subTitleTextStyle: primaryTextStyle(color: white),
                            title: locale.value.rentedVideoNotPurchase,
                            retryText: "",
                            imageWidget: const EmptyStateWidget(),
                          ).paddingSymmetric(horizontal: 16),
                        ],
                        CustomAppScrollingWidget(
                          paddingLeft: 24,
                          paddingRight: 24,
                          paddingBottom: 24,
                          spacing: 12,
                          runSpacing: 12,
                          posterHeight: 150 * 1.2,
                          posterWidth: (Get.width / 8.8) * 1.2,
                          isLoading: false,
                          isLastPage: movieListCont.isLastPage.value,
                          itemList: movieListCont.filteredRentedContentList,
                          onNextPage: movieListCont.onNextPage,
                          onSwipeRefresh: () async {
                            movieListCont.page(1);
                            return await movieListCont.getRentedContentDetails(showLoader: false);
                          },
                          onUpFromItems: () {
                            movieListCont.allFocusNode.requestFocus();
                          },
                          onTap: (posterDet) {
                            doIfLogin(onLoggedIn: () {
                              if (posterDet.details.type == VideoType.episode) {
                                Get.to(() => TVShowPreviewScreen(), arguments: posterDet);
                              } else if (posterDet.details.type == VideoType.movie) {
                                Get.to(() => ContentDetailsScreen(isFromContinueWatch: true), arguments: posterDet);
                              } else if (posterDet.details.type == VideoType.video) {
                                Get.to(() => ContentDetailsScreen(), arguments: posterDet);
                              }
                            });
                          },
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildFilterChip(String key, String label, RentedContentController cont,{
  FocusNode? focusNode,
  FocusNode? onNextPageFocusNode,
  FocusNode? onPreviousPageFocusNode,
}) {
  return Obx(() {
      final bool selected = cont.selectedFilter.value == key;
      return Focus(
        focusNode: focusNode,
        onFocusChange: (value) {
          if (value) {
            cont.setFilter(key);
          }
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight && onNextPageFocusNode != null) {
              onNextPageFocusNode.requestFocus();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && onPreviousPageFocusNode != null) {
              onPreviousPageFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
            if(event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if(cont.filteredRentedContentList.isEmpty) return KeyEventResult.ignored;
              cont.filteredRentedContentList.first.itemFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
            if(event.logicalKey == LogicalKeyboardKey.arrowUp) {
              cont.allFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? appColorPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? appColorPrimary : borderColor),
          ),
          child: Text(
            label,
            style: primaryTextStyle(color: selected ? white : secondaryTextColor),
          ),
        ),
      );
    }
  );
}
