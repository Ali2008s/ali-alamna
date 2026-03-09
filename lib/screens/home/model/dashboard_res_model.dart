import 'package:flutter/material.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/watch_list/model/watch_list_resp.dart';

import '../../genres/model/genres_model.dart';
import '../../person/model/person_model.dart';

class DashboardDetailResponse {
  bool status;
  String message;
  DashboardModel data;

  DashboardDetailResponse({
    this.status = false,
    this.message = "",
    required this.data,
  });

  factory DashboardDetailResponse.fromJson(Map<String, dynamic> json) {
    return DashboardDetailResponse(
      status: json['status'] is bool ? json['status'] : false,
      message: json['message'] is String ? json['message'] : "",
      data: json['data'] is Map ? DashboardModel.fromJson(json['data']) : DashboardModel(),
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

class DashboardModel {
  bool isContinueWatch;
  bool isEnableBanner;
  List<PosterDataModel> continueWatch;
  ListResponse? top10List;
  ListResponse? latestList;
  ListResponse? topChannelList;
  ListResponse? popularMovieList;
  ListResponse? popularTvShowList;
  ListResponse? popularVideoList;
  ListResponse? freeMovieList;
  GenresResponse? genreList;
  LanguageResponse? popularLanguageList;
  CastResponse? actorList;
  List<PosterDataModel> likeMovieList;
  List<PosterDataModel> viewedMovieList;
  List<PosterDataModel> trendingMovieList;
  List<PosterDataModel> trendingInCountryMovieList;
  List<PosterDataModel> basedOnLastWatchMovieList;
  List<GenreModel> favGenreList;
  List<Cast> favActorList;
  List<PosterDataModel> payPerView;
  List<OtherSectionModel> otherSection;

  DashboardModel({
    this.isContinueWatch = false,
    this.isEnableBanner = false,
    this.continueWatch = const <PosterDataModel>[],
    this.top10List,
    this.latestList,
    this.topChannelList,
    this.popularMovieList,
    this.popularTvShowList,
    this.popularVideoList,
    this.freeMovieList,
    this.genreList,
    this.popularLanguageList,
    this.actorList,
    this.likeMovieList = const <PosterDataModel>[],
    this.viewedMovieList = const <PosterDataModel>[],
    this.trendingMovieList = const <PosterDataModel>[],
    this.trendingInCountryMovieList = const <PosterDataModel>[],
    this.basedOnLastWatchMovieList = const <PosterDataModel>[],
    this.favActorList = const <Cast>[],
    this.favGenreList = const <GenreModel>[],
    this.payPerView = const <PosterDataModel>[],
    this.otherSection = const <OtherSectionModel>[],
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      isContinueWatch: json['is_continue_watch'] is int
          ? json['is_continue_watch'] == 1
              ? true
              : false
          : false,
      isEnableBanner: json['is_enable_banner'] is int
          ? json['is_enable_banner'] == 1
              ? true
              : false
          : false,
      continueWatch: json['continue_watch'] is List ? List<PosterDataModel>.from(json['continue_watch'].map((x) => PosterDataModel.fromThumbnailJson(x))) : [],
      top10List: json['top_10'] is Map ? ListResponse.fromJson(json['top_10']) : ListResponse(data: []),
      latestList: json['latest_movie'] is Map ? ListResponse.fromJson(json['latest_movie']) : ListResponse(data: []),
      topChannelList: json['top_channel'] is Map ? ListResponse.fromJson(json['top_channel']) : ListResponse(data: []),
      popularMovieList: json['popular_movie'] is Map ? ListResponse.fromJson(json['popular_movie']) : ListResponse(data: []),
      popularTvShowList: json['popular_tvshow'] is Map ? ListResponse.fromJson(json['popular_tvshow']) : ListResponse(data: []),
      popularVideoList: json['popular_videos'] is Map ? ListResponse.fromJson(json['popular_videos']) : ListResponse(data: []),
      freeMovieList: json['free_movie'] is Map ? ListResponse.fromJson(json['free_movie']) : ListResponse(data: []),
      genreList: json['genres'] is Map ? GenresResponse.fromJson(json['genres']) : GenresResponse(data: []),
      popularLanguageList: json['popular_language'] is Map ? LanguageResponse.fromJson(json['popular_language']) : LanguageResponse(languageList: []),
      actorList: json['personality'] is Map ? CastResponse.fromJson(json['personality']) : CastResponse(data: []),
      favActorList: json['favorite_personality'] is List ? List<Cast>.from(json['favorite_personality'].map((x) => Cast.fromListJson(x))) : [],
      likeMovieList: json['based_on_likes'] is List ? List<PosterDataModel>.from(json['based_on_likes'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      viewedMovieList: json['based_on_views'] is List ? List<PosterDataModel>.from(json['based_on_views'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      basedOnLastWatchMovieList: json['base_on_last_watch'] is List ? List<PosterDataModel>.from(json['base_on_last_watch'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      trendingMovieList: json['trending_movies'] is List ? List<PosterDataModel>.from(json['trending_movies'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      trendingInCountryMovieList: json['trending_in_country'] is List ? List<PosterDataModel>.from(json['trending_in_country'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      favGenreList: json['favorite_gener'] is List ? List<GenreModel>.from(json['favorite_gener'].map((x) => GenreModel.fromJson(x))) : [],
      payPerView: json['pay_per_view'] is List ? List<PosterDataModel>.from(json['pay_per_view'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
      otherSection: json['other_section'] is List ? List<OtherSectionModel>.from(json['other_section'].map((x) => OtherSectionModel.fromJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'continue_watch': continueWatch.map((e) => e.toThumbnailJson()).toList(),
      'top_10': top10List?.toJson(),
      'based_on_likes': likeMovieList.map((e) => e.toPosterJson()).toList(),
      'based_on_views': viewedMovieList.map((e) => e.toPosterJson()).toList(),
      'base_on_last_watch': basedOnLastWatchMovieList.map((e) => e.toPosterJson()).toList(),
      'latest_movie': latestList?.toJson(),
      'top_channel': topChannelList?.toJson(),
      'popular_movie': popularMovieList?.toJson(),
      'popular_tvshow': popularTvShowList?.toJson(),
      'popular_videos': popularVideoList?.toJson(),
      'trending_movies': trendingMovieList.map((e) => e.toPosterJson()).toList(),
      'trending_in_country': trendingInCountryMovieList.map((e) => e.toPosterJson()).toList(),
      'pay_per_view': payPerView.map((e) => e.toPosterJson()).toList(),
      'free_movie': freeMovieList?.toJson(),
      'genres': genreList?.toJson(),
      'popular_language': popularLanguageList?.toJson(),
      'personality': actorList?.toJson(),
      'favorite_genres': favGenreList.map((e) => e.toJson()).toList(),
      'favorite_personality': favActorList.map((e) => e.toListJson()).toList(),
      'other_section': otherSection.map((e) => e.toJson()).toList(),
    };
  }
}

class SliderResponse {
  bool status;
  SliderData data;
  String message;

  SliderResponse({
    this.status = false,
    required this.data,
    this.message = "",
  });

  factory SliderResponse.fromJson(Map<String, dynamic> json) {
    return SliderResponse(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] is Map ? SliderData.fromJson(json['data']) : SliderData(),
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

class SliderData {
  List<PosterDataModel> slider;
  int unreadNotificationCount;

  SliderData({
    this.slider = const <PosterDataModel>[],
    this.unreadNotificationCount = -1,
  });

  factory SliderData.fromJson(Map<String, dynamic> json) {
    return SliderData(
      slider: json['slider'] is List ? List<PosterDataModel>.from(json['slider'].map((x) => PosterDataModel.fromSliderJson(x))) : [],
      unreadNotificationCount: json['unread_notification_count'] is int ? json['unread_notification_count'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slider': slider.map((e) => e.toSliderJson()).toList(),
      'unread_notification_count': unreadNotificationCount,
    };
  }
}

class CategoryListModel {
  String name;
  String sectionType;
  List<dynamic> data;
  bool showViewAll;
  bool isOtherSection;
  String slug;
  String type;
  bool isEachWordCapitalized;

  CategoryListModel({
    this.name = "",
    this.sectionType = "",
    this.data = const <dynamic>[],
    this.showViewAll = false,
    this.isOtherSection = false,
    this.slug = "",
    this.type = "",
    this.isEachWordCapitalized = true,
  });

  final categorykey = GlobalKey();
}

class LanguageResponse {
  String name;
  List<LanguageModel> languageList;

  LanguageResponse({this.name = '', this.languageList = const <LanguageModel>[]});

  factory LanguageResponse.fromJson(Map<String, dynamic> json) {
    return LanguageResponse(
      name: json['name'] is String ? json['name'] : "",
      languageList: json['data'] is List ? List<LanguageModel>.from(json['data'].map((x) => LanguageModel.fromJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'data': languageList.map((e) => e.toJson()).toList(),
    };
  }
}

class LanguageModel {
  int id;
  String name;
  String languageImage;

  LanguageModel({
    this.id = -1,
    this.name = "",
    this.languageImage = "",
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      languageImage: json['language_image'] is String ? json['language_image'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language_image': languageImage,
    };
  }
}

class OtherSectionModel {
  String slug;
  String name;
  String type;
  List<PosterDataModel> data;

  OtherSectionModel({
    this.slug = '',
    this.name = '',
    this.type = '',
    this.data = const <PosterDataModel>[],
  });

  factory OtherSectionModel.fromJson(Map<String, dynamic> json) {
    return OtherSectionModel(
      slug: json['slug'] is String ? json['slug'] : '',
      name: json['name'] is String ? json['name'] : '',
      type: json['type'] is String ? json['type'] : '',
      data: json['data'] is List ? List<PosterDataModel>.from(json['data'].map((x) => PosterDataModel.fromPosterJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'type': type,
      'data': data.map((e) => e.toPosterJson()).toList(),
    };
  }
}