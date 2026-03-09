import 'package:streamit_laravel/screens/content/model/content_model.dart';

class ListResponse {
  bool status;
  String message;
  String name;
  List<PosterDataModel> data;

  ListResponse({
    this.status = false,
    this.message = "",
    this.name = "",
    this.data = const <PosterDataModel>[],
  });

  factory ListResponse.fromJson(Map<String, dynamic> json) {
    return ListResponse(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
      name: json['name'] is String ? json['name'] : '',
      data: json['data'] is List ? List<PosterDataModel>.from(json['data'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'name': name,
      'data': data.map((e) => e.toPosterJson()).toList(),
    };
  }
}

class ThumbnailListResponse {
  bool status;
  String message;
  String name;
  List<PosterDataModel> data;

  ThumbnailListResponse({
    this.status = false,
    this.message = "",
    this.name = "",
    this.data = const <PosterDataModel>[],
  });

  factory ThumbnailListResponse.fromJson(Map<String, dynamic> json) {
    return ThumbnailListResponse(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
      name: json['name'] is String ? json['name'] : '',
      data: json['data'] is List ? List<PosterDataModel>.from(json['data'].map((x) => PosterDataModel.fromThumbnailJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'name': name,
      'data': data.map((e) => e.toPosterJson()).toList(),
    };
  }
}
