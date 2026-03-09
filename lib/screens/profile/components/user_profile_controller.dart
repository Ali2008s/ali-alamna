import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';
import 'package:streamit_laravel/screens/profile/profile_controller.dart';
import '../../../utils/app_common.dart';

class UserProfileController extends GetxController {
  final WatchingProfileController profileWatchingController =
      Get.put(WatchingProfileController(navigateToDashboard: true));
  final ProfileController profileCont = Get.put(ProfileController());

  final RxBool isAddProfileFocused = false.obs;
  final RxBool isAnyProfileFocused = false.obs;

  final FocusNode subscribeBtnFNode = FocusNode();
  final List<FocusNode> profileFocusNodes = [];
  final Map<int, RxBool> profileFocusStates = {};

  int currentProfileIndex = 0;

  @override
  void onInit() {
    super.onInit();
    // Initialize focus nodes for profiles
    _initializeFocusNodes();
  }

  @override
  void onClose() {
    _disposeAllFocusNodes();
    _disposeFocusStates();
    super.onClose();
  }

  /// Initialize focus nodes based on the number of profiles
  void _initializeFocusNodes() {
    _disposeAllFocusNodes();
    _disposeFocusStates();
    for (int i = 0; i < accountProfiles.length; i++) {
      profileFocusNodes.add(FocusNode(debugLabel: 'ProfileNode$i'));
      // Initialize focus state for this index
      profileFocusStates[i] = false.obs;
    }
  }

  /// Safe dispose for all focus nodes
  void _disposeAllFocusNodes() {
    for (var node in profileFocusNodes) {
      try {
        if (node.hasFocus || node.hasPrimaryFocus) {
          node.unfocus();
        }
        node.dispose();
      } catch (e) {
        debugPrint("FocusNode dispose error: $e");
      }
    }
    profileFocusNodes.clear();

    try {
      if (subscribeBtnFNode.hasFocus || subscribeBtnFNode.hasPrimaryFocus) {
        subscribeBtnFNode.unfocus();
      }
      subscribeBtnFNode.dispose();
    } catch (e) {
      debugPrint("Subscribe button node dispose error: $e");
    }
  }

  /// Safely update nodes if profile count changes
  void updateFocusNodes() {
    int diff = accountProfiles.length - profileFocusNodes.length;

    if (diff > 0) {
      // Add new nodes
      for (int i = 0; i < diff; i++) {
        int newIndex = profileFocusNodes.length + i;
        profileFocusNodes.add(FocusNode(debugLabel: 'ProfileNode$newIndex'));
        // Initialize focus state for new index
        profileFocusStates[newIndex] = false.obs;
      }
    } else if (diff < 0) {
      // Remove extra nodes
      int removeCount = -diff;
      int initialLength = profileFocusNodes.length;
      for (int i = 0; i < removeCount; i++) {
        var lastNode = profileFocusNodes.removeLast();
        try {
          if (lastNode.hasFocus || lastNode.hasPrimaryFocus) {
            lastNode.unfocus();
          }
          lastNode.dispose();
        } catch (e) {
          debugPrint("Error disposing node: $e");
        }
        // Remove corresponding focus state (from the end)
        int removedIndex = initialLength - 1 - i;
        if (profileFocusStates.containsKey(removedIndex)) {
          var removedState = profileFocusStates.remove(removedIndex);
          try {
            removedState?.close();
          } catch (e) {
            debugPrint("Error disposing focus state: $e");
          }
        }
      }
    }
  }

  void setFirstProfileFocusNode(FocusNode? firstProfileFocusNode) {
    if (firstProfileFocusNode != null && profileFocusNodes.isNotEmpty) {
      profileFocusNodes[0] = firstProfileFocusNode;
    }
  }

  /// Initialize focus node with external focus node if provided
  void initializeWithFirstProfileFocusNode(FocusNode? firstProfileFocusNode) {
    if (firstProfileFocusNode != null) {
      setFirstProfileFocusNode(firstProfileFocusNode);
    }
  }

  /// Get focus state for a specific profile index
  RxBool getFocusState(int index) {
    if (!profileFocusStates.containsKey(index)) {
      profileFocusStates[index] = false.obs;
    }
    return profileFocusStates[index]!;
  }

  /// Update focus state for a specific profile index
  void updateFocusState(int index, bool value) {
    if (!profileFocusStates.containsKey(index)) {
      profileFocusStates[index] = false.obs;
    }
    profileFocusStates[index]!.value = value;
  }

  /// Dispose all focus states
  void _disposeFocusStates() {
    for (var state in profileFocusStates.values) {
      try {
        state.close();
      } catch (e) {
        debugPrint("FocusState dispose error: $e");
      }
    }
    profileFocusStates.clear();
  }

  void _navigateToProfile(int index) {
    if (index >= 0 && index < profileFocusNodes.length) {
      currentProfileIndex = index;
      if (profileFocusNodes[index].canRequestFocus) {
        profileFocusNodes[index].requestFocus();
      }
    }
  }

  void onProfileFocusChange(bool hasFocus, int index) {
    isAnyProfileFocused(hasFocus);
    updateFocusState(index, hasFocus);
    if (hasFocus) {
      currentProfileIndex = index;
    }
  }

  void onDownArrowKeyEvent() {
    if (isAnyProfileFocused.value && !subscribeBtnFNode.hasFocus) {
      subscribeBtnFNode.requestFocus();
    }
  }

  void onLeftArrowKeyEvent(int index, Function()? onLeftArrowKeyEvent) {
    if (index > 0) {
      _navigateToProfile(index - 1);
    } else {
      onLeftArrowKeyEvent?.call();
    }
  }

  void onRightArrowKeyEvent(int index, Function()? onRightArrowKeyEvent) {
    if (index < accountProfiles.length - 1) {
      _navigateToProfile(index + 1);
    } else {
      onRightArrowKeyEvent?.call();
    }
  }
}
