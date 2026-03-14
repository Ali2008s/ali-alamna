import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/profile/model/profile_detail_resp.dart';
import 'package:streamit_laravel/screens/setting/account_setting/components/logout_account_component.dart';
import 'package:streamit_laravel/screens/setting/language/language_screen.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../network/auth_apis.dart';
import '../../network/core_api.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../home/home_controller.dart';
import '../subscription/model/subscription_plan_model.dart';
import 'profile_screen.dart';

enum ProfileMenuType { profile, watchlist }

class ProfileController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isProfileLoggedIn = false.obs;
  Rx<Future<ProfileDetailResponse>> getProfileDetailsFuture = Future(() => ProfileDetailResponse(data: ProfileModel(planDetails: SubscriptionPlanModel()))).obs;
  Rx<ProfileModel> profileDetailsResp = ProfileModel(planDetails: SubscriptionPlanModel()).obs;
  
  // Focus management
  final FocusNode firstProfileFocusNode = FocusNode();
  final FocusNode logoutButtonFocusNode = FocusNode();
  final FocusNode languageButtonFocusNode = FocusNode();
  final RxBool isLogoutButtonFocused = false.obs;
  final RxBool isLanguageButtonFocused = false.obs;

  RxList<TVMenuItem> menuItems = [
    TVMenuItem(icon: Icons.person, title: () => locale.value.whoIsWatching, slug: ProfileMenuType.profile),
    TVMenuItem(icon: Icons.favorite, title: () => locale.value.watchlist, slug: ProfileMenuType.watchlist),
  ].obs;

  Rx<TVMenuItem> currentFocusMenu = TVMenuItem(icon: Icons.person, title: () => locale.value.profile, slug: ProfileMenuType.profile).obs;

  @override
  void onInit() {
    if (menuItems.isNotEmpty) {
      currentFocusMenu(menuItems.first);
    }

    if (cachedProfileDetails != null) {
      profileDetailsResp(cachedProfileDetails?.data);
    }
    
    // Initialize focus management
    _initializeFocusManagement();
    
    super.onInit();
    getProfile();
    getProfileDetail();
  }

  @override

  void onClose() {
    firstProfileFocusNode.dispose();
    logoutButtonFocusNode.dispose();
    languageButtonFocusNode.dispose();
    super.onClose();
  }

  void _initializeFocusManagement() {
    // Set focus on the first profile component after the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstProfileFocusNode.requestFocus();
    });
    
    // Listen for changes to currentFocusMenu and focus on first profile component when needed
    ever(currentFocusMenu, (TVMenuItem menuItem) {
      if (menuItem.slug == ProfileMenuType.profile) {
        // Focus on the first profile component when profile menu is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          firstProfileFocusNode.requestFocus();
        });
      }
    });
    
    // Listen for focus changes on the first profile focus node
    firstProfileFocusNode.addListener(() {
      if (firstProfileFocusNode.hasFocus) {
        // Update the current focus menu when first profile gets focus
        if (menuItems.isNotEmpty) {
          currentFocusMenu(menuItems[0]);
        }
      }
    });
  }

  // Method to focus on first profile component (can be called from dashboard)
  void focusOnFirstProfileComponent() {
    firstProfileFocusNode.requestFocus();
  }

  void getProfile() {
    if (isLoggedIn.isTrue) {
      isProfileLoggedIn(true);
    } else {
      isProfileLoggedIn(false);
    }
  }

  ///Get Profile List
  Future<void> getProfileDetail({bool showLoader = true}) async {
    if (isLoggedIn.isTrue) {
      if (showLoader) {
        isLoading(true);
      }
      await getProfileDetailsFuture(CoreServiceApis.getProfileDet()).then((value) {
        profileDetailsResp(value.data);
        currentSubscription(value.data.planDetails);
        currentSubscription.value.activePlanInAppPurchaseIdentifier = (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? currentSubscription.value.appleInAppPurchaseIdentifier : currentSubscription.value.googleInAppPurchaseIdentifier;
        setValue(SharedPreferenceConst.USER_SUBSCRIPTION_DATA, value.data.planDetails.toJson());
      }).whenComplete(() {
        isLoading(false);
      });
    }
  }

  Future<void> logoutCurrentUser() async {
    isLoading(true);
    Get.back();

    await AuthServiceApis.deviceLogoutApi(deviceId: currentDevice.value.deviceId).then((value) async {
      isLoggedIn(false);
      AuthServiceApis.removeCacheData();
      await AuthServiceApis.clearData();
      successSnackBar(locale.value.youHaveBeenLoggedOutSuccessfully);
      removeKey(SharedPreferenceConst.IS_LOGGED_IN);
      DashboardController dashboardController = Get.find();
      dashboardController.onBottomTabChange(BottomItem.home);

      Get.offAll(
        () => DashboardScreen(),
        binding: BindingsBuilder(
          () {
            Get.put(HomeController());
          },
        ),
      );

      isLoading(false);
    }).catchError((e) {
      isLoading(false);
      toast(e.toString(), print: true);
    });
  }

  // Method to request focus on the first profile component
  void requestFocusOnFirstProfileComponent() {
    if (menuItems.isNotEmpty) {
      currentFocusMenu(menuItems[0]);
      focusOnFirstProfileComponent();
    }
  }

  // Handle logout button focus changes
  void onLogoutButtonFocusChange(bool hasFocus) {
    isLogoutButtonFocused(hasFocus);
  }

  // Handle logout button key events
  KeyEventResult handleLogoutButtonKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        _showLogoutDialog();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Move focus to first profile component
        firstProfileFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Move focus to language button
        languageButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Ignore up and right arrow keys
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return LogoutAccountComponent(
          device: currentDevice.value.deviceId,
          deviceName: currentDevice.value.deviceName,
          onLogout: (logoutAll) async {
            logoutCurrentUser();
          },
        );
      },
    );
  }

  /// Handle language button focus changes
  void onLanguageButtonFocusChange(bool hasFocus) {
    isLanguageButtonFocused(hasFocus);
  }

  /// Handle language button key events
  KeyEventResult handleLanguageButtonKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        Get.to(() => LanguageScreen());
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Move focus to first profile component
        firstProfileFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Move focus to profile navigation bar button
        DashboardController dashboardCont = Get.find();
        dashboardCont.isInternalFocusChange(true);
        
        // Find the profile menu item in the dashboard
        int profileIndex = dashboardCont.bottomNavItems.indexWhere((item) => item.type == BottomItem.profile);
        if (profileIndex >= 0) {
          dashboardCont.bottomNavItems[profileIndex].focusNode.requestFocus();
        }
        
        currentFocusMenu(menuItems[0]);
        
        // Reset flag after a short delay
        Future.delayed(Duration(milliseconds: 100), () {
          dashboardCont.isInternalFocusChange(false);
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Move focus to logout button
        logoutButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Ignore up arrow key - do nothing
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}