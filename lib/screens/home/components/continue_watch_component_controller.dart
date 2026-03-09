import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';

class ContinueWatchComponentController extends GetxController {
  final bool isFirstCategory;

  late final ScrollController listController;
  bool hasRegistered = false;
  FocusNode? firstItemFocusNode;

  ContinueWatchComponentController({
    this.isFirstCategory = false,
  });

  @override
  void onInit() {
    super.onInit();
    listController = ScrollController();
  }

  void registerFirstFocusNode(FocusNode firstItemFocusNode, String categoryName) {
    this.firstItemFocusNode = firstItemFocusNode;

    /// Add listener to first item focus node to scroll when it gains focus
    focusNodeListener() {
      if (firstItemFocusNode.hasFocus) {
        FocusSoundService.play();
        _scrollToContinueWatching();
      }
    }

    firstItemFocusNode.addListener(focusNodeListener);

    /// This ensures navigation works from other categories
    if (!hasRegistered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasRegistered) {
          hasRegistered = true;
          final HomeController homeController = Get.find<HomeController>();
          homeController.registerCategoryFocusNode(categoryName, firstItemFocusNode, listController);

          /// Only set firstCategoryFocusNode if this is the first category and it's not already set
          if (isFirstCategory && homeController.firstCategoryFocusNode == null) {
            homeController.firstCategoryFocusNode = firstItemFocusNode;
          }
        }
      });
    }
  }

  void _scrollToContinueWatching() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        final HomeController homeController = Get.find<HomeController>();
        if (homeController.continueWatchingKey.currentContext != null) {
          if (homeController.homeScrollController.hasClients) {
            Scrollable.ensureVisible(homeController.continueWatchingKey.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
          }
        }
      });
    });
  }

  void onFocusChange(bool value) {
    if (value && firstItemFocusNode != null) {
      FocusSoundService.play();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        /// Scroll horizontal list to start
        if (listController.hasClients) {
          listController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }

        /// Scroll to Continue Watching component in main scroll view
        Future.delayed(const Duration(milliseconds: 100), () {
          final HomeController homeController = Get.find<HomeController>();
          if (homeController.continueWatchingKey.currentContext != null) {
            if (homeController.homeScrollController.hasClients) {
              Scrollable.ensureVisible(homeController.continueWatchingKey.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
            }
          }
        });

        /// Request focus on first item
        Future.delayed(const Duration(milliseconds: 200), () {
          if (firstItemFocusNode != null && firstItemFocusNode!.canRequestFocus) {
            firstItemFocusNode!.requestFocus();
          }
        });
      });
    }
  }

  @override
  void onClose() {
    listController.dispose();
    super.onClose();
  }
}
