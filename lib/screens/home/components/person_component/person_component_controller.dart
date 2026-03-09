import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/screens/person/model/person_model.dart';
import 'package:streamit_laravel/screens/person/person_controller.dart';
import 'package:streamit_laravel/screens/person/person_detail_screen.dart';

class PersonComponentController extends GetxController {
  final CategoryListModel personDetails;
  final bool isFirstCategory;

  late final ScrollController listController;
  late final FocusNode firstItemFocusNode;
  bool hasRegistered = false;
  bool _isDisposed = false;

  // Map to track focus state for each card
  final Map<int, RxBool> itemFocusStates = {};
  final Map<int, FocusNode> itemFocusNodes = {};
  final Map<int, GlobalKey> itemKeys = {};

  PersonComponentController({
    required this.personDetails,
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
    firstItemFocusNode = FocusNode(debugLabel: '${personDetails.name}_first_item');
    itemFocusNodes[0] = firstItemFocusNode;
  }

  void _registerWithHomeController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasRegistered && personDetails.data.isNotEmpty && !_isDisposed) {
        hasRegistered = true;
        try {
          final HomeController homeController = Get.find<HomeController>();
          homeController.registerCategoryFocusNode(
            personDetails.name,
            firstItemFocusNode,
            listController,
          );
          if (isFirstCategory && homeController.firstCategoryFocusNode == null) {
            homeController.firstCategoryFocusNode = firstItemFocusNode;
            log('Registered PersonComponent as first category focus node');
          }
        } catch (e) {
          log('Error registering PersonComponent focus node: $e');
        }
      }
    });
  }

  void onCategoryFocusChange(bool value) {
    if (value && !_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (listController.hasClients) {
          listController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_isDisposed) return;
          if (firstItemFocusNode.canRequestFocus) {
            firstItemFocusNode.requestFocus();
          }
        });
      });
    }
  }

  void onFocusChange(int index, bool value) {
    if (!itemFocusStates.containsKey(index)) {
      itemFocusStates[index] = false.obs;
    }
    itemFocusStates[index]?.value = value;

    if (value && !_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _scrollToIndex(index);
      });
    }
  }

  FocusNode getItemFocusNode(int index) {
    if (_isDisposed) return firstItemFocusNode;

    if (index == 0) return firstItemFocusNode;

    return itemFocusNodes.putIfAbsent(
      index,
      () => FocusNode(debugLabel: '${personDetails.name}_item_$index'),
    );
  }

  GlobalKey getItemKey(int index) {
    if (_isDisposed) return GlobalKey();

    return itemKeys.putIfAbsent(index, () => GlobalKey(debugLabel: '${personDetails.name}_key_$index'));
  }

  void _scrollToIndex(
    int index, {
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
    double alignment = 0.5,
  }) {
    if (_isDisposed) return;

    final key = itemKeys[index];

    if (key?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: alignment,
          alignmentPolicy: alignmentPolicy,
        );
        return;
      } catch (e) {
        log('Scrollable ensure visible error: $e');
      }
    }

    if (listController.hasClients) {
      try {
        const double estimatedItemExtent = 140.0;
        listController.animateTo(
          index * estimatedItemExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        log('animateTo error: $e');
      }
    }
  }

  // Handle arrow left navigation
  KeyEventResult handleArrowLeft(int index, KeyEvent event) {
    if (_isDisposed) return KeyEventResult.ignored;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) {
        final previousNode = getItemFocusNode(index - 1);
        if (previousNode.canRequestFocus) {
          previousNode.requestFocus();
        }
        _scrollToIndex(
          index - 1,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          alignment: 0.0,
        );
        return KeyEventResult.handled;
      }

      try {
        final DashboardController controller = Get.find<DashboardController>();
        controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
        return KeyEventResult.handled;
      } catch (_) {}
    }
    return KeyEventResult.ignored;
  }

  // Handle arrow right navigation
  KeyEventResult handleArrowRight(int index, int totalItems, KeyEvent event) {
    if (_isDisposed) return KeyEventResult.ignored;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (totalItems <= 0) return KeyEventResult.handled;

      final nextIndex = index + 1;
      if (nextIndex < totalItems) {
        final nextNode = getItemFocusNode(nextIndex);
        if (nextNode.canRequestFocus) {
          nextNode.requestFocus();
        }
        _scrollToIndex(
          nextIndex,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          alignment: 1.0,
        );
      } else {
        _scrollToIndex(
          index,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          alignment: 1.0,
        );
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // Handle arrow up navigation
  KeyEventResult handleArrowUp(KeyEvent event, String? categoryName) {
    if (_isDisposed) return KeyEventResult.ignored;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
      try {
        final HomeController homeController = Get.find<HomeController>();
        final categoryNames = List<String>.from(homeController.categoryFocusNodes.keys);
        final currentIndex = categoryNames.indexOf(categoryName ?? '');
        
        if (currentIndex > 0) {
          // There's a previous category, navigate to it
          homeController.navigateToPreviousCategory(categoryName ?? '');
        } else {
          // No previous category, move focus to slider
          homeController.sliderFocus.requestFocus();
        }
        return KeyEventResult.handled;
      } catch (e) {
        log('Error handling arrow up in PersonComponentController: $e');
      }
    }
    return KeyEventResult.ignored;
  }

  // Handle select key to open person details
  KeyEventResult handleSelect(CastResponse personDet, KeyEvent event) {
    if (_isDisposed) return KeyEventResult.ignored;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
      openPersonDetails(personDet);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Handle tap/click to open person details
  void openPersonDetails(CastResponse personDet) {
    final PersonController personCont = Get.put(PersonController());
    personCont.isUiLoaded = false;
    personCont.actorId(personDet.data.first.id);
    personCont.getPersonMovieDetails();
    Get.to(
      () => PersonDetailScreen(personDet: personDet, isHomeScreen: true),
    );
  }

  RxBool getFocusState(int index) {
    if (!itemFocusStates.containsKey(index)) {
      itemFocusStates[index] = false.obs;
    }
    return itemFocusStates[index]!;
  }

  // Check if an item has focus
  bool hasFocus(int index) {
    return itemFocusStates[index]?.value ?? false;
  }

  @override
  void onClose() {
    _isDisposed = true;

    try {
      firstItemFocusNode.dispose();
      itemFocusNodes.forEach((key, node) {
        if (key != 0) {
          node.dispose();
        }
      });
      listController.dispose();
    } catch (e) {
      log('Dispose error: $e');
    }

    // Dispose all focus state observables
    for (var state in itemFocusStates.values) {
      state.close();
    }
    itemFocusStates.clear();
    itemFocusNodes.clear();
    itemKeys.clear();
    super.onClose();
  }
}
