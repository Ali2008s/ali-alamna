import 'package:streamit_laravel/screens/content/model/content_model.dart';

class SearchResponse {
  bool status;
  String message;
  List<PosterDataModel> movieList;
  List<PosterDataModel> tvShowList;
  List<PosterDataModel> videoList;
  List<PosterDataModel> seasonList;

  SearchResponse({
    this.status = false,
    this.message = "",
    this.movieList = const <PosterDataModel>[],
    this.tvShowList = const <PosterDataModel>[],
    this.videoList = const <PosterDataModel>[],
    this.seasonList = const <PosterDataModel>[],
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
      movieList: json['movieList'] is List ? List<PosterDataModel>.from(json['movieList'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      tvShowList: json['tvshowList'] is List ? List<PosterDataModel>.from(json['tvshowList'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      videoList: json['videoList'] is List ? List<PosterDataModel>.from(json['videoList'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      seasonList: json['seasonList'] is List ? List<PosterDataModel>.from(json['seasonList'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'movieList': movieList.map((e) => e.toPosterJson()).toList(),
      'tvshowList': tvShowList.map((e) => e.toPosterJson()).toList(),
      'videoList': videoList.map((e) => e.toPosterJson()).toList(),
      'seasonList': seasonList.map((e) => e.toPosterJson()).toList(),
    };
  }
}
