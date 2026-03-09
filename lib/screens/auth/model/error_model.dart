import 'package:streamit_laravel/screens/devices/model/device_model.dart';

class ErrorModel {
  String error;
  List<DeviceData> otherDevice;

  ErrorModel({
    this.error = "",
    this.otherDevice = const <DeviceData>[],
  });

  factory ErrorModel.fromJson(Map<String, dynamic> json) {
    return ErrorModel(
      error: json['error'] is String ? json['error'] : json['message'] is String ? json['message'] : '',
      otherDevice: json['other_device'] is List ? List<DeviceData>.from(json['other_device'].map((x) => DeviceData.fromJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'other_device': otherDevice.map((e) => e.toJson()).toList(),
    };
  }
}
