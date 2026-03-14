// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/coming_soon/coming_soon_screen.dart';
import 'package:streamit_laravel/screens/content/content_list_controller.dart';
import 'package:streamit_laravel/screens/content/content_list_screen.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_screen.dart';
import 'package:streamit_laravel/screens/profile/profile_controller.dart';
import 'package:streamit_laravel/screens/profile/profile_screen.dart';
import 'package:streamit_laravel/screens/search/search_screen.dart';

import '../../main.dart';
import '../../network/auth_apis.dart';
import '../../network/core_api.dart';
import '../../utils/app_common.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';
import '../../utils/local_storage.dart' as storage;
import '../../video_players/model/vast_ad_response.dart';
import '../auth/sign_in/sign_in_screen.dart';
import '../home/home_screen.dart';

import '../search/search_controller.dart';
import '../unlocked_video/rented_list_screen.dart';
import 'components/menu.dart';

class DashboardController extends GetxController {
  RxBool isDrawerExpanded = false.obs;

  RxBool isFocusMovedToProfile = false.obs;
  RxBool isFirstItemInProfileFocused = false.obs;
  RxBool isInternalFocusChange = false.obs;
  RxBool isNavigatingToContentBanner = false.obs;

  //Manage current screen
  RxList<BottomBarItem> bottomNavItems = [
    BottomBarItem(
        title: () => locale.value.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        type: BottomItem.home,
        focusNode: FocusNode(),
        screen: SizedBox()),
    BottomBarItem(
        title: () => locale.value.search,
        icon: Icons.search_rounded,
        activeIcon: Icons.search_rounded,
        type: BottomItem.search,
        focusNode: FocusNode(),
        screen: SizedBox()),
    if (appConfigs.value.enableMovie)
      BottomBarItem(
          title: () => locale.value.movies,
          icon: Icons.movie_creation_outlined,
          activeIcon: Icons.movie_creation,
          type: BottomItem.movies,
          focusNode: FocusNode(),
          screen: SizedBox()),
    if (appConfigs.value.enableTvShow)
      BottomBarItem(
          title: () => locale.value.tVShows,
          icon: Icons.tv,
          activeIcon: Icons.tv,
          type: BottomItem.tvShows,
          focusNode: FocusNode(),
          screen: SizedBox()),
    if (appConfigs.value.enableVideo)
      BottomBarItem(
          title: () => locale.value.videos,
          icon: Icons.videocam_outlined,
          activeIcon: Icons.videocam_outlined,
          type: BottomItem.videos,
          focusNode: FocusNode(),
          screen: SizedBox()),
    BottomBarItem(
        title: () => locale.value.comingSoon,
        icon: Icons.campaign_outlined,
        activeIcon: Icons.campaign,
        type: BottomItem.comingsoon,
        focusNode: FocusNode(),
        screen: SizedBox()),
    if (isLoggedIn.value)
      BottomBarItem(
          title: () => locale.value.unlockedVideo,
          icon: Icons.lock_outline,
          activeIcon: Icons.lock_open_rounded,
          type: BottomItem.unlockedVideo,
          focusNode: FocusNode(),
          screen: SizedBox()),
    if (appConfigs.value.enableLiveTv)
      BottomBarItem(
          title: () => locale.value.liveTv,
          icon: Icons.live_tv_outlined,
          activeIcon: Icons.live_tv,
          type: BottomItem.livetv,
          focusNode: FocusNode(),
          screen: SizedBox()),

    BottomBarItem(
        title: () => locale.value.profile,
        icon: Icons.account_circle_outlined,
        activeIcon: Icons.account_circle_rounded,
        type: BottomItem.profile,
        focusNode: FocusNode(),
        screen: SizedBox()),
  ].obs;

  RxInt selectedBottomNavIndex = 0.obs;

  RxList<VastAd> vastAds = <VastAd>[].obs;

  @override
  void onInit() {
    getAppConfigurations();
    onBottomTabChange(BottomItem.home);
    super.onInit();
  }

  /// Navigate focus to the first profile component in Profile screen
  void navigateToFirstProfileComponent() {
    try {
      final ProfileController profileController = Get.find<ProfileController>();
      profileController.requestFocusOnFirstProfileComponent();

      Future.delayed(Duration(milliseconds: 100), () {
        try {
          // Allow ProfileScreen focus management to proceed if necessary
        } catch (e) {
          // Ignore if not available
        }
      });
    } catch (e) {
      // ProfileController not found, ignore
    }
  }

  /// Navigate focus to the content banner (slider) of the current content screen
  void navigateToContentBanner() {
    isNavigatingToContentBanner.value = true;

    String? contentType;
    final currentItem = bottomNavItems[selectedBottomNavIndex.value];

    if (currentItem.type == BottomItem.movies) {
      contentType = VideoType.movie;
    } else if (currentItem.type == BottomItem.tvShows) {
      contentType = VideoType.tvshow;
    } else if (currentItem.type == BottomItem.videos) {
      contentType = VideoType.video;
    }

    if (contentType == null) {
      isNavigatingToContentBanner.value = false;
      return;
    }

    final String controllerTag = 'content_list_controller_$contentType';
    final isRegistered = Get.isRegistered<ContentListController>(tag: controllerTag);

    if (isRegistered) {
      final contentListController = Get.find<ContentListController>(tag: controllerTag);

      if (contentListController.sliderController.bannerList.isNotEmpty) {
        contentListController.sliderController.sliderFocus.requestFocus();
        Future.delayed(Duration(milliseconds: 100), () {
          isNavigatingToContentBanner.value = false;
        });
        return;
      } else if (contentListController.originalContentList.isNotEmpty) {
        _focusOnFirstContentItem(contentListController);
        return;
      } else {
        isNavigatingToContentBanner.value = false;
        return;
      }
    }

    /// Use post frame callback to ensure focus request happens after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ContentListController>(tag: controllerTag)) {
        try {
          final contentListController = Get.find<ContentListController>(tag: controllerTag);
          if (contentListController.sliderController.bannerList.isNotEmpty) {
            final canRequest = contentListController.sliderController.sliderFocus.canRequestFocus;
            if (canRequest) {
              contentListController.sliderController.sliderFocus.requestFocus();
            } else {
              Future.delayed(Duration(milliseconds: 50), () {
                contentListController.sliderController.sliderFocus.requestFocus();
              });
            }

            Future.delayed(Duration(milliseconds: 50), () {
              isNavigatingToContentBanner.value = false;
            });
          } else if (contentListController.originalContentList.isNotEmpty) {
            _focusOnFirstContentItem(contentListController);
          } else {
            isNavigatingToContentBanner.value = false;
          }
        } catch (e) {
          isNavigatingToContentBanner.value = false;
        }
      } else {
        Future.delayed(Duration(milliseconds: 100), () {
          if (Get.isRegistered<ContentListController>(tag: controllerTag)) {
            final contentListController = Get.find<ContentListController>(tag: controllerTag);
            if (contentListController.sliderController.bannerList.isNotEmpty) {
              /// Check if the focus node is ready
              final canRequest = contentListController.sliderController.sliderFocus.canRequestFocus;
              if (canRequest) {
                contentListController.sliderController.sliderFocus.requestFocus();
              } else {
                /// If not ready yet, try again after a short delay
                Future.delayed(Duration(milliseconds: 50), () {
                  contentListController.sliderController.sliderFocus.requestFocus();
                });
              }
            } else if (contentListController.originalContentList.isNotEmpty) {
              _focusOnFirstContentItem(contentListController);
            } else {
              isNavigatingToContentBanner.value = false;
            }
          }
          Future.delayed(Duration(milliseconds: 400), () {
            isNavigatingToContentBanner.value = false;
          });
        });
      }
    });
  }

  /// Focus on the first item in the content list when banner is empty
  void _focusOnFirstContentItem(ContentListController contentListController) {
    if (contentListController.originalContentList.isEmpty) {
      isNavigatingToContentBanner.value = false;
      return;
    }

    final firstItem = contentListController.originalContentList.first;
    Timer? timer;
    int attempts = 0;

    Future.microtask(() {
      timer = Timer.periodic(Duration(milliseconds: 16), (t) {
        attempts++;
        try {
          final context = firstItem.itemGlobalKey.currentContext;
          final focusNode = firstItem.itemFocusNode;

          if (context != null && context.mounted && focusNode.canRequestFocus) {
            try {
              if (contentListController.scrollController.hasClients) {
                contentListController.scrollController.jumpTo(0.0);
              }

              focusNode.requestFocus();
              Scrollable.ensureVisible(
                context,
                alignment: 0.0,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );

              Future.delayed(Duration(milliseconds: 50), () {
                if (focusNode.hasFocus) {
                  isNavigatingToContentBanner.value = false;
                  timer?.cancel();
                }
              });

              return;
            } catch (_) {}
          }
        } catch (_) {}

        if (attempts >= 150) {
          isNavigatingToContentBanner.value = false;
          timer?.cancel();
        }
      });
    });
  }

  /// Ensure ContentListController is registered for the given type
  void _ensureContentControllerRegistered(String contentType) {
    final String controllerTag = 'content_list_controller_$contentType';

    if (!Get.isRegistered<ContentListController>(tag: controllerTag)) {
      Get.put(
        ContentListController(initialType: contentType),
        tag: controllerTag,
      );
    }
  }

  Future<void> onBottomTabChange(BottomItem type) async {
    int index = bottomNavItems.indexWhere((item) => item.type == type);

    if (index < 0 || index >= bottomNavItems.length) {
      log('Invalid index: $index');
      return;
    }

    try {
      isFocusMovedToProfile(isLoggedIn.value && type == BottomItem.profile);

      if ((bottomNavItems[selectedBottomNavIndex.value].type == BottomItem.home ||
              bottomNavItems[selectedBottomNavIndex.value].type == BottomItem.movies) &&
          type == BottomItem.search) {
        await handleSearchScreen();
      }
      hideKeyBoardWithoutContext();

      // Add or replace screen based on the tab type
      Widget newScreen;

      switch (type) {
        case BottomItem.home:
          newScreen = HomeScreen();
          break;
        case BottomItem.search:
          newScreen = SearchScreen();
          break;
        case BottomItem.movies:
          newScreen = ContentListScreen(title: locale.value.movies, type: VideoType.movie);
          // Pre-register the controller so it's available for navigation
          _ensureContentControllerRegistered(VideoType.movie);
          break;
        case BottomItem.tvShows:
          newScreen = ContentListScreen(title: locale.value.tVShows, type: VideoType.tvshow);
          // Pre-register the controller so it's available for navigation
          _ensureContentControllerRegistered(VideoType.tvshow);
          break;
        case BottomItem.videos:
          newScreen = ContentListScreen(title: locale.value.videos, type: VideoType.video);
          // Pre-register the controller so it's available for navigation
          _ensureContentControllerRegistered(VideoType.video);
          break;
        case BottomItem.comingsoon:
          newScreen = ComingSoonScreen();
          break;
        case BottomItem.unlockedVideo:
          newScreen = RentedListScreen();
          break;
        case BottomItem.livetv:
          newScreen = LiveTvScreen();
          break;

        case BottomItem.profile:
          newScreen = isLoggedIn.value ? ProfileScreen() : SignInScreen();
          break;
      }

      bottomNavItems[index].screen = newScreen;

      selectedBottomNavIndex(index);
    } catch (e) {
      log('onBottomTabChangeByIndex Err: $e');
    }
  }

  // Method to shrink the drawer
  void shrinkDrawer() {
    isDrawerExpanded.value = false;
  }

  // Method to expand the drawer
  void expandDrawer() {
    isDrawerExpanded.value = true;
  }

  Future<void> handleSearchScreen() async {
    SearchScreenController searchCont = getOrPutController(() => SearchScreenController());
    if (searchCont.searchTextCont.text.isNotEmpty) {
      searchCont.clearSearchField();
    }
  }

  Future<void> getAppConfigurations() async {
    if (!getBoolAsync(SharedPreferenceConst.IS_APP_CONFIGURATION_SYNCED_ONCE, defaultValue: false)) {
      await AuthServiceApis.getAppConfigurations(
              forceSync: !getBoolAsync(SharedPreferenceConst.IS_APP_CONFIGURATION_SYNCED_ONCE, defaultValue: false))
          .then(
        (value) {
          bottomNavItems[selectedBottomNavIndex.value];
        },
      ).onError((error, stackTrace) {
        toast(error.toString());
      });
    }
  }

  Future<void> getActiveVastAds() async {
    try {
      VastAdResponse? res = await CoreServiceApis.getVastAds();
      vastAds.value = res!.data ?? [];
    } catch (e) {
      log('getActiveVastAds Err: $e');
    }
  }

  /// Navigate focus to the search field in Search screen
  void navigateToSearchField() {
    try {
      SearchScreenController searchCont = getOrPutController(() => SearchScreenController());
      // Request focus on the voice icon (search field) when right arrow is pressed
      searchCont.voiceIconFocus.requestFocus();
    } catch (e) {
      // SearchScreenController not found, ignore
    }
  }

  @override
  void onReady() {
    if (Get.context != null) {
      View.of(Get.context!).platformDispatcher.onPlatformBrightnessChanged = () {
        WidgetsBinding.instance.handlePlatformBrightnessChanged();
        try {
          final getThemeFromLocal = storage.getValueFromLocal(SettingsLocalConst.THEME_MODE);
          if (getThemeFromLocal is int) {
            toggleThemeMode(themeId: getThemeFromLocal);
          }
        } catch (e) {
          log('getThemeFromLocal from cache E: $e');
        }
      };
      getActiveVastAds();
    }
    super.onReady();
  }
}
