import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../network/core_api.dart';
import '../../screens/dashboard/dashboard_controller.dart';
import '../../screens/home/home_controller.dart';
import '../../screens/home/model/dashboard_res_model.dart';
import '../../utils/common_base.dart';
import 'genres_details/genres_details_controller.dart';
import 'genres_details/genres_details_screen.dart';
import 'model/genres_model.dart';

class GenresController extends GetxController {
  // For GenresListScreen
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;

  Rx<Future<RxList<GenreModel>>> getOriginalGenresFuture = Future(() => RxList<GenreModel>()).obs;
  RxList<GenreModel> originalGenresList = RxList();

  // For GenreComponent on home screen
  CategoryListModel? genresDetails;
  bool isFirstCategory = false;
  late final ScrollController? listController;
  late final FocusNode? firstItemFocusNode;
  bool hasRegistered = false;

  @override
  void onInit() {
    if (genresDetails == null) {
      // Only call getGenresDetails if used for GenresListScreen
      getGenresDetails();
    } else {
      // Initialize for GenreComponent
      _initializeFocusNodes();
      _registerWithHomeController();
    }
    super.onInit();
  }

  // Constructor for GenresListScreen
  GenresController() : super();

  // Constructor for GenreComponent
  GenresController.forComponent({required this.genresDetails, this.isFirstCategory = false});

  void _initializeFocusNodes() {
    if (genresDetails != null) {
      listController = ScrollController();
      firstItemFocusNode = FocusNode(debugLabel: '${genresDetails!.name}_first_item');
    }
  }

  void _registerWithHomeController() {
    if (genresDetails == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasRegistered && genresDetails!.data.isNotEmpty) {
        hasRegistered = true;
        try {
          final HomeController homeController = Get.find<HomeController>();
          homeController.registerCategoryFocusNode(
            genresDetails!.name,
            firstItemFocusNode!,
            listController!,
          );
          if (isFirstCategory && homeController.firstCategoryFocusNode == null) {
            homeController.firstCategoryFocusNode = firstItemFocusNode;
            log('Registered GenreComponent as first category focus node');
          }
        } catch (e) {
          log('Error registering GenreComponent focus node: $e');
        }
      }
    });
  }

  void onFocusChange(bool value) {
    if (value && firstItemFocusNode != null) {
      try {
        firstItemFocusNode!.requestFocus();
      } catch (e) {
        log('firstItemFocusNode requestFocus error: $e');
      }
    }
  }

  /// Handle navigation and scrolling when focus changes on a genre card
  void onGenreCardFocusChange(bool value, BuildContext context, String categoryName, int index, GlobalKey categoryKey) {
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

    if (value && listController!.position.maxScrollExtent >= (listController!.offset + 70)) {
      listController!.animateTo(index * (Get.width / 4.7), duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  /// Handle key events for genre card navigation
  KeyEventResult handleGenreCardKeyEvent(KeyEvent event, int index, String categoryName, GenreModel genre) {
    if (event is KeyDownEvent) {
      // Handle arrow left - navigate to bottom nav items if first item
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index == 0) {
        try {
          final DashboardController controller = Get.find<DashboardController>();
          controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
        } catch (_) {}
        return KeyEventResult.handled;
      }

      // Handle arrow up - navigate to previous category or slider
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
          log('Error handling arrow up in GenresCard: $e');
        }
        return KeyEventResult.handled;
      }

      // Handle select/enter - navigate to genre details screen
      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        navigateToGenreDetails(genre);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Navigate to genre details screen
  void navigateToGenreDetails(GenreModel genre) {
    GenresDetailsController genDetCont = Get.put(GenresDetailsController());
    genDetCont.genresId(genre.id);
    genDetCont.getGenresDetails();
    Get.to(() => GenresDetailsScreen(generDetails: genre));
  }

  ///Get GenresDetails List
  Future<void> getGenresDetails({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }
    await getOriginalGenresFuture(
      CoreServiceApis.getGenresList(
        page: page.value,
        getGenresList: originalGenresList,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {}).catchError((e) {
      log("getGenres List Err : $e");
    }).whenComplete(() => isLoading(false));
  }

  @override
  void onClose() {
    if (firstItemFocusNode != null) {
      firstItemFocusNode!.dispose();
    }
    if (listController != null) {
      listController!.dispose();
    }
    super.onClose();
  }
}
