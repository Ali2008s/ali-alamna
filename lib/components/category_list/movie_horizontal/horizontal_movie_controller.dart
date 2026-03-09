import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/common_base.dart';

class HorizontalMovieController extends GetxController {
  final CategoryListModel movieDet;
  final bool isFirstCategory;
  final bool isTopChannel;
  final bool isTop10;

  late final ScrollController listController;
  late final FocusNode firstItemFocusNode;
  final List<FocusNode> itemFocusNodes = [];
  final RxBool isUiLoaded = false.obs;

  bool _isDisposed = false;

  HorizontalMovieController({
    required this.movieDet,
    this.isFirstCategory = false,
    this.isTopChannel = false,
    this.isTop10 = false,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeFocusNodes();
    _registerWithHomeController();
  }

  void _initializeFocusNodes() {
    listController = ScrollController();
    firstItemFocusNode = FocusNode(debugLabel: '${movieDet.name}_first_item');
  }

  void _registerWithHomeController() {
    /// Register this category with the home controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || _isDisposed) return;
      try {
        final HomeController homeController = Get.find<HomeController>();
        homeController.registerCategoryFocusNode(movieDet.name, firstItemFocusNode, listController);

        /// Register the focus node with home controller if this is the first category
        /// Only set it if it hasn't been set already (to avoid second category list overwriting the first one)
        if (isFirstCategory && homeController.firstCategoryFocusNode == null) {
          homeController.firstCategoryFocusNode = firstItemFocusNode;
          log('Registered first category focus node: ${movieDet.name}');
        } else if (isFirstCategory) {
          log('First category already set to: ${homeController.firstCategoryFocusNode?.debugLabel}, not overwriting with: ${movieDet.name}');
        }
      } catch (e) {
        log('Error registering category focus node: $e');
      }
    });
  }

  void onFocusChange(bool value) {
    if (value && !_isDisposed) {
      try {
        firstItemFocusNode.requestFocus();
      } catch (e) {
        log('firstItemFocusNode requestFocus error: $e');
      }
    }
  }

  void onItemFocusChange(bool value, GlobalKey categoryKey) {
    if (_isDisposed) return;
    if (!isUiLoaded.value && isTop10) {
      isUiLoaded(true);
    } else if (value && categoryKey.currentContext != null) {
      HomeController hCont = getOrPutController(() => HomeController());
      try {
        if (!hCont.homeScrollController.hasClients) return;
        Scrollable.ensureVisible(
          categoryKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        log('homeScrollController.hasClients ${hCont.homeScrollController.hasClients}');
      }
    }
    if (value) {
    FocusSoundService.play();
  
    }
  }

  void onArrowUp() {
    if (_isDisposed) return;

    final HomeController homeController = Get.find<HomeController>();

    /// Use dashboardSectionList order to ensure correct navigation order
    final categoryNames = homeController.dashboardSectionList.where((category) => homeController.categoryFocusNodes.containsKey(category.name)).map((category) => category.name).toList();

    /// Check for Continue Watching specifically
    final continueWatchingInList = homeController.dashboardSectionList.where((category) => category.sectionType == DashboardCategoryType.continueWatching).toList();
    if (continueWatchingInList.isNotEmpty) {
      final continueWatchingName = continueWatchingInList.first.name;
      if (homeController.categoryFocusNodes.containsKey(continueWatchingName)) {}
    }

    final currentIndex = categoryNames.indexOf(movieDet.name);

    if (currentIndex > 0) {
      homeController.navigateToPreviousCategory(movieDet.name);
    } else if (currentIndex == 0) {
      homeController.sliderFocus.requestFocus();

      /// Ensure slider is visible in scroll view
      if (homeController.sliderKey.currentContext != null) {
        if (homeController.homeScrollController.hasClients) {
          Scrollable.ensureVisible(
            homeController.sliderKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    } else {
      final continueWatchingCategory = homeController.dashboardSectionList.firstWhereOrNull((category) => category.sectionType == DashboardCategoryType.continueWatching);

      if (continueWatchingCategory != null) {
        if (homeController.categoryFocusNodes.containsKey(continueWatchingCategory.name)) {
          /// Continue Watching exists and is registered, navigate to it
          final continueWatchingFocusNode = homeController.categoryFocusNodes[continueWatchingCategory.name];
          if (continueWatchingFocusNode != null) {
            continueWatchingFocusNode.requestFocus();

            /// Scroll to Continue Watching component
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (homeController.continueWatchingKey.currentContext != null && homeController.homeScrollController.hasClients) {
                  Scrollable.ensureVisible(
                    homeController.continueWatchingKey.currentContext!,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              });
            });

            return;
          }
        }
      }

      /// Fallback: try to navigate to slider
      homeController.sliderFocus.requestFocus();
    }
  }

  void onArrowDown() {
    if (_isDisposed) return;
    try {
      final HomeController homeController = Get.find<HomeController>();
      homeController.navigateToNextCategory(movieDet.name);
    } catch (e) {
      log('Error navigating to next category: $e');
    }
  }

  void onArrowRight(int index) {
    if (_isDisposed) return;
    if (index < (isTopChannel ? movieDet.data.take(10).length - 1 : movieDet.data.length - 1)) {
      if (index + 1 < itemFocusNodes.length) {
        itemFocusNodes[index + 1].requestFocus();

        /// Scroll to next item safely
        if (!_isDisposed && listController.hasClients) {
          try {
            listController.animateTo(
              (index + 1) * (Get.width / 4),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          } catch (e) {
            log('animateTo error: $e');
          }
        }
      }
    }
  }

  void onArrowLeft(int index) {
    if (_isDisposed) return;

    if (index > 0) {
      /// Move focus to previous item
      if (index == 1) {
        firstItemFocusNode.requestFocus();

        /// Scroll to make first item visible

        if (!_isDisposed && listController.hasClients) {
          try {
            listController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
          } catch (e) {
            log('animateTo left error: $e');
          }
        }
      } else if (index - 1 < itemFocusNodes.length) {
        itemFocusNodes[index - 1].requestFocus();

        /// Scroll to make the previous item visible

        if (!_isDisposed && listController.hasClients) {
          try {
            listController.animateTo(
              (index - 1) * (Get.width / 4),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          } catch (e) {
            log('animateTo left error: $e');
          }
        }
      }
    } else if (index == 0) {
      try {
        final DashboardController controller = Get.find<DashboardController>();
        controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
      } catch (e) {
        log('Error moving focus to bottom navigation: $e');
      }
    }
  }

  FocusNode getItemFocusNode(int index) {
    /// Ensure we have enough focus nodes
    while (itemFocusNodes.length <= index) {
      itemFocusNodes.add(FocusNode(debugLabel: '${movieDet.name}_item_$index'));
    }
    return index == 0 ? firstItemFocusNode : itemFocusNodes[index];
  }

  bool isLastIndex(int index) {
    return index == (isTopChannel ? movieDet.data.take(10).length - 1 : movieDet.data.length - 1);
  }

  @override
  void onClose() {
    _isDisposed = true;

    try {
      if (listController.hasClients) {
        listController.jumpTo(listController.offset);
      }
    } catch (e) {
      log('jumpTo error before dispose: $e');
    }

    try {
      firstItemFocusNode.dispose();
      for (var focusNode in itemFocusNodes) {
        focusNode.dispose();
      }
      listController.dispose();
    } catch (e) {
      log('Dispose error: $e');
    }

    super.onClose();
  }
}
