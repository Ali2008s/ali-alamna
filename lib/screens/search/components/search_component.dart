import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import 'package:streamit_laravel/screens/search/search_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import '../../../components/category_list/movie_horizontal/poster_card_component.dart';

class SearchComponent extends StatelessWidget {
  SearchComponent({super.key});

  final SearchScreenController searchCont = Get.find();

  final ScrollController listController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (searchCont.searchMovieDetails.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 30),
            child: NoDataWidget(
              titleTextStyle: secondaryTextStyle(),
              subTitleTextStyle: primaryTextStyle(),
              title: locale.value.noSearchResultsFound,
              subTitle: locale.value.trySearchingForSomething,
              image: Assets.searchNotFound,
              imageSize: Size(75, 75),
            ).visible(searchCont.searchTextCont.text.isNotEmpty),
          );
        } else {
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
                controller: listController,
                physics: const AlwaysScrollableScrollPhysics(),
                runSpacing: 10,
                spacing: 10,
                itemCount: searchCont.searchMovieDetails.length,
                itemBuilder: (context, index) {
                  return PosterCardComponent(
                    control: listController,
                    index: index,
                    focusNode:
                        searchCont.searchMovieDetails[index].itemFocusNode,
                    onFocusChange: (p0) {
                      if(p0) {
                        Scrollable.ensureVisible(
                          searchCont.searchMovieDetails[index]
                              .itemFocusNode.context!,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignmentPolicy:
                              ScrollPositionAlignmentPolicy.explicit,
                        );
                      }
                    },
                    onArrowUp: () {
                      searchCont.searchFocus.requestFocus();
                    },
                    onArrowRight: () {
                      if (index != searchCont.searchMovieDetails.length - 1) {
                        searchCont.searchMovieDetails[index + 1].itemFocusNode
                            .requestFocus();
                      }
                    },
                    onArrowLeft: () {
                      if (index != 0) {
                        searchCont.searchMovieDetails[index - 1].itemFocusNode
                            .requestFocus();
                            return;
                      }
                      if(index == 0) {
                        final list = getDashboardController().bottomNavItems.where((e) => e.type == BottomItem.search).toList();
                        if(list.isEmpty) return;
                        FocusScope.of(context).requestFocus(list.first.focusNode);
                      }
                    },
                    saveSearchResults: () {
                      var selectedMovie = searchCont.searchMovieDetails[index];
                      searchCont.saveSearch(
                        searchQuery: selectedMovie.details.name,
                        type: selectedMovie.details.type,
                        searchID: selectedMovie.id.toString(),
                      );
                    },
                    isForSearch: true,
                    contentDetail: searchCont.searchMovieDetails[index],
                  );
                },
              ),
            ],
          ).paddingSymmetric(vertical: 4);
        }
      },
    );
  }
}
