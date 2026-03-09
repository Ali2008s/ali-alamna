// watching_profile_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/network/auth_apis.dart';
import 'package:streamit_laravel/network/core_api.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_screen.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_screen.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../../main.dart';
import '../../18_plus/18_plus_card.dart';
import '../../auth/model/login_response.dart';
import '../../home/home_controller.dart';
import 'components/add_update_profile_dialog_component.dart';
import 'model/profile_watching_model.dart';
import 'components/pin_verification_screen.dart';
import 'package:streamit_laravel/components/otp_textfield_tv.dart' as otp_field;

class WatchingProfileController extends GetxController {
  bool navigateToDashboard;

  WatchingProfileController({this.navigateToDashboard = false});

  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxBool isBtnEnable = false.obs;
  RxInt currentPage = 1.obs;
  Rx<Future<RxList<WatchingProfileModel>>> getProfileFuture = Future(() => RxList<WatchingProfileModel>()).obs;

  final TextEditingController saveNameController = TextEditingController();
  final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  FocusNode picFocusNode = FocusNode();
  FocusNode nameFocusNode = FocusNode();
  FocusNode cancelBtnFocusNode = FocusNode();
  FocusNode saveBtnBtnFocusNode = FocusNode();
  RxBool isCancelBtnFocused = false.obs;
  RxBool isSaveBtnFocused = false.obs;

  // Focus management for profile screen
  final FocusNode addProfileFocusNode = FocusNode();
  final FocusNode logoutButtonFocusNode = FocusNode();
  final List<FocusNode> profileFocusNodes = [];
  final RxBool isLogoutButtonFocused = false.obs;
  final Map<int, RxBool> profileFocusStates = {};

  var selectedImagePath = ''.obs;
  var centerImagePath = ''.obs;
  var centerAssertImagePath = ''.obs;
  Rx<File> imageFile = File("").obs;
  XFile? pickedFile;

  Rx<WatchingProfileModel> selectedProfile = WatchingProfileModel().obs;

  List<String> defaultProfileImage = [
    Assets.watchingProfileDefaultAvatar1,
    Assets.watchingProfileDefaultAvatar2,
    Assets.watchingProfileDefaultAvatar3,
    Assets.watchingProfileDefaultAvatar4,
    Assets.watchingProfileDefaultAvatar5,
  ];

  RxInt page = 1.obs;

  RxInt currentIndex = 2.obs;

  RxBool isChildrenProfileEnabled = false.obs;

  PageController pageController = PageController(
    initialPage: 0,
    viewportFraction: 0.30,
    keepPage: true,
  );

  // Pin verification related
  final TextEditingController pinController = TextEditingController();
  Rx<FocusNode> lastActiveOTPFocusNode = FocusNode().obs;
  final FocusNode cancelBtnFocus = FocusNode();
  final FocusNode btnFocus = FocusNode();

  List<otp_field.OTPLengthModel> list = [];

  @override
  Future<void> onInit() async {
    super.onInit();
    currentIndex = 0.obs;
    init();
    centerImagePath.value = Assets.iconsIcUser;
  }

  Future<void> init() async {
    isLoggedIn(getBoolAsync(SharedPreferenceConst.IS_LOGGED_IN));
    if (isLoggedIn.value) {
      final userData = getStringAsync(SharedPreferenceConst.USER_DATA);
      if (getStringAsync(SharedPreferenceConst.USER_DATA).isNotEmpty) {
        loginUserData(UserData.fromJson(jsonDecode(userData)));
      }
      getProfilesList();
    }
  }

  void getBtnEnable() {
    if (saveNameController.text.isNotEmpty) {
      isBtnEnable(true);
    } else {
      isBtnEnable(false);
    }
  }

  void updateCenterImage(String imagePath) {
    centerImagePath.value = imagePath;
  }

  ImageProvider<Object> getImageProvider(
    String imagePath, {
    double? height,
    double? width,
  }) {
    if (imagePath.startsWith('http') || Uri.tryParse(imagePath)?.isAbsolute == true) {
      return NetworkImage(
        '$imagePath?v=${DateTime.now().millisecondsSinceEpoch}',
      );
    } else if (File(imagePath).existsSync()) {
      return FileImage(File(imagePath));
    } else {
      return AssetImage(imagePath);
    }
  }

  Future<void> getProfilesList({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }

    await getProfileFuture(
      CoreServiceApis.getWatchingProfileList(
        profileList: accountProfiles,
        page: page.value,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).whenComplete(() => isLoading(false)).catchError((e) {
      toast(e.toString());
      throw e;
    }).then((v) {
      if (profileId.value > 0 && accountProfiles.isNotEmpty && accountProfiles.any((element) => element.id == profileId.value)) {
        selectedProfile(accountProfiles.firstWhere((element) => element.id == profileId.value));
        selectedAccountProfile(selectedProfile.value);
        profileId(selectedProfile.value.id);
      }
    }).catchError((e) {
      toast(e.toString());
    });
  }

  String generateRandomString() {
    final random = Random();
    const length = 10;
    const digits = '0123456789';

    return List.generate(length, (index) => digits[random.nextInt(digits.length)]).join();
  }

  Future<void> editUserProfile(bool isEdit, {required String name}) async {
    if (isLoading.isTrue) return;
    isLoading(true);
    File? tempFile;

    try {
      if (centerImagePath.value.startsWith("http")) {
        final response = await http.get(Uri.parse(centerImagePath.value));
        if (response.statusCode == 200) {
          Directory tempDir = await getTemporaryDirectory();
          String tempPath = '${tempDir.path}/downloaded_image.png';
          tempFile = File(tempPath);
          await tempFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception("Failed to download image");
        }
      } else {
        if (await File(centerImagePath.value).exists()) {
          tempFile = File(centerImagePath.value);
        } else {
          ByteData byteData = await rootBundle.load(centerImagePath.value);

          final buffer = byteData.buffer;
          Directory tempDir = await getTemporaryDirectory();
          String tempPath = '${tempDir.path}/temp_image.${generateRandomString()}.png';

          tempFile = File(tempPath)
            ..writeAsBytesSync(
              buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            );
        }
      }

      Map<String, dynamic> request = {
        "name": name,
        "is_child_profile": isChildrenProfileEnabled.value ? 1 : 0,
        "user_id": loginUserData.value.id,
      };

      if (isEdit) request.putIfAbsent("id", () => selectedProfile.value.id);

      await CoreServiceApis.updateWatchProfile(
        request: request,
        files: [tempFile],
      ).then((value) async {
        if (value.newUserProfile.id > -1) {
          if (isEdit) {
            accountProfiles.removeWhere((element) => element.id == selectedProfile.value.id);
          }
          accountProfiles.add(value.newUserProfile);
          selectedProfile(value.newUserProfile);
        } else {
          await getProfilesList();
        }
        successSnackBar(isEdit ? locale.value.profileUpdatedSuccessfully : locale.value.newProfileAddedSuccessfully);
      }).catchError((e) {
        isLoading(false);
        if (e is Map<String, dynamic>) {
          errorSnackBar(error: e['error']);
          if (e['status_code'] == 406) {
            Future.delayed(
              Duration(seconds: 1),
              () {
                showSubscriptionDialog(title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
              },
            );
          }
        } else {
          errorSnackBar(error: e);
        }
      });
    } catch (e) {
      toast('Error: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteUserProfile(String id, {bool isFromProfileWatching = false}) async {
    if (isLoading.isTrue) return;
    isLoading(true);
    Map<String, dynamic> request = {"profile_id": id};
    await CoreServiceApis.deleteWatchingProfile(
      request: request,
    ).then((value) async {
      if (id.toInt() == profileId.value && !isFromProfileWatching) {
        Get.offAll(() => WatchingProfileScreen(), arguments: true);
      }
      await getProfilesList();
      successSnackBar("Profile deleted successfully");
    }).catchError((e) {
      errorSnackBar(error: e);
    }).whenComplete(() => isLoading(false));
  }

  void handleSelectProfile(WatchingProfileModel profile, BuildContext context) {
    if (profile.id != profileId.value) {
      if (profile.isProtectedProfile.getBoolInt() &&
          profile.profilePin.isNotEmpty &&
          (accountProfiles.any((element) => element.isChildProfile == 1) && selectedAccountProfile.value.isChildProfile.getBoolInt())) {
        Get.to(
          () => PinVerificationScreen(
            correctPin: profile.profilePin,
            onSuccess: () {
              _selectProfile(profile);
            },
          ),
        );
      } else {
        _selectProfile(profile);
      }
    }
  }

  void _selectProfile(WatchingProfileModel profile) {
    AuthServiceApis.removeCacheData();
    profileId(profile.id);
    selectedAccountProfile(profile);
    isChildrenProfileEnabled.value = profile.isChildProfile == 1 ? true : false;
    setValue(SharedPreferenceConst.IS_PROFILE_ID, profile.id);
    if (!getBoolAsync(SharedPreferenceConst.IS_18_PLUS)) {
      Get.to(() => EighteenPlusCard());
    } else {
      Get.offAll(
        () => DashboardScreen(),
        binding: BindingsBuilder(
          () {
            getDashboardController().onBottomTabChange(BottomItem.home);
          },
        ),
      );
    }
  }

  void handleAddEditProfile(WatchingProfileModel profile, bool isEdit) {
    if (isEdit) {
      selectedProfile(profile);
      saveNameController.text = selectedProfile.value.name;
      isChildrenProfileEnabled.value = profile.isChildProfile == 1 ? true : false;
      updateCenterImage(profile.avatar);
    }
    Get.bottomSheet(
      isDismissible: true,
      isScrollControlled: true,
      enableDrag: false,
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AddUpdateProfileDialogComponent(isEdit: isEdit),
      ),
    ).then((v) {
      saveNameController.clear();
    });
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

  void focusOTPField() {
    lastActiveOTPFocusNode.value.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void verifyPin(String correctPin, Function() onSuccess, {required BuildContext context}) async {
    if (pinController.text.isEmpty) {
      toast("Please enter PIN first");
    } else if (pinController.text == correctPin) {
      onSuccess();
    } else {
      toast(locale.value.incorrectPin);
      pinController.clear();
      for (var element in list) {
        element.textEditingController?.clear();
      }
      if(list.isNotEmpty && list.first.focusNode != null) {
        FocusScope.of(context).requestFocus(FocusNode());
        await Future.delayed(Duration(milliseconds: 100));
        if(!context.mounted) return; 
        FocusScope.of(context).requestFocus(list.first.focusNode!);
      }
    }
  }

  // Focus management methods
  void initializeProfileFocusNodes(int count) {
    // Clear existing focus nodes and states
    for (var focusNode in profileFocusNodes) {
      focusNode.dispose();
    }
    profileFocusNodes.clear();
    
    for (var state in profileFocusStates.values) {
      try {
        state.close();
      } catch (e) {
        debugPrint("FocusState dispose error: $e");
      }
    }
    profileFocusStates.clear();
    
    for (int i = 0; i < count; i++) {
      profileFocusNodes.add(FocusNode());
      profileFocusStates[i] = false.obs;
    }
    
    if (profileFocusNodes.isNotEmpty) {
      Future.delayed(Duration(milliseconds: 100), () {
        profileFocusNodes[0].requestFocus();
      });
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

  void moveFocusToLogoutButton() {
    logoutButtonFocusNode.requestFocus();
  }

  void moveFocusToAddProfileButton() {
    addProfileFocusNode.requestFocus();
  }

  void moveFocusToFirstProfile() {
    if (profileFocusNodes.isNotEmpty) {
      profileFocusNodes[0].requestFocus();
    }
  }

  void moveFocusToNextProfile() {
    if (profileFocusNodes.isNotEmpty) {
      int currentIndex = -1;
      for (int i = 0; i < profileFocusNodes.length; i++) {
        if (profileFocusNodes[i].hasFocus) {
          currentIndex = i;
          break;
        }
      }
      
      if (currentIndex >= 0) {
        if (currentIndex < profileFocusNodes.length - 1) {
          profileFocusNodes[currentIndex + 1].requestFocus();
        }
        if(currentIndex == profileFocusNodes.length - 1) {
          moveFocusToAddProfileButton();
        }
      } else {
        profileFocusNodes[0].requestFocus();
      }
    }
  }

  void moveFocusToPreviousProfile() {
    if (profileFocusNodes.isNotEmpty) {
      int currentIndex = -1;
      for (int i = 0; i < profileFocusNodes.length; i++) {
        if (profileFocusNodes[i].hasFocus) {
          currentIndex = i;
          break;
        }
      }
      
      if (currentIndex >= 0) {
        if (currentIndex > 0) {
          profileFocusNodes[currentIndex - 1].requestFocus();
        }
      } else {
        profileFocusNodes[0].requestFocus();
      }
    }
  }

  void updateLogoutButtonFocus(bool hasFocus) {
    isLogoutButtonFocused.value = hasFocus;
  }

  @override
  void onClose() {
    // Dispose focus nodes
    logoutButtonFocusNode.dispose();
    for (var focusNode in profileFocusNodes) {
      focusNode.dispose();
    }
    
    // Dispose focus states
    for (var state in profileFocusStates.values) {
      try {
        state.close();
      } catch (e) {
        debugPrint("FocusState dispose error: $e");
      }
    }
    profileFocusStates.clear();
    
    // ... existing dispose code ...
    pinController.dispose();
    lastActiveOTPFocusNode.value.dispose();
    cancelBtnFocus.dispose();
    btnFocus.dispose();
    super.onClose();
  }
}