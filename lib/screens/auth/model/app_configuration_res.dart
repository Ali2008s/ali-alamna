import 'package:nb_utils/nb_utils.dart';

import '../../../utils/constants.dart';

class ConfigurationResponse {
  ApplicationURL applicationURL;
  Currency currency;
  int enableAds;
  String applicationLanguage;
  String appLoader;
  String appLogo;
  String appMiniLogo;
  bool status;
  bool enableMovie;
  bool enableLiveTv;
  bool enableTvShow;
  bool enableVideo;
  bool enableContinueWatch;
  bool enableRateUs;
  List<TaxModel> taxPercentage;
  bool isDeviceSupported;
  bool isLogin;
  bool isCastingAvailable;
  bool isDownloadAvailable;
  bool isOtpLoginEnabled;
  bool isGoogleLoginEnabled;
  bool isAppleSocialLoginEnabled;
  bool isForceUpdate;
  bool enableDemoLogin;
  MobileApp? mobileApp;
  TvApp? tvApp;
  BannerAds bannerAds;
  int forwardSeekSeconds;
  int backwardSeekSeconds;
  String dateFormate;

  ConfigurationResponse({
    required this.applicationURL,
    required this.currency,
    this.enableAds = -1,
    this.applicationLanguage = "",
    this.appLoader = '',
    this.appLogo = '',
    this.appMiniLogo = '',
    this.status = false,
    this.enableMovie = false,
    this.enableTvShow = false,
    this.enableLiveTv = false,
    this.enableVideo = false,
    this.enableContinueWatch = false,
    this.enableRateUs = false,
    this.taxPercentage = const <TaxModel>[],
    this.isDeviceSupported = true,
    this.isLogin = true,
    this.isCastingAvailable = false,
    this.isDownloadAvailable = false,
    this.isGoogleLoginEnabled = true,
    this.isOtpLoginEnabled = true,
    this.isAppleSocialLoginEnabled = true,
    this.isForceUpdate = false,
    this.enableDemoLogin = true,
    this.mobileApp,
    this.tvApp,
    required this.bannerAds,
    this.forwardSeekSeconds = 10,
    this.backwardSeekSeconds = 10,
    this.dateFormate = 'Y-m-d',
  });

  factory ConfigurationResponse.fromJson(Map<String, dynamic> json) {
    return ConfigurationResponse(
      applicationURL: json['application_url'] is Map ? ApplicationURL.fromJson(json['application_url']) : ApplicationURL(mobileAppUrl: MobileAppUrl()),
      currency: json['currency'] is Map ? Currency.fromJson(json['currency']) : Currency(),
      enableAds: json['enable_ads'] is int ? json['enable_ads'] : 0,
      applicationLanguage: json['application_language'] is String ? json['application_language'] : "",
      appLoader: json['app_loader'] is String ? json['app_loader'] : "",
      appLogo: json['app_logo'] is String ? json['app_logo'] : "",
      appMiniLogo: json['app_mini_logo'] is String ? json['app_mini_logo'] : "",
      status: json['status'] is bool ? json['status'] : false,
      enableMovie: json['enable_movie'] is int ? (json['enable_movie'] as int).getBoolInt() : false,
      enableTvShow: json['enable_tvshow'] is int ? (json['enable_tvshow'] as int).getBoolInt() : false,
      enableLiveTv: json['enable_livetv'] is int ? (json['enable_livetv'] as int).getBoolInt() : false,
      enableVideo: json['enable_video'] is int ? (json['enable_video'] as int).getBoolInt() : false,
      enableContinueWatch: json['continue_watch'] is int ? (json['continue_watch'] as int).getBoolInt() : false,
      enableRateUs: json['enable_rate_us'] is int ? (json['enable_rate_us'] as int).getBoolInt() : false,
      taxPercentage: json['tax'] is List ? List<TaxModel>.from(json['tax'].map((x) => TaxModel.fromJson(x))) : [],
      isDeviceSupported: json['is_device_supported'] is int ? (json['is_device_supported'] as int).getBoolInt() : (json['is_device_supported'] is bool ? json['is_device_supported'] : true),
      isLogin: json['is_login'] is bool ? json['is_login'] : json['is_login'] == 1,
      isCastingAvailable: json['is_download_available'] is int ? (json['is_casting_available'] as int).getBoolInt() : false,
      isDownloadAvailable: json['is_download_available'] is int ? (json['is_download_available'] as int).getBoolInt() : false,
      isGoogleLoginEnabled: json['google_login_status'] is int ? (json['google_login_status'] as int).getBoolInt() : false,
      isAppleSocialLoginEnabled: json['apple_login_status'] is int ? (json['apple_login_status'] as int).getBoolInt() : false,
      isOtpLoginEnabled: json['otp_login_status'] is int ? (json['otp_login_status'] as int).getBoolInt() : false,
      isForceUpdate: json['force_update'] is int ? (json['force_update'] as int).getBoolInt() : false,
      enableDemoLogin: json['enable_demo_login'] is int ? (json['enable_demo_login'] as int).getBoolInt() : true,
      mobileApp: json['mobile_app'] is Map ? MobileApp.fromJson(json['mobile_app']) : MobileApp(android: AndroidMobileVersionDetails(), ios: IosMobileVersionDetails()),
      tvApp: json['tv_app'] is Map ? TvApp.fromJson(json['tv_app']) : TvApp(androidTv: AndroidTvVersionDetails()),
      bannerAds: json['banner_ads'] is Map ? BannerAds.fromJson(json['banner_ads']) : BannerAds(),
      forwardSeekSeconds: json['video_forward_seek_seconds'] is int ? json['video_forward_seek_seconds'] : 10,
      backwardSeekSeconds: json['video_backward_seek_seconds'] is int ? json['video_backward_seek_seconds'] : 10,
      dateFormate: json['date_format'] is String ? json['date_format'] : 'Y-m-d',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_app_url': applicationURL.toJson(),
      'currency': currency.toJson(),
      'enable_ads': enableAds,
      'application_language': applicationLanguage,
      'app_loader': appLoader,
      'app_logo': appLogo,
      'app_mini_logo': appMiniLogo,
      'status': status,
      'enable_movie': enableMovie ? 1 : 0,
      'enable_tvshow': enableTvShow ? 1 : 0,
      'enable_livetv': enableLiveTv ? 1 : 0,
      'enable_video': enableVideo ? 1 : 0,
      'continue_watch': enableContinueWatch ? 1 : 0,
      'enable_rate_us': enableRateUs ? 1 : 0,
      'tax': taxPercentage.map((e) => e.toJson()).toList(),
      'is_device_supported': isDeviceSupported,
      'is_login': isLogin ? 1 : 0,
      'is_casting_available': isCastingAvailable ? 1 : 0,
      'mobile_app': mobileApp?.toJson(),
      'tv_app': tvApp?.toJson(),
      'banner_ads': bannerAds.toJson(),
      'is_download_available': isDownloadAvailable ? 1 : 0,
      'google_login_status': isGoogleLoginEnabled ? 1 : 0,
      'apple_login_status': isAppleSocialLoginEnabled ? 1 : 0,
      'otp_login_status': isOtpLoginEnabled ? 1 : 0,
      'force_update': isForceUpdate ? 1 : 0,
      'enable_demo_login': enableDemoLogin ? 1 : 0,
      'video_forward_seek_seconds': forwardSeekSeconds,
      'video_backward_seek_seconds': backwardSeekSeconds,
      'date_format': dateFormate
    };
  }
}

class ApplicationURL {
  MobileAppUrl mobileAppUrl;

  ApplicationURL({required this.mobileAppUrl});

  String get applicationURL => isIOS
      ? mobileAppUrl.appStoreUrl
      : isAndroid
          ? mobileAppUrl.playstoreUrl
          : "";

  factory ApplicationURL.fromJson(Map<String, dynamic> json) {
    return ApplicationURL(
      mobileAppUrl: json['mobile_app'] is Map ? MobileAppUrl.fromJson(json['mobile_app']) : MobileAppUrl(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['mobile_app'] = mobileAppUrl.toJson();
    return data;
  }
}

class MobileAppUrl {
  String playstoreUrl;
  String appStoreUrl;

  MobileAppUrl({this.playstoreUrl = '', this.appStoreUrl = ''});

  factory MobileAppUrl.fromJson(Map<String, dynamic> json) {
    return MobileAppUrl(
      playstoreUrl: json['playstore_url'] is String ? json['playstore_url'] : '',
      appStoreUrl: json['appStore_url'] is String ? json['appStore_url'] : '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['playstore_url'] = playstoreUrl;
    data['appStore_url'] = appStoreUrl;
    return data;
  }
}

class PlatformUrl {
  String mobileAppPlayStoreUrl;
  String mobileAppAppstoreUrl;

  PlatformUrl({
    this.mobileAppPlayStoreUrl = "",
    this.mobileAppAppstoreUrl = "",
  });

  factory PlatformUrl.fromJson(Map<String, dynamic> json) {
    return PlatformUrl(
      mobileAppPlayStoreUrl: json['mobile_app_play_store_url'] is String ? json['mobile_app_play_store_url'] : "",
      mobileAppAppstoreUrl: json['mobile_app_app_store_url'] is String ? json['mobile_app_app_store_url'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile_app_play_store_url': mobileAppPlayStoreUrl,
      'mobile_app_app_store_url': mobileAppAppstoreUrl,
    };
  }
}

class Currency {
  String currencyName;
  String currencySymbol;
  String currencyCode;
  String currencyPosition;
  int noOfDecimal;
  String thousandSeparator;
  String decimalSeparator;

  Currency({
    this.currencyName = "Doller",
    this.currencySymbol = "\$",
    this.currencyCode = "USD",
    this.currencyPosition = CurrencyPosition.CURRENCY_POSITION_LEFT,
    this.noOfDecimal = 2,
    this.thousandSeparator = ",",
    this.decimalSeparator = ".",
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      currencyName: json['currency_name'] is String ? json['currency_name'] : "Doller",
      currencySymbol: json['currency_symbol'] is String ? json['currency_symbol'] : "\$",
      currencyCode: json['currency_code'] is String ? json['currency_code'] : "USD",
      currencyPosition: json['currency_position'] is String ? json['currency_position'] : "left",
      noOfDecimal: json['no_of_decimal'] is int ? json['no_of_decimal'] : 2,
      thousandSeparator: json['thousand_separator'] is String ? json['thousand_separator'] : ",",
      decimalSeparator: json['decimal_separator'] is String ? json['decimal_separator'] : ".",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_name': currencyName,
      'currency_symbol': currencySymbol,
      'currency_code': currencyCode,
      'currency_position': currencyPosition,
      'no_of_decimal': noOfDecimal,
      'thousand_separator': thousandSeparator,
      'decimal_separator': decimalSeparator,
    };
  }
}

class TaxModel {
  int id;
  String title;
  String type;
  num value;

  TaxModel({
    this.id = -1,
    this.title = "",
    this.type = "",
    this.value = -1,
  });

  factory TaxModel.fromJson(Map<String, dynamic> json) {
    return TaxModel(
      id: json['id'] is int ? json['id'] : -1,
      title: json['title'] is String ? json['title'] : "",
      type: json['type'] is String ? json['type'] : "",
      value: json['value'] is num ? json['value'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'value': value,
    };
  }
}

class MobileApp {
  AndroidMobileVersionDetails android;
  IosMobileVersionDetails ios;

  MobileApp({
    required this.android,
    required this.ios,
  });

  factory MobileApp.fromJson(Map<String, dynamic> json) {
    return MobileApp(
      android: json['android'] is Map ? AndroidMobileVersionDetails.fromJson(json['android']) : AndroidMobileVersionDetails(),
      ios: json['ios'] is Map ? IosMobileVersionDetails.fromJson(json['ios']) : IosMobileVersionDetails(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android.toJson(),
      'ios': ios.toJson(),
    };
  }
}

class AndroidMobileVersionDetails {
  String minimumRequiredVersion;
  String latestVersion;

  AndroidMobileVersionDetails({
    this.minimumRequiredVersion = "",
    this.latestVersion = "",
  });

  factory AndroidMobileVersionDetails.fromJson(Map<String, dynamic> json) {
    return AndroidMobileVersionDetails(
      minimumRequiredVersion: json['minimum_required_version'] is String ? json['minimum_required_version'] : "",
      latestVersion: json['latest_version'] is String ? json['latest_version'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum_required_version': minimumRequiredVersion,
      'latest_version': latestVersion,
    };
  }
}

class IosMobileVersionDetails {
  String minimumRequiredVersion;
  String latestVersion;

  IosMobileVersionDetails({
    this.minimumRequiredVersion = "",
    this.latestVersion = "",
  });

  factory IosMobileVersionDetails.fromJson(Map<String, dynamic> json) {
    return IosMobileVersionDetails(
      minimumRequiredVersion: json['minimum_version'] is String ? json['minimum_version'] : "",
      latestVersion: json['latest_version'] is String ? json['latest_version'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum_version': minimumRequiredVersion,
      'latest_version': latestVersion,
    };
  }
}

class TvApp {
  AndroidTvVersionDetails androidTv;

  TvApp({
    required this.androidTv,
  });

  factory TvApp.fromJson(Map<String, dynamic> json) {
    return TvApp(
      androidTv: json['android_tv'] is Map ? AndroidTvVersionDetails.fromJson(json['android_tv']) : AndroidTvVersionDetails(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android_tv': androidTv.toJson(),
    };
  }
}

class AndroidTvVersionDetails {
  String minimumRequiredVersion;
  String latestVersion;

  AndroidTvVersionDetails({
    this.minimumRequiredVersion = "",
    this.latestVersion = "",
  });

  factory AndroidTvVersionDetails.fromJson(Map<String, dynamic> json) {
    return AndroidTvVersionDetails(
      minimumRequiredVersion: json['minimum_required_version'] is String ? json['minimum_required_version'] : "",
      latestVersion: json['latest_version'] is String ? json['latest_version'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum_required_version': minimumRequiredVersion,
      'latest_version': latestVersion,
    };
  }
}

class BannerAds {
  String iosBannerAdId;
  String androidBannerAdId;

  BannerAds({
    this.iosBannerAdId = "",
    this.androidBannerAdId = "",
  });

  factory BannerAds.fromJson(Map<String, dynamic> json) {
    return BannerAds(
      iosBannerAdId: json['ios_banner_ad_id'] is String ? json['ios_banner_ad_id'] : "",
      androidBannerAdId: json['android_banner_ad_id'] is String ? json['android_banner_ad_id'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ios_banner_ad_id': iosBannerAdId,
      'android_banner_ad_id': androidBannerAdId,
    };
  }
}

class PaymentMethodModel {
  bool status;
  String message;
  PaymentMethod data;

  PaymentMethodModel({
    this.status = false,
    this.message = "",
    required this.data,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
      data: json['data'] is Map
          ? PaymentMethod.fromJson(json['data'])
          : PaymentMethod(
              razorPay: RazorPay(),
              stripePay: StripePay(),
              payStackPay: PayStackPay(),
              paypalPay: PaypalPay(),
              flutterWavePay: FlutterwavePay(),
              inAppPurchase: InAppPurchase(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class PaymentMethod {
  RazorPay razorPay;
  StripePay stripePay;
  PayStackPay payStackPay;
  PaypalPay paypalPay;
  FlutterwavePay flutterWavePay;
  InAppPurchase inAppPurchase;

  PaymentMethod({
    required this.razorPay,
    required this.stripePay,
    required this.payStackPay,
    required this.paypalPay,
    required this.flutterWavePay,
    required this.inAppPurchase,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      razorPay: json['razor_pay'] is Map ? RazorPay.fromJson(json['razor_pay']) : RazorPay(),
      stripePay: json['stripe_pay'] is Map ? StripePay.fromJson(json['stripe_pay']) : StripePay(),
      payStackPay: json['paystack_pay'] is Map ? PayStackPay.fromJson(json['paystack_pay']) : PayStackPay(),
      paypalPay: json['paypal_pay'] is Map ? PaypalPay.fromJson(json['paypal_pay']) : PaypalPay(),
      flutterWavePay: json['flutterwave_pay'] is Map ? FlutterwavePay.fromJson(json['flutterwave_pay']) : FlutterwavePay(),
      inAppPurchase: json['in_app_purchase'] is Map ? InAppPurchase.fromJson(json['in_app_purchase']) : InAppPurchase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razor_pay': razorPay.toJson(),
      'stripe_pay': stripePay.toJson(),
      'paystack_pay': payStackPay.toJson(),
      'paypal_pay': paypalPay.toJson(),
      'flutterwave_pay': flutterWavePay.toJson(),
      'in_app_purchase': inAppPurchase.toJson(),
    };
  }
}

class RazorPay {
  String razorpaySecretKey;
  String razorpayPublicKey;

  RazorPay({
    this.razorpaySecretKey = "",
    this.razorpayPublicKey = "",
  });

  factory RazorPay.fromJson(Map<String, dynamic> json) {
    return RazorPay(
      razorpaySecretKey: json['razorpay_secretkey'] is String ? json['razorpay_secretkey'] : "",
      razorpayPublicKey: json['razorpay_publickey'] is String ? json['razorpay_publickey'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razorpay_secretkey': razorpaySecretKey,
      'razorpay_publickey': razorpayPublicKey,
    };
  }
}

class StripePay {
  String stripeSecretKey;
  String stripePublicKey;

  StripePay({
    this.stripeSecretKey = "",
    this.stripePublicKey = "",
  });

  factory StripePay.fromJson(Map<String, dynamic> json) {
    return StripePay(
      stripeSecretKey: json['stripe_secretkey'] is String ? json['stripe_secretkey'] : "",
      stripePublicKey: json['stripe_publickey'] is String ? json['stripe_publickey'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stripe_secretkey': stripeSecretKey,
      'stripe_publickey': stripePublicKey,
    };
  }
}

class PayStackPay {
  String payStackSecretKey;
  String payStackPublicKey;

  PayStackPay({
    this.payStackSecretKey = "",
    this.payStackPublicKey = "",
  });

  factory PayStackPay.fromJson(Map<String, dynamic> json) {
    return PayStackPay(
      payStackSecretKey: json['paystack_secretkey'] is String ? json['paystack_secretkey'] : "",
      payStackPublicKey: json['paystack_publickey'] is String ? json['paystack_publickey'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paystack_secretkey': payStackSecretKey,
      'paystack_publickey': payStackPublicKey,
    };
  }
}

class PaypalPay {
  String paypalSecretKey;
  String paypalClientId;

  PaypalPay({
    this.paypalSecretKey = "",
    this.paypalClientId = "",
  });

  factory PaypalPay.fromJson(Map<String, dynamic> json) {
    return PaypalPay(
      paypalSecretKey: json['paypal_secretkey'] is String ? json['paypal_secretkey'] : "",
      paypalClientId: json['paypal_clientid'] is String ? json['paypal_clientid'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paypal_secretkey': paypalSecretKey,
      'paypal_clientid': paypalClientId,
    };
  }
}

class FlutterwavePay {
  String flutterwaveSecretkey;
  String flutterwavePublickey;

  FlutterwavePay({
    this.flutterwaveSecretkey = "",
    this.flutterwavePublickey = "",
  });

  factory FlutterwavePay.fromJson(Map<String, dynamic> json) {
    return FlutterwavePay(
      flutterwaveSecretkey: json['flutterwave_secretkey'] is String ? json['flutterwave_secretkey'] : "",
      flutterwavePublickey: json['flutterwave_publickey'] is String ? json['flutterwave_publickey'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flutterwave_secretkey': flutterwaveSecretkey,
      'flutterwave_publickey': flutterwavePublickey,
    };
  }
}

class InAppPurchase {
  String entitlementId;
  String appleApiKey;
  String googleApiKey;

  InAppPurchase({
    this.entitlementId = "",
    this.appleApiKey = "",
    this.googleApiKey = "",
  });

  factory InAppPurchase.fromJson(Map<String, dynamic> json) {
    return InAppPurchase(
      entitlementId: json['entitlement_id'] is String ? json['entitlement_id'] : "",
      appleApiKey: json['apple_api_key'] is String ? json['apple_api_key'] : "",
      googleApiKey: json['google_api_key'] is String ? json['google_api_key'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entitlement_id': entitlementId,
      'apple_api_key': appleApiKey,
      'google_api_key': googleApiKey,
    };
  }
}

class CinetPay {
  String cinetSiteid;
  String cinetApiKey;
  String cinetSecretKey;

  CinetPay({
    this.cinetSiteid = "",
    this.cinetApiKey = "",
    this.cinetSecretKey = "",
  });

  factory CinetPay.fromJson(Map<String, dynamic> json) {
    return CinetPay(
      cinetSiteid: json['cinet_siteid'] is String ? json['cinet_siteid'] : "",
      cinetApiKey: json['cinet_api_key'] is String ? json['cinet_api_key'] : "",
      cinetSecretKey: json['cinet_Secret_key'] is String ? json['cinet_Secret_key'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cinet_siteid': cinetSiteid,
      'cinet_api_key': cinetApiKey,
      'cinet_Secret_key': cinetSecretKey,
    };
  }
}

class SadadPay {
  String sadadSadadkey;
  String sadadIdKey;
  String sadadDomain;

  SadadPay({
    this.sadadSadadkey = "",
    this.sadadIdKey = "",
    this.sadadDomain = "",
  });

  factory SadadPay.fromJson(Map<String, dynamic> json) {
    return SadadPay(
      sadadSadadkey: json['sadad_Sadadkey'] is String ? json['sadad_Sadadkey'] : "",
      sadadIdKey: json['sadad_id_key'] is String ? json['sadad_id_key'] : "",
      sadadDomain: json['sadad_Domain'] is String ? json['sadad_Domain'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sadad_Sadadkey': sadadSadadkey,
      'sadad_id_key': sadadIdKey,
      'sadad_Domain': sadadDomain,
    };
  }
}

class AirtelPay {
  String airtelMoneySecretkey;
  String airtelMoneyClientId;

  AirtelPay({
    this.airtelMoneySecretkey = "",
    this.airtelMoneyClientId = "",
  });

  factory AirtelPay.fromJson(Map<String, dynamic> json) {
    return AirtelPay(
      airtelMoneySecretkey: json['airtel_money_secretkey'] is String ? json['airtel_money_secretkey'] : "",
      airtelMoneyClientId: json['airtel_money_client_id'] is String ? json['airtel_money_client_id'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airtel_money_secretkey': airtelMoneySecretkey,
      'airtel_money_client_id': airtelMoneyClientId,
    };
  }
}

class PhonepePay {
  String phonepeAppId;
  String phonepeMerchantId;
  String phonepeSaltKey;
  String phonepeSaltIndex;

  PhonepePay({
    this.phonepeAppId = "",
    this.phonepeMerchantId = "",
    this.phonepeSaltKey = "",
    this.phonepeSaltIndex = "",
  });

  factory PhonepePay.fromJson(Map<String, dynamic> json) {
    return PhonepePay(
      phonepeAppId: json['phonepe_App_id'] is String ? json['phonepe_App_id'] : "",
      phonepeMerchantId: json['phonepe_Merchant_id'] is String ? json['phonepe_Merchant_id'] : "",
      phonepeSaltKey: json['phonepe_salt_key'] is String ? json['phonepe_salt_key'] : "",
      phonepeSaltIndex: json['phonepe_salt_index'] is String ? json['phonepe_salt_index'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phonepe_App_id': phonepeAppId,
      'phonepe_Merchant_id': phonepeMerchantId,
      'phonepe_salt_key': phonepeSaltKey,
      'phonepe_salt_index': phonepeSaltIndex,
    };
  }
}

class MidtransPay {
  String midtransClientId;
  String midtransServerKey;

  MidtransPay({
    this.midtransClientId = "",
    this.midtransServerKey = "",
  });

  factory MidtransPay.fromJson(Map<String, dynamic> json) {
    return MidtransPay(
      midtransClientId: json['midtrans_client_id'] is String ? json['midtrans_client_id'] : "",
      midtransServerKey: json['midtrans_server_key'] is String ? json['midtrans_server_key'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'midtrans_client_id': midtransClientId,
      'midtrans_server_key': midtransServerKey,
    };
  }
}