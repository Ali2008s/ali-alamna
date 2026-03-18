import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/home/components/continue_watch_component.dart';
import '../../../../utils/common_base.dart';
import '../../screens/home/components/ad_component.dart';
import '../../screens/home/components/geners/genres_component.dart';
import '../../screens/home/components/language_component/language_component.dart';
import '../../screens/home/components/person_component/person_component.dart';
import '../../screens/home/model/dashboard_res_model.dart';
import 'movie_horizontal/movie_component.dart';

class CategoryListComponent extends StatelessWidget {
  final RxList<CategoryListModel> categoryList;
  final bool isSearch;
  final bool isLoading;
  final bool isPlayTrailer;

  const CategoryListComponent({super.key, required this.categoryList, this.isSearch = false, this.isLoading = false, this.isPlayTrailer = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        // Find the first visible category index
        int firstVisibleIndex = -1;
        for (int i = 0; i < categoryList.length; i++) {
          if (categoryList[i].sectionType != DashboardCategoryType.trending && 
              categoryList[i].data.isNotEmpty) {
            firstVisibleIndex = i;
            break;
          }
        }

        return AnimatedListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryList.length,
          itemBuilder: (context, index) {
            CategoryListModel category = categoryList[index];
            final bool isFirstCategory = index == firstVisibleIndex;
            bool isChannelSection = category.sectionType == DashboardCategoryType.channels || category.sectionType.startsWith('channels_') || category.type == 'livetv';
            
            switch (category.sectionType) {
              case DashboardCategoryType.continueWatching:
                return ContinueWatchComponent(continueWatchList: category.data as List<PosterDataModel>, isFirstCategory: isFirstCategory);
            case DashboardCategoryType.trending:
              return Offstage();
            case DashboardCategoryType.personalised:
              return HorizontalMovieComponent(
                key: Key('personalised_$index'),
                movieDet: category,
                isTop10: false,
                isSearch: false,
                type: category.sectionType,
                isLoading: isLoading,
                isPlayTrailer: isPlayTrailer,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.top10:
              return HorizontalMovieComponent(
                key: Key('personalised_$index'),
                movieDet: category,
                isTop10: true,
                isSearch: isSearch,
                type: category.sectionType,
                isPlayTrailer: isPlayTrailer,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.advertisement:
              return AdComponent();
            case DashboardCategoryType.movie:
            case DashboardCategoryType.tvShow:
            case DashboardCategoryType.horizontalList:
              return HorizontalMovieComponent(
                key: Key('personalised_$index'),
                movieDet: category,
                isSearch: isSearch,
                type: category.sectionType,
                isLoading: isLoading,
                isPlayTrailer: isPlayTrailer,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.channels:
              return HorizontalMovieComponent(
                key: Key('personalised_$index'),
                movieDet: category,
                isSearch: isSearch,
                isTopChannel: true,
                type: category.sectionType,
                isLoading: isLoading,
                isPlayTrailer: isPlayTrailer,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.language:
              return LanguageComponent(
                languageDetails: category,
                isLoading: isLoading,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.personality:
              return PersonComponent(
                personDetails: category,
                isLoading: isLoading,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.genres:
              return GenreComponent(
                genresDetails: category,
                isLoading: isLoading,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
            case DashboardCategoryType.rateApp:
              return Offstage();
            default:
              return HorizontalMovieComponent(
                key: Key('personalised_$index'),
                movieDet: category,
                isTop10: false,
                isSearch: isSearch,
                isLoading: isLoading,
                type: category.sectionType,
                isTopChannel: isChannelSection,
                isPlayTrailer: isPlayTrailer,
                isFirstCategory: isFirstCategory,
              ).visible(category.data.isNotEmpty);
          }
        },
      );
      },
    );
  }
}
