import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/utils/shimmer/shimmer.dart';
import '../../components/app_scaffold.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/empty_error_state_widget.dart';
import 'components/search_component.dart';
import 'search_controller.dart';
import 'tv_search_component.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});
  final SearchScreenController searchCont = Get.put(SearchScreenController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (Get.previousRoute == "/PosterCardComponent") {
            searchCont.restoreSearchQuery();
          } else {
            searchCont.clearSearchField();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: TVSearchComponent(
            searchConfig: TVSearchConfig(
              searchFocus: searchCont.searchFocus,
              voiceIconFocus: searchCont.voiceIconFocus,
              searchTextCont: searchCont.searchTextCont,
              searchResultsHasFocus: searchCont.searchResultsHasFocus,
              recentSearches: <String>[].obs,
              onSearch: (query) {
                // Handle search
                log('Searching for: $query');
                searchCont.onSearch(searchVal: query.trim());
              },
              onClear: (p0) {
                searchCont.clearSearchField();
              },
              onRecentSearchTap: (search) {
                // Handle recent search tap
                log('Tapped recent search: $search');
              },
              hintText: 'Search',
              showRecentSearches: false,
              searchResults: Focus(
                focusNode: searchCont.searchResultsFocus,
                onKeyEvent: (node, event) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                      searchCont.searchMovieDetails.isNotEmpty &&
                      searchCont
                          .searchMovieDetails.first.itemFocusNode.hasFocus) {
                    searchCont.searchFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                onFocusChange: (value) {
                  if (value && searchCont.searchMovieDetails.isNotEmpty) {
                    searchCont.searchMovieDetails.first.itemFocusNode
                        .requestFocus();
                  }
                },
                child: Obx(
                  () => SnapHelperWidget(
                    future: searchCont.getSearchMovieFuture.value,
                    loadingWidget: Offstage(),
                    errorBuilder: (error) {
                      return NoDataWidget(
                        titleTextStyle: secondaryTextStyle(color: white),
                        subTitleTextStyle: primaryTextStyle(color: white),
                        title: error,
                        retryText: locale.value.reload,
                        imageWidget: const ErrorStateWidget(),
                        onRetry: () {
                          searchCont.getSearchMovieDetail(showLoader: true);
                        },
                      );
                    },
                    onSuccess: (res) {
                      return AnimatedScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        listAnimationType: commonListAnimationType,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          10.height.visible(
                              searchCont.searchTextCont.text.length > 2),
                          if (searchCont.isSearchLoading.value) buildShimmer(),
                          SearchComponent().visible(
                              searchCont.searchTextCont.text.length > 2 &&
                                  searchCont.isSearchLoading.isFalse),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ).obs,
          ),
        ),
      ),
    );
  }

  Widget buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        viewAllWidget(
          label: locale.value.searchResults,
          showViewAll: false,
          iconSize: 18,
        ),
        HorizontalList(
          physics: const AlwaysScrollableScrollPhysics(),
          runSpacing: 10,
          spacing: 10,
          itemCount: 10,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            return Container(
              padding: EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: radius(8),
                child: Shimmer.fromColors(
                  baseColor: shimmerPrimaryBaseColor,
                  highlightColor: shimmerHighLightBaseColor,
                  direction: ShimmerDirection.ltr,
                  child: Container(
                    height: 150,
                    width: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2A2A2A),
                          const Color(0xFF121212),
                          Colors.black.withValues(alpha: 0.9)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ).paddingSymmetric(vertical: 4);
  }
}
