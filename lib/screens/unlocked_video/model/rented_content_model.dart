import 'package:streamit_laravel/screens/content/model/content_model.dart';

class RentedContent {
  bool status;
  PayPerView data;

  RentedContent({
    this.status = false,
    required this.data,
  });

  factory RentedContent.fromJson(Map<String, dynamic> json) {
    return RentedContent(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] is Map ? PayPerView.fromJson(json['data']) : PayPerView(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.toJson(),
    };
  }
}

class PayPerView {
  List<PosterDataModel> movies;
  List<PosterDataModel> tvshows;
  List<PosterDataModel> videos;
  List<PosterDataModel> seasons;
  List<PosterDataModel> episodes;

  PayPerView({
    this.movies = const <PosterDataModel>[],
    this.tvshows = const <PosterDataModel>[],
    this.videos = const <PosterDataModel>[],
    this.seasons = const <PosterDataModel>[],
    this.episodes = const <PosterDataModel>[],
  });

  factory PayPerView.fromJson(Map<String, dynamic> json) {
    return PayPerView(
      movies: json['movies'] is List
          ? List<PosterDataModel>.from(json['movies'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
      tvshows: json['tvshows'] is List
          ? List<PosterDataModel>.from(json['tvshows'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
      videos: json['videos'] is List
          ? List<PosterDataModel>.from(json['videos'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
      seasons: json['seasons'] is List
          ? List<PosterDataModel>.from(json['seasons'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
      episodes: json['episodes'] is List
          ? List<PosterDataModel>.from(json['episodes'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movies': movies.map((e) => e.toPosterJson()).toList(),
      'tvshows': tvshows.map((e) => e.toPosterJson()).toList(),
      'videos': videos.map((e) => e.toPosterJson()).toList(),
      'seasons': seasons.map((e) => e.toPosterJson()).toList(),
      'episodes': episodes.map((e) => e.toPosterJson()).toList(),
    };
  }
}
