// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:ui';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/network/auth_apis.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_screen.dart';

import '../../../configs.dart';
import '../../../main.dart';
import '../../../network/core_api.dart';
import '../../../utils/app_common.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../../utils/country_picker/country_code.dart';
import '../../../utils/firebase_phone_auth/firebase_auth_util.dart';
import '../../../utils/firebase_phone_auth/firebase_excauth_exception_utils.dart';
import '../components/device_list_component.dart';
import '../components/otp_verify_component.dart';
import '../model/error_model.dart';
import '../model/login_response.dart';
import '../services/social_logins.dart';

class SignInController extends GetxController {
  RxBool isNavigateToDashboard = true.obs;
  final GlobalKey<FormState> signInformKey = GlobalKey();
  RxBool isPhoneAuthLoading = false.obs;
  RxBool isOTPSent = false.obs;
  RxBool isVerifyBtn = false.obs;
  RxBool isBtnEnable = false.obs;
  RxBool isRememberMe = true.obs;
  RxBool isLoading = false.obs;
  RxBool isEmailFocused = false.obs;
  RxBool isPasswordFocused = false.obs;
  RxBool isSignInBtnFocused = false.obs;

  RxBool isPhoneLogin = false.obs;
  RxBool isLeftFormEmail = appConfigs.value.isOtpLoginEnabled ? false.obs : true.obs;

  RxString countryCode = "+91".obs;
  RxBool isOTPVerify = false.obs;

  Rx<String> verificationCode = ''.obs;
  Rx<String> verificationId = ''.obs;
  Rx<String> mobileNo = ''.obs;
  Rx<Timer> codeResendTimer = Timer(const Duration(), () {}).obs;
  Rx<int> codeResendTime = 0.obs;

  set setCodeResendTime(int time) {
    codeResendTime(time);
  }

  TextEditingController phoneCont = TextEditingController();
  TextEditingController countryCodeCont = TextEditingController();
  TextEditingController verifyCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  Rx<Country> selectedCountry = defaultCountry.obs;

  FocusNode phoneFocus = FocusNode();
  FocusNode countryCodeFocus = FocusNode();
  FocusNode getVerificationFocusNode = FocusNode();
  FocusNode phoneSignINFocusNode = FocusNode();
  FocusNode emailSignINFocusNode = FocusNode();
  FocusNode gSignINFocusNode = FocusNode();
  FocusNode qrSignINFocusNode = FocusNode();
  FocusNode aSignINFocusNode = FocusNode();
  FocusNode resendBtnFocusNode = FocusNode();
  FocusNode verifyOTPBtnFocusNode = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode signInBtnFocus = FocusNode();
  FocusNode logoFocus = FocusNode();
  FocusNode termsConditionFocus = FocusNode();
  FocusNode privacyPolicyFocus = FocusNode();

  // Focus handles for Tv app
  final RxBool isCountryCodeFocused = false.obs;
  final RxBool isTandCFocused = false.obs;
  final RxBool isGetVerificationBtnFocused = false.obs;
  final RxBool isPolicyFocused = false.obs;
  final RxBool isOTPVerifyBtnFocused = false.obs;
  final RxBool isResendOtpBtnFocused = false.obs;
  final RxBool isEmailSignInBtnFocused = false.obs;
  final RxBool isGoogleSignInBtnFocused = false.obs;

  /// Generate QR Code
  RxString sessionId = ''.obs;
  Timer? qrTimer;
  Timer? pollingTimer;

  Rx<LoginType> selectedLoginType = LoginType.qr.obs;

  @override
  void onInit() {
    if (Get.arguments is bool) {
      isNavigateToDashboard(Get.arguments);
    }
    init();
    getBtnEnable();

    super.onInit();
  }

  @override
  void onReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedLoginType.value == LoginType.qr) {
        handleQrLogin();
      }
    });
    // Focus on appropriate field based on left form type
    if (isLeftFormEmail.value) {
      // Email form is active
      if (emailCont.text.isEmpty) {
        emailFocus.requestFocus();
      } else if (passwordCont.text.isEmpty) {
        passwordFocus.requestFocus();
      } else {
        signInBtnFocus.requestFocus();
      }
    } else {
      // OTP form is active (default)
      countryCodeFocus.requestFocus();
    }

    super.onReady();
  }

  Future<void> init() async {
    if (await isIqonicProduct) {
      phoneCont.text = '1234567890';
      emailCont.text = Constants.DEFAULT_EMAIL;
      passwordCont.text = Constants.DEFAULT_PASS;
      signInBtnFocus.requestFocus();
      getBtnEnable();
    }
  }

  void getBtnEnable() {
    if (phoneCont.text.isNotEmpty && phoneCont.text.isNotEmpty) {
      isBtnEnable(true);
    } else {
      isBtnEnable(false);
    }
  }

  void toggleLeftFormType() {
    isLeftFormEmail(!isLeftFormEmail.value);
    // Focus on appropriate field after toggle
    if (isLeftFormEmail.value) {
      // Switched to Email form
      emailFocus.requestFocus();
    } else {
      // Switched to OTP form
      countryCodeFocus.requestFocus();
    }
  }

  void handleSocialButtonUpArrow() {
    if (isLeftFormEmail.value) {
      // If Email form is active, go to Sign In button
      signInBtnFocus.requestFocus();
    } else {
      // If OTP form is active, go to Get Verification Code button
      getVerificationFocusNode.requestFocus();
    }
  }

  void handleSocialButtonLeftArrow(FocusNode currentFocusNode) {
    if (currentFocusNode == gSignINFocusNode) {
      if(!appConfigs.value.isOtpLoginEnabled) return;
      emailSignINFocusNode.requestFocus();
    }
  }

  void handleSocialButtonRightArrow(FocusNode currentFocusNode) {
    if (currentFocusNode == emailSignINFocusNode) {
      if(!appConfigs.value.isGoogleLoginEnabled) return;
      gSignINFocusNode.requestFocus();
    }
  }

  void getVerifyBtnEnable() {
    if (verifyCont.text.isNotEmpty && verifyCont.text.length == 6) {
      hideKeyBoardWithoutContext();
      isVerifyBtn(true);
    } else {
      isVerifyBtn(false);
    }
  }

  Future<void> isDemoUser({bool verify = false}) async {
    isLoading(true);

    Future.delayed(
      Duration(seconds: 2),
      () {
        if (verify) {
          isOTPVerify(true);
          isLoading(false);
          phoneSignIn();
        } else {
          isOTPSent(true);
          verificationId('');
          mobileNo(phoneCont.text);
          countryCode(countryCode.value);
          initializeCodeResendTimer;
          isLoading(false);
          Get.to(
            () => OTPVerifyComponent(
              mobileNo: "$countryCode${phoneCont.text}",
            ),
          )?.then((value) {
            if (Get.context != null) {
              FocusScope.of(Get.context!).requestFocus(phoneFocus);
            }
            isLoading(false);
          });
        }
      },
    );
  }

  Future<void> checkIfDemoUser({bool verify = false, required VoidCallback callBack}) async {
    if (phoneCont.text.trim() == Constants.demoNumber) {
      isDemoUser(verify: verify);
    } else {
      callBack.call();
    }
  }

  Future<void> onLoginPressed() async {
    isLoading(true);
    isOTPSent(false);
    final firebaseAuthUtil = FirebaseAuthUtil();

    try {
      firebaseAuthUtil.login(
          mobileNumber: "$countryCode${phoneCont.text}",
          onCodeSent: (value) {
            isOTPSent(true);
            verificationId(value);
            mobileNo(phoneCont.text);
            countryCode(countryCode.value);
            initializeCodeResendTimer;
            isLoading(false);
            Get.to(
              () => OTPVerifyComponent(
                mobileNo: "$countryCode${phoneCont.text}",
              ),
            )?.then((value) {
              phoneFocus.requestFocus();
              isLoading(false);
            });
          },
          onVerificationFailed: (value) {
            isOTPSent(false);
            isPhoneAuthLoading(false);
            isLoading(false);
            errorSnackBar(error: FirebaseAuthHandleExceptionsUtils().handleException(value));
          });
    } catch (e) {
      isLoading(false);
      isOTPSent(false);
      errorSnackBar(error: e);
    }
  }

  Future<void> changeCountry(BuildContext context) async {
    showCustomCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        margin: const EdgeInsets.only(top: 80),
        bottomSheetHeight: Get.height * 0.86,
        backgroundColor: btnColor,
        padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
        textStyle: secondaryTextStyle(color: white),
        searchTextStyle: primaryTextStyle(color: white),
        inputDecoration: InputDecoration(
          labelStyle: secondaryTextStyle(color: white),
          labelText: locale.value.searchHere,
          prefixIcon: const Icon(
            Icons.search,
            color: white,
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: white),
          ),
        ),
      ),

      showPhoneCode: true, // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        countryCode("+${country.phoneCode}");
        selectedCountry(country);
        log(country.flagEmoji);
      },
    );
  }

  Future<void> loginAPICall({
    required Map<String, dynamic> request,
    required bool isSocialLogin,
    bool isNormalLogin = false,
  }) async {
    await AuthServiceApis.loginUser(request: request, isSocialLogin: isSocialLogin).then((value) async {
      handleLoginResponse(isSocialLogin: isSocialLogin, isNormalLogin: isNormalLogin, loginResponse: value);
    }).catchError((e) async {
      if (e.toString().startsWith('404')) {
        toast("User not found. Please create an account using the mobile app or web.");
      } else {
        isLoading(false);
        Get.back();
        errorSnackBar(error: e);
        if (e is Map<String, dynamic> &&
            e.containsKey('status_code') &&
            e['status_code'] == 406 &&
            e.containsKey('response')) {
          ErrorModel errorData = ErrorModel.fromJson(e['response']);
          Get.bottomSheet(
            isDismissible: true,
            isScrollControlled: true,
            enableDrag: false,
            DeviceListComponent(
              loggedInDeviceList: errorData.otherDevice,
              onLogout: (logoutAll, deviceId, deviceName) {
                Get.back();
                if (logoutAll) {
                  logOutAll(errorData.otherDevice.first.userId);
                } else {
                  deviceLogOut(device: deviceId, userId: errorData.otherDevice.first.userId);
                }
              },
            ),
          );
        }
      }
    });
  }

  Future<void> saveForm({bool isNormalLogin = false}) async {
    if (isLoading.isTrue) return;

    hideKeyBoardWithoutContext();
    isLoading(true);
    Map<String, dynamic> req = {
      'email': emailCont.text.trim(),
      'password': passwordCont.text.trim(),
      'device_id': currentDevice.value.deviceId,
      'device_name': currentDevice.value.deviceName,
      'platform': currentDevice.value.platform,
    };

    await loginAPICall(isSocialLogin: false, request: req, isNormalLogin: isNormalLogin);
  }

  Future<void> phoneSignIn() async {
    if (isLoading.value) return;

    isLoading(true);
    Map<String, dynamic> request = {
      UserKeys.username: "${countryCode.value}${mobileNo.value.trim()}",
      UserKeys.password: "${countryCode.value}${mobileNo.value.trim()}",
      UserKeys.mobile: "${countryCode.value}${mobileNo.value.trim()}",
      'device_id': currentDevice.value.deviceId,
      'device_name': currentDevice.value.deviceName,
      'platform': currentDevice.value.platform,
      UserKeys.loginType: LoginTypeConst.LOGIN_TYPE_OTP,
    };

    await loginAPICall(isSocialLogin: true, request: request);
  }

  void get initializeCodeResendTimer {
    codeResendTimer.value.cancel();
    codeResendTime(60);
    codeResendTimer.value = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (codeResendTime > 0) {
        setCodeResendTime = --codeResendTime.value;
      } else {
        timer.cancel();
      }
    });
  }

  void onVerifyPressed() async {
    final firebaseAuthUtil = FirebaseAuthUtil();
    isLoading(true);
    isVerifyBtn(false);
    try {
      await firebaseAuthUtil.verifyOTPCode(
          verificationId: verificationId.value,
          verificationCode: verifyCont.text,
          onVerificationSuccess: (value) {
            log("Phone Auth Completed");
            isOTPVerify(true);
            isLoading(false);
            phoneSignIn();
          },
          onCodeVerificationFailed: (value) {
            isLoading(false);
            verifyCont.clear();

            Get.back();
            verifyCont.text = '';
            Get.to(
              () => OTPVerifyComponent(
                mobileNo: "$countryCode${phoneCont.text}",
              ),
            );
            errorSnackBar(error: value);
          });
    } catch (error) {
      isLoading(false);
      verifyCont.clear();

      Get.back();
      Get.bottomSheet(
        isDismissible: false,
        isScrollControlled: false,
        enableDrag: false,
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: OTPVerifyComponent(
            mobileNo: mobileNo.value,
          ),
        ),
      );
      errorSnackBar(error: error);
    }
  }

  Future<void> reSendOTP() async {
    if (isLoading.value) {
      return;
    }
    final firebaseAuthUtil = FirebaseAuthUtil();
    isLoading(true);
    firebaseAuthUtil.login(
        mobileNumber: "${countryCode.value}${mobileNo.value}",
        onCodeSent: (value) {
          initializeCodeResendTimer;
          isLoading(false);
          verificationId(value);
        },
        onVerificationFailed: (value) {
          isLoading(false);
          verifyCont.clear();
          errorSnackBar(error: FirebaseAuthHandleExceptionsUtils().handleException(value));
        });
  }

  Future<void> googleSignIn() async {
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.first == ConnectivityResult.none) {
      toast(locale.value.yourInternetIsNotWorking, print: true);
      return;
    }

    isLoading(true);
    await GoogleSignInAuthService.signInWithGoogle().then((value) async {
      Map<String, dynamic> request = {
        UserKeys.email: value.email,
        UserKeys.password: value.email,
        UserKeys.firstName: value.firstName,
        UserKeys.lastName: value.lastName,
        UserKeys.mobile: value.mobile,
        UserKeys.fileUrl: value.profileImage,
        'device_id': currentDevice.value.deviceId,
        'device_name': currentDevice.value.deviceName,
        'platform': currentDevice.value.platform,
        UserKeys.loginType: LoginTypeConst.LOGIN_TYPE_GOOGLE,
      };
      log('signInWithGoogle REQUEST: $request');

      await loginAPICall(request: request, isSocialLogin: true);
    }).catchError((e) {
      isLoading(false);
      log("Error is $e");
      toast(e.toString(), print: true);
    });
  }

  void handleLoginResponse(
      {required UserData loginResponse, String? password, bool isSocialLogin = false, bool isNormalLogin = false}) {
    try {
      setValue(SharedPreferenceConst.IS_LOGGED_IN, true);
      setValue(SharedPreferenceConst.IS_REMEMBER_ME, isRememberMe.value);

      AuthServiceApis.storeUserData(loginResponse);

      isLoggedIn(true);
      qrTimer?.cancel();

      Get.offAll(() => WatchingProfileScreen(), binding: BindingsBuilder(() {
        Get.isRegistered<WatchingProfileController>()
            ? Get.find<WatchingProfileController>()
            : Get.put(WatchingProfileController(navigateToDashboard: isNavigateToDashboard.value));
      }));

      isLoading(false);
    } catch (e) {
      log("Error  ==> $e");
    }
  }

  Future<void> deviceLogOut({required String device, required int userId}) async {
    removeKey(SharedPreferenceConst.IS_PROFILE_ID);
    isLoading(true);
    await AuthServiceApis.deviceLogoutApiWithoutAuth(deviceId: device, userId: userId).then((value) {
      successSnackBar(value.message);
    }).catchError((e) {
      toast(e.toString(), print: true);
    }).whenComplete(() {
      isLoading(false);
    });
  }

  Future<void> logOutAll(int userId) async {
    Get.back();
    if (isLoading.value) return;
    isLoading(true);
    await AuthServiceApis.logOutAllAPIWithoutAuth(userId: userId).then((value) async {
      successSnackBar(value.message);
      Get.back();
    }).catchError((e) {
      errorSnackBar(error: e);
    }).whenComplete(() {
      isLoading(false);
    });
  }

  //region for QR Code
  Future<void> handleQrLogin() async {
    isLoading(true);
    await getSessionId();
    startQRRefreshTimer();
    isLoading(false);
  }

  void startQRRefreshTimer() {
    if (qrTimer != null && qrTimer!.isActive) {
      qrTimer?.cancel();
    }
    qrTimer = Timer.periodic(const Duration(minutes: 3), (_) async {
      if (!isLoggedIn.value) {
        await getSessionId();
      }
    });
  }

  Future<void> getSessionId() async {
    await CoreServiceApis.initiateSession().then((value) async {
      isLoading(false);
      sessionId(value.sessionId);
      if (pollingTimer == null) {
        startPolling();
      }
    }).whenComplete(() {
      isLoading(false);
    }).catchError((e) {
      isLoading(false);
    });
  }

  void startPolling({
    String? logoutSessionId,
  }) async {
    if (sessionId.value.isEmpty) {
      return;
    }

    pollingTimer?.cancel();

    const interval = Duration(seconds: 5);

    pollingTimer = Timer.periodic(interval, (timer) async {
      if (isLoggedIn.value) {
        timer.cancel();
        pollingTimer?.cancel();
        return;
      }
      
      final previousSessionId = sessionId.value;

      /// TV Session Check API
      await CoreServiceApis.tvSessionCheck(sessionId: logoutSessionId ?? sessionId.value).then((value) async {
        isLoading(false);
        if (value.userData.id > -1) {
          successSnackBar(value.message);
          handleLoginResponse(loginResponse: value.userData);
          pollingTimer?.cancel();
          timer.cancel();
        }
      }).catchError((e) async {
        isLoading(false);
        if (e.toString().startsWith('404')) {
          toast("User not found. Please create an account using the mobile app or web.");
        } else {
          if (e is Map<String, dynamic> &&
              e.containsKey('status_code') &&
              e['status_code'] == 406) {
            pollingTimer = null;
            timer.cancel();
            errorSnackBar(error: e);
            handleQrLogin();
            ErrorModel errorData = ErrorModel.fromJson(e);
            Get.bottomSheet(
              isDismissible: true,
              isScrollControlled: true,
              enableDrag: false,
              DeviceListComponent(
                loggedInDeviceList: errorData.otherDevice,
                onLogout: (logoutAll, deviceId, deviceName) async {
                  Get.back();
                  if (logoutAll) {
                    await logOutAll(errorData.otherDevice.first.userId);
                  } else {
                    await deviceLogOut(device: deviceId, userId: errorData.otherDevice.first.userId);
                  }
                  startPolling(logoutSessionId: previousSessionId);
                },
              ),
            );
          }
        }
      });
    });
  }

  // endRegion

  @override
  void onClose() {
    qrTimer?.cancel();
    pollingTimer?.cancel();
    super.onClose();
  }
}
