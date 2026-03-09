import 'package:streamit_laravel/screens/auth/model/about_page_res.dart';
import 'package:streamit_laravel/screens/devices/model/device_model.dart';

import '../../../subscription/model/subscription_plan_model.dart';

class AccountSettingResponse {
  bool status;
  AccountSettingModel data;
  String message;

  AccountSettingResponse({
    this.status = false,
    required this.data,
    this.message = "",
  });

  factory AccountSettingResponse.fromJson(Map<String, dynamic> json) {
    return AccountSettingResponse(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] is Map ? AccountSettingModel.fromJson(json['data']) : AccountSettingModel(yourDevice: DeviceData(), planDetails: SubscriptionPlanModel()),
      message: json['message'] is String ? json['message'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.toJson(),
      'message': message,
    };
  }
}

class AccountSettingModel {
  SubscriptionPlanModel planDetails;
  String registerMobileNumber;
  DeviceData yourDevice;
  List<DeviceData> otherDevice;
  List<AboutDataModel> pageList;

  AccountSettingModel({
    required this.planDetails,
    this.registerMobileNumber = "",
    required this.yourDevice,
    this.otherDevice = const <DeviceData>[],
    this.pageList = const <AboutDataModel>[],
  });

  factory AccountSettingModel.fromJson(Map<String, dynamic> json) {
    return AccountSettingModel(
      planDetails: json['plan_details'] is Map ? SubscriptionPlanModel.fromJson(json['plan_details']) : SubscriptionPlanModel(),
      registerMobileNumber: json['register_mobile_number'] is String ? json['register_mobile_number'] : "",
      yourDevice: json['device'] is Map ? DeviceData.fromJson(json['device']) : DeviceData(),
      otherDevice: json['other_device'] is List ? List<DeviceData>.from(json['other_device'].map((x) => DeviceData.fromJson(x))) : [],
      pageList: json['page_list'] is List ? List<AboutDataModel>.from(json['page_list'].map((x) => AboutDataModel.fromJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_details': planDetails.toJson(),
      'register_mobile_number': registerMobileNumber,
      'your_device': yourDevice.toJson(),
      'other_device': otherDevice.map((e) => e.toJson()).toList(),
      'page_list': pageList.map((e) => e.toJson()).toList(),
    };
  }
}