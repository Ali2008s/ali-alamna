import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/coming_soon/model/coming_soon_response.dart';
import 'package:streamit_laravel/controllers/base_controller.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import '../../network/core_api.dart';
import '../../utils/app_common.dart';
import '../../utils/common_base.dart';
import 'coming_soon_detail_screen.dart';

class ComingSoonController extends BaseListController<ComingSoonModel> {
  List<String> get filterTabs => [
    'all',
    if (appConfigs.value.enableMovie) 'movies',
    if (appConfigs.value.enableTvShow) 'tv shows',
    if (appConfigs.value.enableVideo) 'videos',
  ];

  RxBool isRefresh = false.obs;
  RxBool isFullScreenEnable = false.obs;
  RxInt page = 1.obs;
  RxInt currentSelected = 0.obs;
  late List<FocusNode> focusNodesForTabs;
  FocusNode? trailerButtonFocusNode;
  FocusNode? descriptionFocusNode;
  RxBool isTrailerButtonFocused = false.obs;
  FocusNode? firstGridItemFocusNode;
  late ScrollController scrollController;
  List<FocusNode> gridFocusNodes = [];

  /// Get DashboardController instance
  DashboardController get dashboardController => getDashboardController();

  /// Initialize focus nodes for each tab
  void _initializeFocusNodes() {
    focusNodesForTabs = List.generate(
      filterTabs.length,
      (index) => FocusNode(
        debugLabel: 'Tab_${filterTabs[index]}',
        onKeyEvent: (node, event) => _handleKeyEvent(node, event, index),
      ),
    );
    trailerButtonFocusNode = FocusNode(
      debugLabel: 'TrailerButton',
      onKeyEvent: (node, event) => _handleTrailerButtonKeyEvent(node, event),
    );
    descriptionFocusNode?.dispose();
    descriptionFocusNode = null;
    descriptionFocusNode = FocusNode(
      debugLabel: 'Description',
    );
    scrollController = ScrollController();
  }

  /// Initialize grid focus nodes
  void initializeGridFocusNodes() {
    // Dispose existing nodes
    for (var node in gridFocusNodes) {
      node.dispose();
    }
    gridFocusNodes.clear();
    firstGridItemFocusNode = null;

    final total = listContent.length > 1 ? listContent.length - 1 : 0;
    for (int i = 0; i < total; i++) {
      gridFocusNodes.add(FocusNode(debugLabel: 'Card_$i'));
    }
    if (gridFocusNodes.isNotEmpty) {
      firstGridItemFocusNode = gridFocusNodes.first;
    }
  }

  /// Dispose grid focus nodes
  void disposeGridFocusNodes() {
    for (var node in gridFocusNodes) {
      node.dispose();
    }
    gridFocusNodes.clear();
  }

  /// Handle grid navigation
  KeyEventResult handleGridNavigation(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    const cols = 5; // Updated to match the new grid column count
    final r = index ~/ cols;
    final c = index % cols;
    final t = gridFocusNodes.length;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        // If we're at the last item of the entire grid, don't move
        if (index == t - 1) {
          return KeyEventResult.handled; // Stay on current item
        }
        final n = (c == cols - 1) ? (r + 1) * cols : index + 1;
        if (n < t) {
          _focusGridItem(n);
          return KeyEventResult.handled;
        }
        return KeyEventResult.handled; // Stay on current item if no valid move
      case LogicalKeyboardKey.arrowLeft:
        if (index == 0) {
          moveFocusToNavigationBar();
          return KeyEventResult.handled;
        }
        final p = (c == 0 && r > 0) ? r * cols - 1 : index - 1;
        if (p >= 0) {
          _focusGridItem(p);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        final n = (r + 1) * cols;
        if (n < t) {
          _focusGridItem(n);
          return KeyEventResult.handled;
        }
        return KeyEventResult.handled; // Stay on current item if no valid move
      case LogicalKeyboardKey.arrowUp:
        if (r == 0) {
          _moveFocusToTrailerButton();
          return KeyEventResult.handled;
        }
        // Fix: Calculate the correct position in the previous row
        // If the current row has fewer items than cols, we need to go to the last item of the previous row
        final prevRowStart = (r - 1) * cols;
        final prevRowEnd = (prevRowStart + cols - 1).clamp(0, t - 1);
        final targetIndex = (index - cols).clamp(prevRowStart, prevRowEnd);

        if (targetIndex >= 0 && targetIndex < t) {
          _focusGridItem(targetIndex);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  /// Focus on grid item and scroll to it
  void _focusGridItem(int index) {
    if (index < 0 || index >= gridFocusNodes.length) return;
    gridFocusNodes[index].requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      const cols = 5; // Updated to match the new grid column count
      final pos = 262.0 + ((index ~/ cols) * 200.0) - (scrollController.position.viewportDimension / 3);
      scrollController.animateTo(
        pos.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Handle key events for TV remote navigation
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          // Handle Left Arrow from "All" tab (index 0) to Dashboard Coming Soon tab
          if (index == 0) {
            moveFocusToNavigationBar();
            return KeyEventResult.handled;
          } else {
            _moveFocusLeft();
            return KeyEventResult.handled;
          }
        case LogicalKeyboardKey.arrowRight:
          _moveFocusRight();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          return KeyEventResult.ignored;
        case LogicalKeyboardKey.arrowUp:
          return KeyEventResult.ignored;
        case LogicalKeyboardKey.arrowDown:
          // Only move to trailer button if there's data
          if (listContent.isNotEmpty) {
            if(descriptionFocusNode != null && descriptionFocusNode!.ancestors.isNotEmpty) {
              _moveFocusToDescription();
              return KeyEventResult.handled;
            }
            _moveFocusToTrailerButton();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Move focus to the left tab
  void _moveFocusLeft() {
    if (currentSelected.value > 0) {
      currentSelected.value--;
      FocusManager.instance.primaryFocus?.unfocus();
      focusNodesForTabs[currentSelected.value].requestFocus();
      // Trigger API call on horizontal navigation
      onTabChanged(currentSelected.value);
    }
  }

  /// Move focus to the right tab
  void _moveFocusRight() {
    if (currentSelected.value < filterTabs.length - 1) {
      currentSelected.value++;
      focusNodesForTabs[currentSelected.value].requestFocus();
      // Trigger API call on horizontal navigation
      onTabChanged(currentSelected.value);
    }
  }

  /// Move focus to the trailer button
  void _moveFocusToTrailerButton() {
    if (trailerButtonFocusNode != null && listContent.isNotEmpty) {
      trailerButtonFocusNode!.requestFocus();
      isTrailerButtonFocused.value = true;

      // Scroll to show the trailer button area immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Retry after a longer delay if still not ready
          Future.delayed(const Duration(milliseconds: 100), () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      });
    }
  }

  /// Public method to move focus to trailer button
  void moveFocusToTrailerButton() {
    _moveFocusToTrailerButton();
  }

  void _moveFocusToDescription() {
    if (descriptionFocusNode != null && listContent.isNotEmpty) {
      descriptionFocusNode!.requestFocus();

      // Scroll to show the trailer button area immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Retry after a longer delay if still not ready
          Future.delayed(const Duration(milliseconds: 100), () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      });
    }
  }

  /// Public method to move focus to trailer button
  void moveFocusToDescription() {
    _moveFocusToDescription();
  }

  /// Move focus to the Coming Soon tab in the navigation bar
  void moveFocusToNavigationBar() {
    // Find the Coming Soon tab in the dashboard navigation
    final comingSoonIndex = dashboardController.bottomNavItems.indexWhere(
      (item) => item.type == BottomItem.comingsoon,
    );

    if (comingSoonIndex >= 0 && comingSoonIndex < dashboardController.bottomNavItems.length) {
      // Request focus on the Coming Soon tab
      dashboardController.bottomNavItems[comingSoonIndex].focusNode.requestFocus();
      // Expand the drawer to show the navigation
      dashboardController.expandDrawer();
    }
  }

  /// Handle key events for trailer button
  KeyEventResult _handleTrailerButtonKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if(descriptionFocusNode != null && descriptionFocusNode!.ancestors.isNotEmpty) {
            _moveFocusToDescription();
            return KeyEventResult.handled;
          }
          // Move focus back to the currently selected tab
          focusNodesForTabs[currentSelected.value].requestFocus();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          // Move focus to the first grid card only if there's data
          if (listContent.length > 1 && firstGridItemFocusNode != null) {
            firstGridItemFocusNode!.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        case LogicalKeyboardKey.arrowLeft:
          // Move focus to the Coming Soon tab in the navigation bar
          moveFocusToNavigationBar();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          // Handle horizontal navigation if needed
          return KeyEventResult.ignored;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          if (listContent.isNotEmpty) {
            navigateToDetailScreen(listContent.first);
          }
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult handleDescriptionKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          // Move focus back to the currently selected tab
          focusNodesForTabs[currentSelected.value].requestFocus();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          // Move focus to the first grid card only if there's data
          _moveFocusToTrailerButton();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowLeft:
          // Move focus to the Coming Soon tab in the navigation bar
          moveFocusToNavigationBar();
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  // Tab selection method for TV navigation
  void onTabChanged(int index) {
    currentSelected(index);
    getListData(showLoader: true);
  }

  // Map tab names to API filter types
  String _getFilterType(String tabName) {
    switch (tabName.toLowerCase()) {
      case 'all':
        return 'all';
      case 'movies':
        return 'movie';
      case 'tv shows':
        return 'tvshow';
      case 'videos':
        return 'videos';
      default:
        return 'all';
    }
  }

  // Timer state management
  Timer? _timer;
  Rx<Duration> timeRemaining = Duration.zero.obs;
  RxBool isTimerActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFocusNodes();
    getListData(showLoader: false);

    // Initialize focus on first tab after data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNodesForTabs.isNotEmpty) {
        focusNodesForTabs[0].requestFocus();
      }
      onTabChanged(0);
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    trailerButtonFocusNode?.dispose();
    descriptionFocusNode?.dispose();
    scrollController.dispose();
    disposeGridFocusNodes();
    super.onClose();
  }

//Get Coming Soon Details List
  @override
  Future<void> getListData({bool showLoader = true}) async {
    setLoading(showLoader);
    await listContentFuture(
      CoreServiceApis.getComingSoonList(
        page: currentPage.value,
        type: _getFilterType(filterTabs[currentSelected.value]),
        getComingSoonList: listContent,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).catchError((e) {
      throw e;
    }).whenComplete(() {
      setLoading(false);
      // Initialize grid focus nodes after data loads
      initializeGridFocusNodes();
      // Ensure focus stays on the current tab after data loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusNodesForTabs.isNotEmpty && currentSelected.value < focusNodesForTabs.length) {
          // Only restore focus if no other widget has focus (e.g., when switching tabs)
          if (!focusNodesForTabs.any((node) => node.hasFocus)) {
            focusNodesForTabs[currentSelected.value].requestFocus();
          }
        }
      });
    });
  }

//Save Reminder
  Future<void> saveRemind({required bool isRemind, required ComingSoonModel comingSoonData}) async {
    setLoading(true);
    CoreServiceApis.saveReminder(
      request: {
        "entertainment_id": comingSoonData.id,
        "is_remind": isRemind ? 0 : 1,
        "release_date": comingSoonData.releaseDate,
        if (profileId.value != 0) "profile_id": profileId.value,
      },
    ).then((value) async {
      await getListData(showLoader: false);
      successSnackBar(value.message);
    }).catchError((e) {
      setLoading(false);
      errorSnackBar(error: e);
    });
  }

  // Timer management methods
  void calculateTimeRemaining(String releaseDate) {
    if (releaseDate.isNotEmpty) {
      try {
        final releaseDateTime = DateTime.parse(releaseDate);
        final now = DateTime.now();
        final difference = releaseDateTime.difference(now);

        if (difference.isNegative) {
          timeRemaining.value = Duration.zero;
        } else {
          timeRemaining.value = difference;
        }
      } catch (e) {
        timeRemaining.value = Duration.zero;
      }
    }
  }

  void startTimer(String releaseDate) {
    _timer?.cancel();

    calculateTimeRemaining(releaseDate);
    isTimerActive.value = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.value > Duration.zero) {
        timeRemaining.value = timeRemaining.value - const Duration(seconds: 1);
      } else {
        timer.cancel();
        isTimerActive.value = false;
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    isTimerActive.value = false;
    timeRemaining.value = Duration.zero;
  }

  void pauseTimer() {
    _timer?.cancel();
    isTimerActive.value = false;
  }

  void resumeTimer(String releaseDate) {
    if (!isTimerActive.value) {
      startTimer(releaseDate);
    }
  }

  /// Navigate to ComingSoonDetailScreen
  void navigateToDetailScreen(ComingSoonModel comingSoonData) {
    doIfLogin(onLoggedIn: () {
      Get.to(
        () => ComingSoonDetailScreen(
          comingSoonCont: this,
          comingSoonData: comingSoonData,
        ),
      );
    });
  }
}
