import 'package:streamit_laravel/screens/content/model/content_model.dart';

class CastResponse {
  bool status;
  String message;
  String? name;
  List<Cast> data;

  CastResponse({
    this.status = false,
    this.message = "",
    this.name = '',
    this.data = const <Cast>[],
  });

  factory CastResponse.fromJson(Map<String, dynamic> json) {
    return CastResponse(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
      name: json['name'] is String ? json['name'] : '',
      data: json['data'] is List ? List<Cast>.from(json['data'].map((x) => Cast.fromListJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'name': name,
      'data': data.map((e) => e.toListJson()).toList(),
    };
  }
}