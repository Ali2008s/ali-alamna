import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/screens/home/firebase/firebase_api.dart';

class ShortsScreenController extends GetxController {
  final PageController pageController = PageController();
  RxList<Map<String, dynamic>> shortsList = <Map<String, dynamic>>[].obs;
  RxInt currentIndex = 0.obs;
  RxBool isLoading = false.obs;

  // Cache for controllers to achieve TikTok-like smoothness
  final RxMap<int, PodPlayerController> controllers = <int, PodPlayerController>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadShorts();
  }

  Future<void> loadShorts() async {
    isLoading(true);
    try {
      final list = await FirebaseChannelApi.getShorts();
      shortsList.assignAll(list.reversed.toList());
      
      // Preload first two videos
      if (shortsList.isNotEmpty) {
        _initController(0);
        if (shortsList.length > 1) {
          _initController(1);
        }
      }
    } finally {
      isLoading(false);
    }
  }

  void _initController(int index) {
    if (controllers.containsKey(index)) return;
    if (index < 0 || index >= shortsList.length) return;

    final url = shortsList[index]['video_url'];
    if (url == null || url.isEmpty) return;

    final controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.network(url),
      podPlayerConfig: const PodPlayerConfig(
        autoPlay: false,
        isLooping: true,
        videoQualityPriority: [360, 720],
      ),
    )..initialise().then((_) {
      if (index == currentIndex.value) {
        controllers[index]?.play();
      }
      controllers.refresh();
    });
    
    controllers[index] = controller;
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    
    // Play current, pause others
    controllers.forEach((idx, controller) {
      if (idx == index) {
        if (controller.isInitialised) {
          controller.play();
        } else {
           // If not ready yet, it will play once init finishes in _initController
        }
      } else {
        controller.pause();
      }
    });

    // Cleanup far away controllers and preload adjacent ones
    _cleanupControllers(index);
    _initController(index + 1);
    _initController(index + 2); // Preload one extra for speed
  }

  void _cleanupControllers(int currentIndex) {
    // Keep 2 before and 3 after
    final keysToRemove = controllers.keys.where((i) => (i < currentIndex - 2) || (i > currentIndex + 3)).toList();
    for (var key in keysToRemove) {
      controllers[key]?.dispose();
      controllers.remove(key);
    }
  }

  @override
  void onClose() {
    controllers.forEach((_, c) => c.dispose());
    pageController.dispose();
    super.onClose();
  }

  void nextShort() {
    if (currentIndex.value < shortsList.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousShort() {
    if (currentIndex.value > 0) {
      pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
}
