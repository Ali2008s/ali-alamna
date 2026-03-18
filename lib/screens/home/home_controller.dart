import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/screens/slider/slider_controller.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../main.dart';
import '../../network/auth_apis.dart';
import '../../utils/app_common.dart';
import '../../screens/home/firebase/firebase_api.dart';
import 'package:http/http.dart' as http;

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
    cachedDashboardDetailResponse = null; // Clear old cache to avoid showing movies
    getAppConfigurations(forceConfigSync);

    checkApiCallIsWithinTimeSpan(
      forceSync: true, // Force to ensure news/channels load
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

  Future<void> getDashboardDetail({bool showLoader = false}) async {
    showCategoryShimmer(showLoader);
    dashboardSectionList.clear();

    // Clear slider to get rid of movies immediately
    sliderController.listContent.clear();

    try {
      await fetchNewsForSlider();

      List<CategoryListModel> firebaseSections = await FirebaseChannelApi.getFirebaseChannels();
      if (firebaseSections.isNotEmpty) {
        dashboardSectionList.addAll(firebaseSections);
      }
      
      // Update the main future to trigger SnapHelperWidget onSuccess
      dashboardDetailsFuture.value = Future.value(DashboardDetailResponse(
        status: true,
        data: DashboardModel(isEnableBanner: true),
      ));
    } catch (e) {
       log('getDashboardDetail error: $e');
       dashboardDetailsFuture.value = Future.error(e.toString());
    } finally {
      showCategoryShimmer(false);
    }
  }

  Future<void> fetchNewsForSlider() async {
    bool success = false;
    // Try multiple sports RSS feeds
    final List<String> sportsFeedUrls = [
      'https://api.rss2json.com/v1/api.json?rss_url=https://www.skysports.com/rss/0,20514,11661,00.xml',
      'https://api.rss2json.com/v1/api.json?rss_url=http://feeds.bbci.co.uk/sport/rss.xml',
      'https://api.rss2json.com/v1/api.json?rss_url=https://www.goal.com/feeds/ar/news',
      'https://api.rss2json.com/v1/api.json?rss_url=http://feeds.bbci.co.uk/arabic/rss.xml',
    ];

    for (final feedUrl in sportsFeedUrls) {
      if (success) break;
      try {
        final response = await http.get(Uri.parse(feedUrl)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final items = data['items'] as List;
          List<PosterDataModel> news = [];
          for (var item in items) {
            final title = item['title'] ?? '';
            final imageUrl = item['thumbnail'] ?? item['enclosure']?['link'] ?? '';
            if (title.isEmpty) continue;

            final contentModel = ContentData(
              id: 0,
              name: title,
              thumbnailImage: imageUrl,
              type: 'video',
              description: item['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? title,
            );
            news.add(PosterDataModel(details: contentModel, posterImage: imageUrl));
          }
          if (news.isNotEmpty) {
            sliderController.listContent.assignAll(news);
            sliderController.currentSliderPage(news.first);
            currentSliderPage(news.first);
            success = true;
            break;
          }
        }
      } catch (e) {
        log('RSS feed error ($feedUrl): $e');
      }
    }

    if (!success) {
      // Sports fallback items
      final List<Map<String, String>> fallbackItems = [
        {
          'title': '⚽ أحدث أخبار كرة القدم',
          'image': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=1200',
          'desc': 'تابع آخر أخبار دوريات العالم والمباريات المباشرة',
        },
        {
          'title': '🏆 دوري أبطال أوروبا',
          'image': 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=1200',
          'desc': 'نتائج وتحليلات دوري أبطال أوروبا',
        },
        {
          'title': '🔴 المباريات المباشرة',
          'image': 'https://images.unsplash.com/photo-1540655037529-dec987208707?w=1200',
          'desc': 'شاهد المباريات المباشرة الآن',
        },
      ];

      final fallbackNews = fallbackItems.map((item) {
        final contentModel = ContentData(
          id: 0,
          name: item['title']!,
          thumbnailImage: item['image']!,
          type: 'video',
          description: item['desc']!,
        );
        return PosterDataModel(details: contentModel, posterImage: item['image']!);
      }).toList();

      sliderController.listContent.assignAll(fallbackNews);
      sliderController.currentSliderPage(sliderController.listContent.first);
      currentSliderPage(sliderController.listContent.first);
    }
  }

  /// GET Other Dashboard Data Details
  Future<void> getOtherDashboardDetails({bool showLoader = false}) async {
    // Disabled logic for movies
  }

  ///GET Category Sections Data (Disabled)
  Future<void> createCategorySections(DashboardModel dashboard, {bool isFirstPage = true}) async {
    // Disabled movies logic
  }

  DashboardModel removeNotEnableModuleSections(DashboardModel dashboard) {
    return dashboard;
  }

  void createDashboardFirstSectionList(DashboardModel dashboard) {
    // Disabled
  }

  Future<void> createDashboardOtherSectionList(DashboardModel dashboard) async {
    // Disabled
  }
  ///Add or Replace Section
  /// Replaces only if both sectionType AND name match (to allow multiple sections with same type but different names)
  void addOrReplaceSection({
    required List<CategoryListModel> targetList,
    required CategoryListModel newSection,
    required int index,
    bool skipIfEmpty = false,
  }) {
    if (skipIfEmpty && newSection.data.isEmpty) return;

    final existingIndex = targetList.indexWhere((element) => element.sectionType == newSection.sectionType && element.name == newSection.name);

    if (existingIndex != -1) {
      targetList[existingIndex] = newSection;
    } else {
      if (index >= 0 && index < targetList.length) {
        targetList.insert(index, newSection);
      } else {
        targetList.add(newSection);
      }
    }
  }

  Future<void> getAppConfigurations(bool forceSync) async {
    if (forceSync) AuthServiceApis.getAppConfigurations(forceSync: forceSync);
  }
}
