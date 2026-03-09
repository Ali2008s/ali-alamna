import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:streamit_laravel/components/app_logo_widget.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/configs.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/country_picker/country_list.dart';
import 'package:streamit_laravel/utils/country_picker/country_utils.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';
import '../../../utils/common_base.dart';
import '../sign_in/sign_in_controller.dart';
import 'component/social_auth.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final SignInController signInController = Get.put(SignInController(), permanent: false);
  final GlobalKey<FormState> _signInformKey = GlobalKey();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      scaffoldBackgroundColor: Colors.transparent,
      topBarBgColor: transparentColor,
      hideAppBar: true,
      hasLeadingWidget: false,
      /* isLoading: signInController.isLoading, */
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(Assets.authBackground, fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: black.withAlpha(100))),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  16.height,
                  Focus(
                    onKeyEvent: (node, event) {
                      try {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            if (signInController.isLeftFormEmail.value) {
                              signInController.emailFocus.requestFocus();
                            } else {
                              signInController.countryCodeFocus.requestFocus();
                            }
                            return KeyEventResult.handled;
                          }
                        }
                      } catch (e) {
                        log('error in Logo KeyboardListener: $e');
                      }
                      return KeyEventResult.ignored;
                    },
                    onFocusChange: (focus) {
                      if (focus) {
                        FocusSoundService.play();
                      }
                    },
                    canRequestFocus: true,
                    focusNode: signInController.logoFocus,
                    child: Align(
                      alignment: Alignment.center,
                      child: DynamicAppLogoWidget(
                        size: const Size(150, 60),
                        image: appConfigs.value.appLogo,
                      ),
                      // CachedImageWidget(url: Assets.assetsAppLogo, height: 60, width: 150),
                    ),
                  ),
                  Text(locale.value.welcomeBackToStreamIt, style: boldTextStyle(size: 20)),
                  8.height,
                  Text(locale.value.weHaveEagerlyAwaitedYourReturn, style: boldTextStyle()),
                  16.height,
                  Row(
                    spacing: 32,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.all(16),
                                decoration: boxDecorationDefault(
                                  borderRadius: radius(12),
                                  color: loginCardColor.withValues(alpha: 0.8),
                                  border: Border.all(color: borderColor, width: 1),
                                ),
                                child: signInController.isLeftFormEmail.value
                                    ? formFieldComponent(context)
                                    : mobileLoginComponentLeft(context),
                              ),
                            ),
                            12.height,
                            Row(
                              children: [
                                Container(height: 1, color: borderColor).expand(),
                                12.width,
                                Text(locale.value.or, style: secondaryTextStyle(size: 12)),
                                12.width,
                                Container(height: 1, color: borderColor).expand(),
                              ],
                            ),
                            12.height,
                            SocialAuthComponent(signInController: signInController),
                            16.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text('${locale.value.bySigningYouAgreeTo} $APP_NAME ', style: boldTextStyle()),
                                    Builder(
                                      builder: (context) {
                                        return Focus(
                                          focusNode: signInController.termsConditionFocus,
                                          canRequestFocus: true,
                                          onFocusChange: (focus) {
                                            if (focus) {
                                              FocusSoundService.play();
                                              Scrollable.ensureVisible(
                                                alignment: 0.01,
                                                context,
                                                duration: Duration(milliseconds: 400),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                            signInController.isTandCFocused(focus);
                                            log("termsConditions btn focus: $focus");
                                          },
                                          onKeyEvent: (node, event) {
                                            try {
                                              if (event is KeyDownEvent) {
                                                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                                  // Move focus to social auth buttons
                                                  if (signInController.isLeftFormEmail.value) {
                                                    signInController.signInBtnFocus.requestFocus();
                                                  } else {
                                                    signInController.getVerificationFocusNode.requestFocus();
                                                  }
                                                  return KeyEventResult.handled;
                                                }
                                                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                                  signInController.privacyPolicyFocus.requestFocus();
                                                  return KeyEventResult.handled;
                                                }
                                                if (event.logicalKey == LogicalKeyboardKey.select ||
                                                    event.logicalKey == LogicalKeyboardKey.enter) {
                                                  commonLaunchUrl(TERMS_CONDITION_URL);
                                                  return KeyEventResult.handled;
                                                }
                                              }
                                            } catch (e) {
                                              log('error in Terms & Conditions KeyboardListener: $e');
                                            }
                                            return KeyEventResult.ignored;
                                          },
                                          child: Obx(
                                            () => InkWell(
                                              onTap: () {
                                                commonLaunchUrl(TERMS_CONDITION_URL);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: signInController.isTandCFocused.value
                                                      ? Border.all(color: white, width: 2)
                                                      : Border.all(color: Colors.transparent, width: 0),
                                                ),
                                                child: Text('${locale.value.termsConditions} ',
                                                    style: boldTextStyle(color: appColorPrimary)),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                    Text(locale.value.ofAll, style: boldTextStyle()).paddingOnly(left: 4),
                                  ],
                                ).center(),
                                4.height,
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text(locale.value.servicesAnd, style: boldTextStyle()),
                                    Builder(
                                      builder: (context) {
                                        return Focus(
                                          focusNode: signInController.privacyPolicyFocus,
                                          canRequestFocus: true,
                                          onFocusChange: (focus) {
                                            if (focus) {
                                              FocusSoundService.play();
                                              Scrollable.ensureVisible(
                                                alignment: 0.01,
                                                context,
                                                duration: Duration(milliseconds: 400),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                            signInController.isPolicyFocused(focus);
                                            log("privacyPolicy btn focus: $focus");
                                          },
                                          onKeyEvent: (node, event) {
                                            try {
                                              if (event is KeyDownEvent) {
                                                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                                  signInController.termsConditionFocus.requestFocus();
                                                  return KeyEventResult.handled;
                                                }
                                                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                                  // Move focus back to social auth buttons or form fields
                                                  if(appConfigs.value.isOtpLoginEnabled) {
                                                    signInController.emailSignINFocusNode.requestFocus();
                                                  } else if(appConfigs.value.isGoogleLoginEnabled) {
                                                    signInController.gSignINFocusNode.requestFocus();
                                                  } else {
                                                    if(signInController.isLeftFormEmail.value){
                                                      signInController.signInBtnFocus.requestFocus();
                                                    } else {
                                                      signInController.getVerificationFocusNode.requestFocus();
                                                    }
                                                  }
                                                  return KeyEventResult.handled;
                                                }
                                                if (event.logicalKey == LogicalKeyboardKey.select ||
                                                    event.logicalKey == LogicalKeyboardKey.enter) {
                                                  commonLaunchUrl(PRIVACY_POLICY_URL);
                                                  return KeyEventResult.handled;
                                                }
                                              }
                                            } catch (e) {
                                              log('error in Privacy Policy KeyboardListener: $e');
                                            }
                                            return KeyEventResult.ignored;
                                          },
                                          child: Obx(
                                            () => InkWell(
                                              onTap: () {
                                                commonLaunchUrl(PRIVACY_POLICY_URL);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: signInController.isPolicyFocused.value
                                                      ? Border.all(color: white, width: 2)
                                                      : Border.all(color: Colors.transparent, width: 0),
                                                ),
                                                child: Text(locale.value.privacyPolicy,
                                                    style: boldTextStyle(color: appColorPrimary)),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                  ],
                                ).center(),
                              ],
                            ).paddingSymmetric(horizontal: 30),
                          ],
                        ),
                      ),
                      Container(height: 375, width: 1, color: borderColor.withValues(alpha: 0.5)),
                      Expanded(
                        child: Obx(
                          () {
                            if (signInController.sessionId.value.isNotEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: boxDecorationDefault(
                                  borderRadius: radius(12),
                                  color: loginCardColor.withValues(alpha: 0.8),
                                  border: Border.all(color: borderColor, width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(locale.value.scanQRBelowToLogin,
                                        style: primaryTextStyle(size: 18, weight: FontWeight.w600),
                                        textAlign: TextAlign.center),
                                    16.height,
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey[300]!, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4)),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: jsonEncode({ 
                                          "session_id": signInController.sessionId.value,
                                          "type": "television",
                                        }),
                                        version: QrVersions.auto,
                                        size: 160.0,
                                        backgroundColor: Colors.white,
                                        dataModuleStyle: QrDataModuleStyle(
                                            color: Colors.black, dataModuleShape: QrDataModuleShape.square),
                                      ),
                                    ),
                                    16.height,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('1. ${locale.value.openTheMobileApp(APP_NAME)}',
                                            style: boldTextStyle(size: 14, color: Colors.grey[300])),
                                        8.height,
                                        Text('2. ${locale.value.goToYourProfile}',
                                            style: boldTextStyle(size: 14, color: Colors.grey[300])),
                                        8.height,
                                        Text('3. ${locale.value.clickOnLinkTvButton}',
                                            style: boldTextStyle(size: 14, color: Colors.grey[300])),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Offstage();
                            } 
                          },
                        ),
                      ),
                    ],
                  ).paddingSymmetric(horizontal: 30),
                  16.height,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileLoginComponentLeft(BuildContext context) {
    return Form(
      key: _signInformKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(locale.value.loginWithOTP, style: primaryTextStyle(size: 16, weight: FontWeight.w600)),
          16.height,
          Obx(
            () {
              return Row(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Focus(
                    onFocusChange: (focus) {
                      if (focus) {
                        FocusSoundService.play();
                      }
                      signInController.isCountryCodeFocused(focus);
                      log("country code focus: $focus");
                    },
                    onKeyEvent: (node, event) {
                      try {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            signInController.changeCountry(context);
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            signInController.logoFocus.requestFocus();
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            signInController.phoneFocus.requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                      } catch (e) {
                        log('error in CountryCode KeyboardListener: $e');
                      }
                      return KeyEventResult.ignored;
                    },
                    canRequestFocus: true,
                    focusNode: signInController.countryCodeFocus,
                    child: Obx(
                      () => Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: backgroundColor.withValues(alpha: 0.8),
                          border: Border.all(
                            color: signInController.isCountryCodeFocused.value ? white : borderColor,
                            width: signInController.isCountryCodeFocused.value ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(signInController.selectedCountry.value.flagEmoji, style: primaryTextStyle(size: 16)),
                            6.width,
                            Text(signInController.countryCode.value, style: primaryTextStyle(color: white, size: 15)),
                            6.width,
                            Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 16)
                          ],
                        ),
                      ),
                    ),
                  ),
                  KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      try {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            signInController.getVerificationFocusNode.requestFocus();
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            // Check if cursor is at the leftmost position (position 0)
                            if (signInController.phoneCont.value.selection.baseOffset == 0) {
                              signInController.countryCodeFocus.requestFocus();
                            }
                          }
                        }
                      } catch (e) {
                        log('error in KeyboardListener: $e');
                      }
                    },
                    child: AppTextField(
                      textStyle: primaryTextStyle(color: white, size: 15),
                      focus: signInController.phoneFocus,
                      controller: signInController.phoneCont,
                      textFieldType: TextFieldType.PHONE,
                      cursorColor: white,
                      maxLength: getValidPhoneNumberLength(
                          CountryModel.fromJson(signInController.selectedCountry.value.toJson())),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (mobileCont) {
                        if (mobileCont!.isEmpty) {
                          return locale.value.phnRequiredText;
                        } else if (!validatePhoneNumberByCountry(signInController.phoneCont.text,
                            CountryModel.fromJson(signInController.selectedCountry.value.toJson()))) {
                          return locale.value.pleaseEnterAValidMobileNo;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintText: locale.value.mobileNumber,
                        hintStyle: secondaryTextStyle(size: 13, color: Colors.grey[600]),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(Assets.iconsIcPhone, color: Colors.grey[600], height: 12, width: 12),
                        ),
                        filled: true,
                        fillColor: backgroundColor.withValues(alpha: 0.8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: white, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColorPrimary.withValues(alpha: 0.5), width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColorPrimary, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                      ),
                      onChanged: (value) {
                        signInController.getBtnEnable();
                      },
                      onFieldSubmitted: (value) {
                        signInController.getVerificationFocusNode.requestFocus();
                      },
                    ),
                  ).expand()
                ],
              );
            },
          ),
          16.height,
          Obx(
            () => Focus(
              focusNode: signInController.getVerificationFocusNode,
              onFocusChange: (value) {
                if (value) {
                  FocusSoundService.play();
                }
                signInController.isGetVerificationBtnFocused(value);
                log("getVerificationCode btn focus: $value");
              },
              onKeyEvent: (node, event) {
                try {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      signInController.phoneFocus.requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      signInController.emailSignINFocusNode.requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                      if (_signInformKey.currentState!.validate()) {
                        hideKeyboard(context);
                        signInController.isPhoneAuthLoading(true);
                        signInController.checkIfDemoUser(
                          callBack: () {
                            signInController.onLoginPressed();
                          },
                        );
                      }
                      return KeyEventResult.handled;
                    }
                  }
                } catch (e) {
                  log('error in getVerificationCode KeyboardListener: $e');
                }
                return KeyEventResult.ignored;
              },
              child: AppButton(
                onTap: () {
                  if (_signInformKey.currentState!.validate()) {
                    hideKeyboard(context);
                    signInController.isPhoneAuthLoading(true);
                    signInController.checkIfDemoUser(
                      callBack: () {
                        signInController.onLoginPressed();
                      },
                    );
                  }
                },
                width: double.infinity,
                padding: EdgeInsets.zero,
                height: Get.height * 0.07,
                // color: signInController.isBtnEnable.isTrue ? Colors.white.withValues(alpha: 0.1) : lightBtnColor,
                textStyle: appButtonTextStyleWhite,
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: signInController.isGetVerificationBtnFocused.value
                      ? BorderSide(color: white, width: 1.5, strokeAlign: BorderSide.strokeAlignOutside)
                      : BorderSide.none,
                ),
                child: Text(locale.value.getVerificationCode, style: boldTextStyle(size: 16, color: white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget formFieldComponent(BuildContext context) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale.value.loginWithEmail,
            style: primaryTextStyle(size: 16, weight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          16.height,
          Focus(
            onFocusChange: (focus) {
              if (focus) {
                FocusSoundService.play();
              }
              signInController.isEmailFocused(focus);
              log("email field focus: $focus");
            },
            onKeyEvent: (node, event) {
              try {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    signInController.passwordFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    signInController.logoFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                }
              } catch (e) {
                log('error in Email KeyboardListener: $e');
              }
              return KeyEventResult.ignored;
            },
            child: AppTextField(
              textStyle: primaryTextStyle(color: white, size: 15),
              controller: signInController.emailCont,
              focus: signInController.emailFocus,
              nextFocus: signInController.passwordFocus,
              textFieldType: TextFieldType.EMAIL_ENHANCED,
              cursorColor: white,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return locale.value.emailIsARequiredField;
                } else if (!value.isValidEmail()) {
                  return locale.value.pleaseEnterValidEmailAddress;
                }
                return null;
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                hintText: locale.value.email,
                hintStyle: secondaryTextStyle(size: 13, color: Colors.grey[600]),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.email_outlined, color: Colors.grey[600], size: 16),
                ),
                filled: true,
                fillColor: backgroundColor.withValues(alpha: 0.8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: white, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColorPrimary.withValues(alpha: 0.5), width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColorPrimary, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
              ),
              onFieldSubmitted: (p0) {
                signInController.passwordFocus.requestFocus();
              },
              onChanged: (value) {
                signInController.getBtnEnable();
              },
            ),
          ),
          16.height,
          Focus(
            onFocusChange: (focus) {
              if (focus) {
                FocusSoundService.play();
              }
              signInController.isPasswordFocused(focus);
              log("password field focus: $focus");
            },
            onKeyEvent: (node, event) {
              try {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    signInController.signInBtnFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    signInController.emailFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                }
              } catch (e) {
                log('error in Password KeyboardListener: $e');
              }
              return KeyEventResult.ignored;
            },
            child: AppTextField(
              suffix: Offstage(),
              textStyle: primaryTextStyle(color: white, size: 15),
              nextFocus: signInController.signInBtnFocus,
              controller: signInController.passwordCont,
              focus: signInController.passwordFocus,
              obscureText: true,
              textFieldType: TextFieldType.PASSWORD,
              cursorColor: white,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                hintText: locale.value.password,
                hintStyle: secondaryTextStyle(size: 13, color: Colors.grey[600]),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.lock_outline, color: Colors.grey[600], size: 16),
                ),
                filled: true,
                fillColor: backgroundColor.withValues(alpha: 0.8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: white, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColorPrimary.withValues(alpha: 0.5), width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColorPrimary, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
              ),
              onFieldSubmitted: (p0) {
                signInController.signInBtnFocus.requestFocus();
              },
              onChanged: (value) {
                signInController.getBtnEnable();
              },
            ),
          ),
          16.height,
          Focus(
            focusNode: signInController.signInBtnFocus,
            onFocusChange: (focus) {
              if (focus) {
                FocusSoundService.play();
              }
              signInController.isSignInBtnFocused(focus);
              log("sign in btn focus: $focus");
            },
            onKeyEvent: (node, event) {
              try {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    signInController.passwordFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if(appConfigs.value.isOtpLoginEnabled) {
                      signInController.emailSignINFocusNode.requestFocus();
                    } else if(appConfigs.value.isGoogleLoginEnabled) {
                      signInController.gSignINFocusNode.requestFocus();
                    } else {
                      signInController.termsConditionFocus.requestFocus();
                    }
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                    if (_emailFormKey.currentState!.validate()) {
                      signInController.saveForm(isNormalLogin: true);
                    }
                    return KeyEventResult.handled;
                  }
                }
              } catch (e) {
                log('error in SignIn Button KeyboardListener: $e');
              }
              return KeyEventResult.ignored;
            },
            child: Obx(
              () => AppButton(
                padding: EdgeInsets.zero,
                height: Get.height * 0.07,
                width: double.infinity,
                color: appColorPrimary,
                textStyle: appButtonTextStyleWhite,
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: signInController.isSignInBtnFocused.value
                      ? BorderSide(color: white, width: 1.5, strokeAlign: BorderSide.strokeAlignOutside)
                      : BorderSide.none,
                ),
                child: Text(locale.value.signIn, style: boldTextStyle(size: 16, color: white)),
                onTap: () {
                  if (_emailFormKey.currentState!.validate()) {
                    signInController.saveForm(isNormalLogin: true);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
