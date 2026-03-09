import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/screens/slider/slider_controller.dart';
import 'package:streamit_laravel/screens/watch_list/model/watch_list_resp.dart';
import 'package:streamit_laravel/services/local_storage_service.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../main.dart';
import '../../network/auth_apis.dart';
import '../../network/core_api.dart';
import '../../utils/app_common.dart';
import '../../utils/common_base.dart';

class HomeController extends GetxController {
  /// Declarations
  bool forceSyncDashboardAPI;
  RxBool showCategoryShimmer = false.obs;
  RxBool isLastPage = false.obs;
  RxBool isWatchListLoading = false.obs;
  RxBool sliderHasFocus = false.obs;
  FocusNode sliderFocus = FocusNode();
  final GlobalKey sliderKey = GlobalKey();
  final GlobalKey continueWatchingKey = GlobalKey();
  FocusNode? firstCategoryFocusNode;
  bool hasRequestedInitialFocus = false;
  
  /// Map of category names to focus nodes
  Map<String, FocusNode> categoryFocusNodes = {};

  /// Map of category names to scroll controllers
  Map<String, ScrollController> categoryScrollControllers = {};

  /// Register a category focus node and scroll controller
  void registerCategoryFocusNode(String categoryName, FocusNode focusNode, ScrollController scrollController) {
    categoryFocusNodes[categoryName] = focusNode;
    categoryScrollControllers[categoryName] = scrollController;
  }

  /// Navigate to next category
  /// Uses the order from dashboardSectionList to ensure correct navigation order
  void navigateToNextCategory(String currentCategoryName) {
    // Use the order from dashboardSectionList to ensure correct navigation order
    final categoryNames = dashboardSectionList.where((category) => categoryFocusNodes.containsKey(category.name)).map((category) => category.name).toList();

    final currentIndex = categoryNames.indexOf(currentCategoryName);
    if (currentIndex >= 0 && currentIndex + 1 < categoryNames.length) {
      final nextCategoryName = categoryNames[currentIndex + 1];
      final nextFocusNode = categoryFocusNodes[nextCategoryName];
      final nextScrollController = categoryScrollControllers[nextCategoryName];

      if (nextFocusNode != null) {
        if (nextScrollController != null && nextScrollController.hasClients) {
          nextScrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        nextFocusNode.requestFocus();
      }
    }
  }
  
  /// Navigate to previous category
  /// Uses the order from dashboardSectionList to ensure correct navigation order
  void navigateToPreviousCategory(String currentCategoryName) {
    final categoryNames = dashboardSectionList.where((category) => categoryFocusNodes.containsKey(category.name)).map((category) => category.name).toList();

    final currentIndex = categoryNames.indexOf(currentCategoryName);
    if (currentIndex > 0) {
      final previousCategoryName = categoryNames[currentIndex - 1];
      final previousFocusNode = categoryFocusNodes[previousCategoryName];
      final previousScrollController = categoryScrollControllers[previousCategoryName];
      
      if (previousFocusNode != null) {
        if (previousScrollController != null && previousScrollController.hasClients) {
          previousScrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        previousFocusNode.requestFocus();

        /// Scroll to Continue Watching if it's the previous category
        if (previousCategoryName == locale.value.continueWatching) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (continueWatchingKey.currentContext != null && homeScrollController.hasClients) {
                Scrollable.ensureVisible(
                  continueWatchingKey.currentContext!,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            });
          });
        }
      }
    }
  }

  /// Request initial focus on slider
  void requestInitialFocus() {
    if (!hasRequestedInitialFocus && sliderController.listContent.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!hasRequestedInitialFocus && sliderController.listContent.isNotEmpty) {
            hasRequestedInitialFocus = true;
            sliderFocus.requestFocus();
            log('Requested initial focus on slider');
          }
        });
      });
    }
  }

  Rx<Future<DashboardDetailResponse>> dashboardDetailsFuture = Future(() => DashboardDetailResponse(data: DashboardModel())).obs;

  Rx<Future<DashboardDetailResponse>> dashboardOtherDetailsFuture = Future(() => DashboardDetailResponse(data: DashboardModel())).obs;

  Rx<PosterDataModel> currentSliderPage = PosterDataModel(details: ContentData()).obs;

  SliderController sliderController = SliderController();

  RxList<CategoryListModel> dashboardSectionList = RxList();

  RxList<CategoryListModel> sectionList = RxList();

  Rx<PageController> sliderPageController = PageController(initialPage: 0).obs;

  HomeController({this.forceSyncDashboardAPI = false});

  final homeScrollController = ScrollController();

  /// Init Call Method
  @override
  void onInit() {
    if (cachedDashboardDetailResponse != null) {
      createCategorySections(cachedDashboardDetailResponse!.data);
    }
    init(showLoader: true);
    super.onInit();
  }

  /// Init Function
  Future<void> init({bool forceSync = false, bool showLoader = false, bool forceConfigSync = false}) async {
    isLastPage(false);
    getAppConfigurations(forceConfigSync);
    sliderController.getBanner(type: BannerType.home);

    checkApiCallIsWithinTimeSpan(
      forceSync: forceSync,
      callback: () {
        getDashboardDetail(showLoader: showLoader);
      },
      sharePreferencesKey: SharedPreferenceConst.DASHBOARD_DETAIL_LAST_CALL_TIME,
    );
  }

  /// Pagination handling
  void onNextPage() {
    if (!isLastPage.value) {
      getOtherDashboardDetails(showLoader: true);
    }
  }

  ///Get Dashboard List
  Future<void> getDashboardDetail({bool showLoader = false}) async {
    showCategoryShimmer(showLoader);
    dashboardSectionList.clear();

    await dashboardDetailsFuture(CoreServiceApis.getDashboard()).then((value) async {
      value.data.continueWatch.validate().removeWhere((continueWatchData) {
        return calculatePendingPercentage(
              continueWatchData.details.duration.isEmpty || continueWatchData.details.duration == "00:00:00" ? "00:00:01" : continueWatchData.details.duration,
              continueWatchData.details.watchedDuration.isEmpty || continueWatchData.details.watchedDuration == "00:00:00" ? "00:00:01" : continueWatchData.details.watchedDuration,
            ).$1 ==
            1;
      });

      cachedDashboardDetailResponse = value;
      setValue(SharedPreferenceConst.DASHBOARD_DETAIL_LAST_CALL_TIME, DateTime.timestamp().millisecondsSinceEpoch);
      await createCategorySections(value.data);
      await getOtherDashboardDetails(showLoader: false);
    }).whenComplete(
      () {
        showCategoryShimmer(false);
      },
    ).catchError((e) {
      showCategoryShimmer(false);
    });
  }

  /// GET Other Dashboard Data Details
  Future<void> getOtherDashboardDetails({bool showLoader = false}) async {
    showCategoryShimmer(showLoader);
    await dashboardOtherDetailsFuture(CoreServiceApis.getDashboardDetailOtherData()).then((value) async {
      isLastPage(true);
      await createCategorySections(value.data, isFirstPage: false);
      showCategoryShimmer(false);
      final DashboardDetailResponse? oldData = cachedDashboardDetailResponse;
      cachedDashboardDetailResponse = value;
      if (oldData != null) {
        cachedDashboardDetailResponse!.data.continueWatch = oldData.data.continueWatch;
        cachedDashboardDetailResponse!.data.top10List = oldData.data.top10List;
        cachedDashboardDetailResponse!.data.latestList = oldData.data.latestList;
        cachedDashboardDetailResponse!.data.likeMovieList = oldData.data.likeMovieList;
        cachedDashboardDetailResponse!.data.viewedMovieList = oldData.data.viewedMovieList;
        cachedDashboardDetailResponse!.data.basedOnLastWatchMovieList = oldData.data.basedOnLastWatchMovieList;
      }

      setJsonToLocal(SharedPreferenceConst.CACHE_DASHBOARD, cachedDashboardDetailResponse!.data.toJson());
    }).catchError((e) {
      showCategoryShimmer(false);
    });
  }

  ///GET Category Sections Data
  Future<void> createCategorySections(DashboardModel dashboard, {bool isFirstPage = true}) async {
    showCategoryShimmer(true);

    final DashboardModel newDashboardData = removeNotEnableModuleSections(dashboard);

    if (isFirstPage) {
      createDashboardFirstSectionList(newDashboardData);
    } else {
      createDashboardOtherSectionList(newDashboardData);
    }

    showCategoryShimmer(false);
  }

  /// Remove Not Enable Module Sections
  DashboardModel removeNotEnableModuleSections(DashboardModel dashboard) {
    if (!appConfigs.value.enableMovie) {
      for (var list in [
        dashboard.basedOnLastWatchMovieList,
        dashboard.trendingInCountryMovieList,
        dashboard.trendingMovieList,
        dashboard.likeMovieList,
        dashboard.viewedMovieList,
        dashboard.payPerView,
      ]) {
        list.removeWhere((e) => e.details.type == VideoType.movie);
      }
    }

    if (!appConfigs.value.enableTvShow) {
      for (var list in [
        dashboard.basedOnLastWatchMovieList,
        dashboard.trendingInCountryMovieList,
        dashboard.trendingMovieList,
        dashboard.likeMovieList,
        dashboard.viewedMovieList,
        dashboard.payPerView,
      ]) {
        list.removeWhere((e) => e.details.type == VideoType.tvshow || e.details.type == VideoType.episode);
      }
    }

    if (!appConfigs.value.enableVideo) {
      for (var list in [
        dashboard.basedOnLastWatchMovieList,
        dashboard.trendingInCountryMovieList,
        dashboard.trendingMovieList,
        dashboard.likeMovieList,
        dashboard.viewedMovieList,
        dashboard.payPerView,
      ]) {
        list.removeWhere((e) => e.details.type == VideoType.video);
      }
    }

    return dashboard;
  }

  /// Create Dashboard First Section List
  void createDashboardFirstSectionList(DashboardModel dashboard) {
    if (appConfigs.value.enableContinueWatch && dashboard.continueWatch.isNotEmpty) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.continueWatching,
          sectionType: DashboardCategoryType.continueWatching,
          data: dashboard.continueWatch,
        ),
        index: 0,
      );
    }

    addOrReplaceSection(
      targetList: dashboardSectionList,
      newSection: CategoryListModel(
        name: dashboard.top10List?.name ?? '',
        sectionType: DashboardCategoryType.top10,
        data: dashboard.top10List?.data ?? [],
      ),
      index: 1,
    );

    // 🎬 Latest Movies
    if (appConfigs.value.enableMovie) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.latestMovies,
          sectionType: DashboardCategoryType.latestMovies,
          data: dashboard.latestList?.data ?? [],
          showViewAll: dashboard.latestList!.data.length > 8,
        ),
        index: 3,
      );
    }

    // 💰 Pay Per View
    addOrReplaceSection(
      targetList: dashboardSectionList,
      newSection: CategoryListModel(
        name: locale.value.payPerView,
        sectionType: DashboardCategoryType.payPerView,
        data: dashboard.payPerView,
        showViewAll: true
      ),
      index: 4,
    );

    // 🌐 Languages
    addOrReplaceSection(
      targetList: dashboardSectionList,
      newSection: CategoryListModel(
        name: dashboard.popularLanguageList?.name ?? locale.value.popularLanguages,
        sectionType: DashboardCategoryType.language,
        data: dashboard.popularLanguageList?.languageList ?? [],
      ),
      index: 5,
    );

    // 🎥 Popular Movies
    if (appConfigs.value.enableMovie) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: dashboard.popularMovieList?.name ?? '',
          sectionType: DashboardCategoryType.movie,
          data: dashboard.popularMovieList?.data ?? [],
          showViewAll: (dashboard.popularMovieList?.data ?? []).length > 9,
        ),
        index: 6,
      );
    }
  }

  Future<void> createDashboardOtherSectionList(DashboardModel dashboard) async {
    // 📺 Live TV Channels
    if (appConfigs.value.enableLiveTv) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: dashboard.topChannelList?.name ?? '',
          sectionType: DashboardCategoryType.channels,
          data: dashboard.topChannelList?.data ?? [],
          showViewAll: true,
        ),
        index: 7,
      );
    }

    // 📺 Popular TV Shows
    if (appConfigs.value.enableTvShow) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: dashboard.popularTvShowList?.name ?? '',
          sectionType: DashboardCategoryType.tvShow,
          data: dashboard.popularTvShowList?.data ?? [],
          showViewAll: dashboard.popularTvShowList!.data.length > 8,
        ),
        index: 8,
      );
    }

    // 👩‍🎤 Personalities
    addOrReplaceSection(
      targetList: dashboardSectionList,
      newSection: CategoryListModel(
        name: dashboard.actorList?.name ?? '',
        sectionType: DashboardCategoryType.personality,
        data: dashboard.actorList?.data ?? [],
        showViewAll: true,
      ),
      index: 9,
    );

    // 🆓 Free Movies
    if (appConfigs.value.enableMovie) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: dashboard.freeMovieList?.name ?? '',
          sectionType: DashboardCategoryType.movie,
          data: dashboard.freeMovieList?.data ?? [],
          showViewAll: true,
        ),
        index: 10,
      );
    }

    // 🎭 Genres
    addOrReplaceSection(
      targetList: dashboardSectionList,
      newSection: CategoryListModel(
        name: locale.value.genres,
        sectionType: DashboardCategoryType.genres,
        data: dashboard.genreList?.data ?? [],
        showViewAll: true,
      ),
      index: 11
    );

    // 📼 Popular Videos
    if (appConfigs.value.enableVideo) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.popularVideos,
          sectionType: DashboardCategoryType.video,
          data: dashboard.popularVideoList?.data ?? [],
          showViewAll: true
        ),
        index: 12,
      );
    }

    if (isLoggedIn.value) {
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.basedOnYourPreviousWatch,
          sectionType: DashboardCategoryType.personalised,
          data: dashboard.basedOnLastWatchMovieList,
        ),
        index: 13,
      );

      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.mostLiked,
          sectionType: DashboardCategoryType.personalised,
          data: dashboard.likeMovieList,
          showViewAll: true,
          isEachWordCapitalized: false,
        ),
        index: 14,
      );

      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.mostViewed,
          sectionType: DashboardCategoryType.personalised,
          data: dashboard.viewedMovieList,
        ),
        index: 15,
      );
    }

    // 🔥 Trending
    await setJsonToLocal(
      SharedPreferenceConst.POPULAR_MOVIE,
      ListResponse(
        data: dashboard.trendingMovieList,
        name: locale.value.trendingMovies,
      ).toJson(),
    );

    if (isLoggedIn.value) {
      // Trending in your country
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.trendingInYourCountry,
          sectionType: DashboardCategoryType.personalised,
          data: dashboard.trendingInCountryMovieList,
          showViewAll: true,
        ),
        index: 16,
      );

      // Favorite genres
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.favoriteGenres,
          sectionType: DashboardCategoryType.genres,
          data: dashboard.favGenreList,
        ),
        index: 17,
      );

      // Favorite personalities
      addOrReplaceSection(
        targetList: dashboardSectionList,
        newSection: CategoryListModel(
          name: locale.value.yourFavoritePersonalities,
          sectionType: DashboardCategoryType.personality,
          data: dashboard.favActorList,
          showViewAll: false,
        ),
        index: 18,
      );

      dashboardSectionList.removeWhere((element) => element.isOtherSection);

      for (final section in dashboard.otherSection) {
        addOrReplaceSection(
          targetList: dashboardSectionList,
          skipIfEmpty: true,
          newSection: CategoryListModel(
            name: section.name,
            sectionType: 'other_section_${section.slug}',
            data: section.data,
            showViewAll: true,
            isOtherSection: true,
            slug: section.slug,
            type: section.type,
          ),
          index: dashboardSectionList.length + 1,
        );
      }

      if (appConfigs.value.enableAds.getBoolInt()) {
        addOrReplaceSection(
          targetList: dashboardSectionList,
          newSection: CategoryListModel(
            sectionType: DashboardCategoryType.advertisement,
            data: [],
          ),
          index: dashboardSectionList.length + 1,
        );
      }
    }
  }
  ///Add or Replace Section
  /// Replaces only if both sectionType AND name match (to allow multiple sections with same type but different names)
  void addOrReplaceSection({
    required List<CategoryListModel> targetList,
    required CategoryListModel newSection,
    required int index,
    bool skipIfEmpty = false,
  }) {
    targetList.add(newSection);
  }

  Future<void> getAppConfigurations(bool forceSync) async {
    if (forceSync) AuthServiceApis.getAppConfigurations(forceSync: forceSync);
  }
}
