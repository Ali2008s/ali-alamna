import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/content/content_list_screen.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/utils/common_base.dart';

class LanguageComponentController extends GetxController {
  final CategoryListModel languageDetails;
  final bool isFirstCategory;

  late final ScrollController listController;
  late final FocusNode firstItemFocusNode;
  bool hasRegistered = false;

  LanguageComponentController({
    required this.languageDetails,
    this.isFirstCategory = false,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeFocusNodes();
    _registerWithHomeController();
  }

  void _initializeFocusNodes() {
    listController = ScrollController();
    firstItemFocusNode = FocusNode(debugLabel: '${languageDetails.name}_first_item');
  }

  void _registerWithHomeController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasRegistered && languageDetails.data.isNotEmpty) {
        hasRegistered = true;
        try {
          final HomeController homeController = Get.find<HomeController>();
          homeController.registerCategoryFocusNode(
            languageDetails.name,
            firstItemFocusNode,
            listController,
          );
          if (isFirstCategory && homeController.firstCategoryFocusNode == null) {
            homeController.firstCategoryFocusNode = firstItemFocusNode;
            log('Registered LanguageComponent as first category focus node');
            // Explicitly request focus on the first item
            Future.delayed(const Duration(milliseconds: 100), () {
              firstItemFocusNode.requestFocus();
            });
          }
        } catch (e) {
          log('Error registering LanguageComponent focus node: $e');
        }
      }
    });
  }

  void onFocusChange(bool value) {
    if (value) {
      try {
        firstItemFocusNode.requestFocus();
      } catch (e) {
        log('firstItemFocusNode requestFocus error: $e');
      }
    }
  }

  /// Handle navigation and scrolling when focus changes on a language card
  void onLanguageCardFocusChange(bool value, BuildContext context, String categoryName, int index, GlobalKey categoryKey) {
    if (value && categoryKey.currentContext != null) {
      final HomeController hCont = getOrPutController(() => HomeController());
      try {
        if (hCont.homeScrollController.position.maxScrollExtent >= (hCont.homeScrollController.offset + 7)) {
          Scrollable.ensureVisible(categoryKey.currentContext!, duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      } catch (e) {
        log('homeScrollController.hasClients ${hCont.homeScrollController.hasClients}');
      }
    }

    if (value && listController.position.maxScrollExtent >= (listController.offset + 70)) {
      listController.animateTo(index * (Get.width / 4.7), duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  /// Handle key events for language card navigation
  KeyEventResult handleLanguageCardKeyEvent(KeyEvent event, int index, String categoryName, LanguageModel language) {
    if (event is KeyDownEvent) {
      /// Handle arrow left - navigate to bottom nav items if first item
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index == 0) {
        try {
          final DashboardController controller = Get.find<DashboardController>();
          controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
        } catch (_) {}
        return KeyEventResult.handled;
      }

      /// Handle arrow up - navigate to previous category or slider
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        try {
          final HomeController homeController = Get.find<HomeController>();
          final categoryNames = List<String>.from(homeController.categoryFocusNodes.keys);
          final currentIndex = categoryNames.indexOf(categoryName);

          if (currentIndex > 0) {
            // There's a previous category, navigate to it
            homeController.navigateToPreviousCategory(categoryName);
          } else {
            // No previous category, move focus to slider
            homeController.sliderFocus.requestFocus();
          }
        } catch (e) {
          log('Error handling arrow up in LanguageItemWidget: $e');
        }
        return KeyEventResult.handled;
      }

      /// Handle select/enter - navigate to content list screen
      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        navigateToContentList(language);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Navigate to content list screen
  void navigateToContentList(LanguageModel language) {
    Get.to(() => ContentListScreen(title: language.name), arguments: language.name);
  }

  @override
  void onClose() {
    firstItemFocusNode.dispose();
    listController.dispose();
    super.onClose();
  }
}

