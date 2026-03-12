// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/devices/model/device_model.dart';
import 'package:streamit_laravel/screens/profile/model/profile_detail_resp.dart';
import 'package:streamit_laravel/screens/subscription/model/subscription_plan_model.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../network/auth_apis.dart';
import '../utils/common_base.dart';
import '../utils/constants.dart';
import 'dashboard/components/menu.dart';
import 'dashboard/dashboard_screen.dart';
import 'live_tv/live_tv_details/live_tv_details_screen.dart';
import 'live_tv/model/live_tv_dashboard_response.dart';
import 'profile/watching_profile/watching_profile_screen.dart';
// import 'tv_show/tv_show_detail_screen.dart';

class SplashScreenController extends GetxController {
  RxBool appNotSynced = false.obs;
  RxBool _initialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialized(false);
    init();
  }

  @override
  void onReady() {
    try {
      toggleThemeMode(themeId: THEME_MODE_DARK);
    } catch (e) {
      log('getThemeFromLocal from cache E: $e');
    }
    super.onReady();
  }

  /// يُستدعى من SplashScreen لضمان التهيئة حتى لو كان الـ Controller موجوداً
  void ensureInit() {
    if (!_initialized.value) {
      _initialized(true);
      getCacheData();
      getDeviceInfo().then((_) => getAppConfigurations());
    }
  }

  Future<void> init({bool showLoader = false}) async {
    _initialized(true);
    getCacheData();
    await getDeviceInfo();
    await getAppConfigurations(showLoader: showLoader);
  }

  void handleDeepLinking({required String deepLink}) {
    if (deepLink.split("/")[2] == locale.value.movies) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doIfLogin(onLoggedIn: () {
          final int id = int.parse(deepLink.split("/").last);
          Get.offAll(
            () => ContentDetailsScreen(),
            arguments: PosterDataModel(
              id: id,
              posterImage: '',
              details: ContentData(id: id, type: VideoType.movie),
            ),
          );
        });
      });
    } else if (deepLink.split("/")[2] == locale.value.episode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doIfLogin(onLoggedIn: () {
          final int id = int.parse(deepLink.split("/").last);
          Get.offAll(
            () => ContentDetailsScreen(),
            arguments: PosterDataModel(
              id: id,
              posterImage: '',
              details: ContentData(id: id, type: VideoType.episode),
            ),
          );
        });
      });
    } else if (deepLink.split("/")[2] == locale.value.liveTv) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doIfLogin(onLoggedIn: () {
          Get.offAll(() => LiveShowDetailsScreen(),
              arguments: ChannelModel(id: int.parse(deepLink.split("/").last)));
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => DashboardScreen(), binding: BindingsBuilder(
          () {
            getDashboardController().onBottomTabChange(BottomItem.home);
          },
        ));
      });
    }
  }

//Get Device Information
  Future<void> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        // Use androidId or fallback to a unique device ID for TV devices
        final String deviceId = androidInfo.id.isNotEmpty
            ? androidInfo.id
            : '${androidInfo.brand}_${androidInfo.model}_${androidInfo.product}'
                .validate();

        currentDevice(
          DeviceData(
            deviceId: deviceId,
            deviceName: '${androidInfo.brand}(${androidInfo.model.validate()})',
            platform: locale.value.android,
            createdAt: DateTime.now().toUtc().toIso8601String(),
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        currentDevice(
          DeviceData(
            deviceId: iosInfo.identifierForVendor.validate(),
            deviceName: iosInfo.name,
            platform: locale.value.ios,
            createdAt: DateTime.now().toUtc().toIso8601String(),
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      } else {
        // Fallback for TV or other Android-based devices
        currentDevice(
          DeviceData(
            deviceId: 'tv_device_${DateTime.now().millisecondsSinceEpoch}',
            deviceName: 'Smart TV',
            platform: locale.value.android,
            createdAt: DateTime.now().toUtc().toIso8601String(),
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
      }
    } catch (e) {
      log('getDeviceInfo error: $e');
      // Fallback device info to avoid blocking splash screen
      currentDevice(
        DeviceData(
          deviceId: 'unknown_device_${DateTime.now().millisecondsSinceEpoch}',
          deviceName: 'Unknown Device',
          platform: 'android',
          createdAt: DateTime.now().toUtc().toIso8601String(),
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    }
  }

  RxBool isLoading = false.obs;

  ///Get ChooseService List
  Future<void> getAppConfigurations({bool showLoader = false}) async {
    isLoading(showLoader);
    appNotSynced(
        !getBoolAsync(SharedPreferenceConst.IS_APP_CONFIGURATION_SYNCED_ONCE));

    // ✅ مؤقت أمان: إذا لم يحدث تنقل خلال 12 ثانية، انتقل تلقائياً
    final safetyTimer = Future.delayed(const Duration(seconds: 12), () {
      _navigateOnError();
    });

    try {
      await AuthServiceApis.getAppConfigurations(
        forceSync: true,
        isFromSplashScreen: true,
        onError: () {
          isLoading(false);
          appNotSynced(true);
          _navigateOnError();
        },
      ).then((value) async {
        setValue(SharedPreferenceConst.IS_APP_CONFIGURATION_SYNCED_ONCE, true);
        is18Plus(getBoolAsync(SharedPreferenceConst.IS_18_PLUS));
        isLoading(false);
        appNotSynced(false);
        // لا داعي لإلغاء safetyTimer لأن _navigateOnError محمية بشرط
      }).catchError((e) {
        log('getAppConfigurations error: $e');
        isLoading(false);
        appNotSynced(true);
        _navigateOnError();
      });
    } catch (e) {
      log('getAppConfigurations exception: $e');
      isLoading(false);
      _navigateOnError();
    }
    // safetyTimer يعمل في الخلفية ولا نحتاج await
    safetyTimer.ignore();
  }

  bool _hasNavigated = false;

  /// Navigate away from splash screen even when there is a network/API error
  void _navigateOnError() {
    if (_hasNavigated) return; // منع التنقل المزدوج
    _hasNavigated = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        if (isLoggedIn.value) {
          Get.offAll(() => WatchingProfileScreen(), arguments: true);
        } else {
          Get.offAll(
            () => DashboardScreen(),
            binding: BindingsBuilder(() {
              getDashboardController().onBottomTabChange(BottomItem.home);
            }),
          );
        }
      } catch (e) {
        log('_navigateOnError error: $e');
      }
    });
  }

  void getCacheData() {
    if (getStringAsync(SharedPreferenceConst.CACHE_LIVE_TV_DASHBOARD)
        .isNotEmpty) {
      cachedLiveTvDashboard = LiveChannelDashboardResponse.fromJson(jsonDecode(
          getStringAsync(SharedPreferenceConst.CACHE_LIVE_TV_DASHBOARD)));
    }
    if (getStringAsync(SharedPreferenceConst.CACHE_PROFILE_DETAIL).isNotEmpty) {
      cachedProfileDetails = ProfileDetailResponse.fromJson(jsonDecode(
          getStringAsync(SharedPreferenceConst.CACHE_PROFILE_DETAIL)));
    }

    if (getStringAsync(SharedPreferenceConst.USER_SUBSCRIPTION_DATA)
        .isNotEmpty) {
      currentSubscription(SubscriptionPlanModel.fromJson(jsonDecode(
          getStringAsync(SharedPreferenceConst.USER_SUBSCRIPTION_DATA))));
    }
  }
}
