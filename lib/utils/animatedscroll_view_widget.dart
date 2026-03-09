import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../components/category_list/movie_horizontal/poster_card_component.dart';
import 'colors.dart';

class CustomAppScrollingWidget extends StatelessWidget {
  final double paddingLeft;
  final double paddingRight;
  final double paddingBottom;
  final double spacing;
  final double runSpacing;
  final double posterHeight;
  final double posterWidth;
  final bool isLoading;
  final bool isLastPage;
  final List<PosterDataModel> itemList;
  final Future<void> Function() onNextPage;
  final Future<void> Function() onSwipeRefresh;
  final void Function(PosterDataModel) onTap;
  final bool isTop10;
  final bool isSearch;
  final bool isTopChannel;
  final VoidCallback? onUpFromItems;
  final ScrollController? scrollController;

  const CustomAppScrollingWidget({
    super.key,
    required this.paddingLeft,
    required this.paddingRight,
    required this.paddingBottom,
    required this.spacing,
    required this.runSpacing,
    required this.posterHeight,
    required this.posterWidth,
    required this.isLoading,
    required this.isLastPage,
    required this.itemList,
    required this.onNextPage,
    required this.onSwipeRefresh,
    required this.onTap,
    this.isTop10 = false,
    this.isSearch = false,
    this.isTopChannel = false,
    this.onUpFromItems,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final scrollCtrl = scrollController ?? ScrollController();
    int crossAxisCount = (MediaQuery.of(context).size.width ~/ (posterWidth + spacing));

    return RefreshIndicator(
      onRefresh: onSwipeRefresh,
      color: appColorPrimary,
      child: GridView.builder(
        controller: scrollCtrl,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        shrinkWrap: true,
        padding: EdgeInsets.only(
          left: paddingLeft,
          right: paddingRight,
          bottom: paddingBottom,
        ),
        itemCount: itemList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: runSpacing,
          crossAxisSpacing: spacing,
          childAspectRatio: posterWidth / posterHeight,
        ),
        itemBuilder: (context, index) {
          final posterDet = itemList[index];
          final bool isLast = index == itemList.length - 1;
          final bool isEndOfRow = (index + 1) % crossAxisCount == 0;
          final bool isStartOfRow = index % crossAxisCount == 0;
          final bool isFirstRow = index < crossAxisCount;
          return PosterCardComponent(
            key: posterDet.itemGlobalKey,
            index: index,
            height: posterHeight,
            width: posterWidth,
            onTap: () => onTap(posterDet),
            focusNode: posterDet.itemFocusNode,
            isLastIndex: isLast,
            isSingleRow: false,
            onArrowUp: () {
              if (isFirstRow) {
                onUpFromItems?.call();
              } else {
                final itemAboveIndex = index - crossAxisCount;
                if (itemAboveIndex >= 0 && itemAboveIndex < itemList.length) {
                  itemList[itemAboveIndex].itemFocusNode.requestFocus();
                }
              }
            },
            onArrowDown: () {
              final itemBelowIndex = index + crossAxisCount;
              if (itemBelowIndex < itemList.length) {
                itemList[itemBelowIndex].itemFocusNode.requestFocus();
              }
            },
            onArrowRight: () {
              if (isEndOfRow && !isLast) {
                final nextRowFirstIndex = index + 1;
                if (nextRowFirstIndex < itemList.length) {
                  itemList[nextRowFirstIndex].itemFocusNode.requestFocus();
                }
              } else if (!isEndOfRow && index + 1 < itemList.length) {
                itemList[index + 1].itemFocusNode.requestFocus();
              }
            },
            onArrowLeft: () {
              if (index == 0 || isStartOfRow) {
                try {
                  final DashboardController controller = Get.find<DashboardController>();
                  controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
                  return;
                } catch (_) {}
              }

              if (isStartOfRow && !isFirstRow) {
                /// If at start of row (but not first row), move to previous row's last item

                final prevRowLastIndex = index - 1;
                if (prevRowLastIndex >= 0) {
                  itemList[prevRowLastIndex].itemFocusNode.requestFocus();
                }
              } else if (!isStartOfRow) {
                /// If not at start of row, move to previous item in same row

                final prevItemIndex = index - 1;
                if (prevItemIndex >= 0) {
                  itemList[prevItemIndex].itemFocusNode.requestFocus();
                }
              }
            },
            onFocusChange: (hasFocus) {
              if (hasFocus && posterDet.itemGlobalKey.currentContext != null) {
                Scrollable.ensureVisible(
                  posterDet.itemGlobalKey.currentContext!,
                  alignment: 0.1,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );

                if (scrollCtrl.hasClients &&
                    scrollCtrl.position.maxScrollExtent > 0 &&
                    scrollCtrl.offset >= scrollCtrl.position.maxScrollExtent - 500 &&
                    !isLastPage) {
                  onNextPage.call();
                }
              }
            },
            contentDetail: posterDet,
            isHorizontalList: false,
            isLoading: isLoading,
            isTopChannel: isTopChannel,
            isSearch: isSearch,
            isTop10: isTop10,
          );
        },
      ),
    );
  }
}

//Animation ChannelListView

class CustomAnimatedChannelScrollView extends StatefulWidget {
  final double paddingLeft;
  final double paddingRight;
  final double paddingBottom;
  final double spacing;
  final double runSpacing;
  final double posterHeight;
  final double posterWidth;
  final bool isHorizontalList;
  final bool isLoading;
  final bool isLastPage;
  final List<ChannelModel> itemList;
  final Future<void> Function() onNextPage;
  final Future<void> Function() onSwipeRefresh;
  final void Function(ChannelModel) onTap;
  final bool isSearch;
  final bool isTopChannel;

  const CustomAnimatedChannelScrollView({
    super.key,
    required this.paddingLeft,
    required this.paddingRight,
    required this.paddingBottom,
    required this.spacing,
    required this.runSpacing,
    required this.posterHeight,
    required this.posterWidth,
    required this.isHorizontalList,
    required this.isLoading,
    required this.isLastPage,
    required this.itemList,
    required this.onNextPage,
    required this.onSwipeRefresh,
    required this.onTap,
    required this.isSearch,
    required this.isTopChannel,
  });

  @override
  State<CustomAnimatedChannelScrollView> createState() => _CustomAnimatedChannelScrollViewState();
}

class _CustomAnimatedChannelScrollViewState extends State<CustomAnimatedChannelScrollView> {
  final ScrollController scrollController = ScrollController();
  final RxBool _isUiLoaded = false.obs;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (MediaQuery.of(context).size.width ~/ (widget.posterWidth + widget.spacing));

    return RefreshIndicator(
      onRefresh: widget.onSwipeRefresh,
      color: appColorPrimary,
      child: GridView.builder(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          left: widget.paddingLeft,
          right: widget.paddingRight,
          bottom: widget.paddingBottom + 30,
        ),
        itemCount: widget.itemList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: widget.runSpacing,
          crossAxisSpacing: widget.spacing,
          childAspectRatio: widget.posterWidth / widget.posterHeight,
        ),
        itemBuilder: (context, index) {
          final channel = widget.itemList[index];

          // Create PosterDataModel from ChannelModel
          final posterData = PosterDataModel(
            id: channel.id,
            posterImage: channel.posterTvImage,
            details: ContentData(
              id: channel.id,
              name: channel.name,
              type: VideoType.liveTv,
              thumbnailImage: channel.posterTvImage,
              access: channel.access,
              requiredPlanLevel: channel.requiredPlanLevel,
            ),
          );

          return PosterCardComponent(
            height: widget.posterHeight,
            width: widget.posterWidth,
            onTap: () => widget.onTap(channel),
            contentDetail: posterData,
            isHorizontalList: widget.isHorizontalList,
            isLoading: widget.isLoading,
            isTopChannel: widget.isTopChannel,
            isSearch: widget.isSearch,
            isTop10: false,
            onFocusChange: (hasFocus) {
              if (!_isUiLoaded.value) {
                _isUiLoaded.value = true;
              } else if (hasFocus && channel.itemGlobalKey.currentContext != null) {
                try {
                  if (scrollController.position.maxScrollExtent >= (scrollController.offset - 52) &&
                      !widget.isLastPage) {
                    Scrollable.ensureVisible(
                      alignment: 0.05,
                      channel.itemGlobalKey.currentContext!,
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                    widget.onNextPage.call();
                  }
                } catch (e) {
                  debugPrint('ensureVisible failed: $e');
                }
              }
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
