import 'package:streamit_laravel/screens/content/model/content_model.dart';

class SearchListResponse {
  bool? status;
  List<PosterDataModel>? data;
  String? message;

  SearchListResponse({this.status, this.data, this.message});

  // Factory method to create an instance from a JSON map
  factory SearchListResponse.fromJson(Map<String, dynamic> json) {
    return SearchListResponse(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>).map((e) => PosterDataModel.fromPosterJson(e)).toList(),
      message: json['message'] ?? '',
    );
  }

}