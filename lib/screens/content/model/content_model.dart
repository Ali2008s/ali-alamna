import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/utils/constants.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';

class ContentResponse {
  bool status;
  ContentModel data;
  String message;

  ContentResponse({
    this.status = false,
    required this.data,
    this.message = "",
  });

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    return ContentResponse(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] is Map
          ? ContentModel.fromContentJson(json['data'])
          : ContentModel(
              details: ContentData(),
              downloadData: DownloadDataModel(
                downloadQualities: DownloadQualities(),
              ),
            ),
      message: json['message'] is String ? json['message'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.toContentJson(),
      'message': message,
    };
  }
}

class ContentModel {
  int id;
  ContentData details;
  DownloadDataModel downloadData;
  List<VideoData> trailerData;
  List<VideoData> videoQualities;
  List<Cast> cast;
  List<Cast> directors;
  List<PosterDataModel> suggestedContent;

  List<SubtitleModel> subtitleList;
  RentalData? rentalData;
  AdsData? adsData;

  bool get isDownloadDetailsAvailable => downloadData.downloadEnable.getBoolInt();

  bool get isTrailerAvailable => trailerData.isNotEmpty;

  bool get isVideoQualitiesAvailable => videoQualities.isNotEmpty;

  bool get isCastDetailsAvailable => cast.isNotEmpty;

  bool get isDirectorDetailsAvailable => directors.isNotEmpty;

  bool get isSuggestedContentAvailable => suggestedContent.isNotEmpty;

  bool get isDefaultQualityAvailable => defaultQuality.url.isNotEmpty;

  bool get isAdsAvailable => adsData != null && (adsData!.isCustomAdsAvailable || adsData!.isVastAdsAvailable);

  bool get isRentalAvailable => rentalData != null;

  bool get isSubtitleAvailable => subtitleList.isNotEmpty;

  VideoData get defaultQuality => videoQualities.isNotEmpty
      ? videoQualities.firstWhere(
          (element) =>
              (element.quality.isEmpty ||
                  element.quality.toLowerCase() == QualityConstants.defaultQuality.toLowerCase()) &&
              element.url.isNotEmpty,
          orElse: () => VideoData(),
        )
      : VideoData();

  bool get isEpisode => details.type == VideoType.episode;

  int get entertainmentId => isEpisode
      ? details.tvShowData!.id
      : id > -1
          ? id
          : 0;

  ContentModel({
    this.id = -1,
    required this.details,
    required this.downloadData,
    this.trailerData = const <VideoData>[],
    this.videoQualities = const <VideoData>[],
    this.cast = const <Cast>[],
    this.directors = const <Cast>[],
    this.suggestedContent = const <PosterDataModel>[],
    this.subtitleList = const <SubtitleModel>[],
    this.adsData,
    this.rentalData,
  });

  factory ContentModel.fromContentJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] is int ? json['id'] : -1,
      details: json['details'] is Map ? ContentData.fromDetailsJson(json['details']) : ContentData(),
      downloadData: json['download_data'] is Map
          ? DownloadDataModel.fromJson(json['download_data'])
          : DownloadDataModel(downloadQualities: DownloadQualities()),
      trailerData: json['trailer_data'] is List
          ? List<VideoData>.from(json['trailer_data'].map((x) => VideoData.fromTrailerJson(x)))
          : [],
      videoQualities: json['video_qualities'] is List
          ? List<VideoData>.from(json['video_qualities'].map((x) => VideoData.fromQualityJson(x)))
          : [],
      cast: json['cast'] is List ? List<Cast>.from(json['cast'].map((x) => Cast.fromListJson(x))) : [],
      directors: json['directors'] is List ? List<Cast>.from(json['directors'].map((x) => Cast.fromListJson(x))) : [],
      suggestedContent: json['suggested_content'] is List
          ? List<PosterDataModel>.from(json['suggested_content'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
      adsData: json['ads_data'] is Map ? AdsData.fromJson(json['ads_data']) : null,
      rentalData: json['rental_data'] is Map ? RentalData.fromJson(json['rental_data']) : null,
      subtitleList: json['subtitle_info'] is List
          ? List<SubtitleModel>.from(json['subtitle_info'].map((x) => SubtitleModel.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toContentJson() {
    return {
      'id': id,
      'details': details.toDetailsJson(),
      'download_data': downloadData.toJson(),
      'trailer_data': trailerData.map((e) => e.toTrailerJson()).toList(),
      'video_qualities': videoQualities.map((e) => e.toQualityJson()).toList(),
      'cast': cast.map((e) => e.toListJson()).toList(),
      'directors': directors.map((e) => e.toListJson()).toList(),
      'suggested_content': suggestedContent.map((e) => e.toPosterJson()).toList(),
      'ads_data': adsData?.toJson(),
      'rental_data': rentalData?.toJson(),
      'subtitle_info': subtitleList.map((e) => e.toJson()).toList(),
    };
  }

  factory ContentModel.fromLiveContentJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] is int ? json['id'] : -1,
      details: json['details'] is Map ? ContentData.fromDetailsJson(json['details']) : ContentData(),
      videoQualities: json['video_qualities'] is List
          ? List<VideoData>.from(json['video_qualities'].map((x) => VideoData.fromQualityJson(x)))
          : [],
      suggestedContent: json['suggested_content'] is List
          ? List<PosterDataModel>.from(json['suggested_content'].map((x) => PosterDataModel.fromPosterJson(x)))
          : [],
      downloadData: DownloadDataModel(downloadQualities: DownloadQualities()),
    );
  }

  Map<String, dynamic> toLiveContentJson() {
    return {
      'id': id,
      'details': details.toDetailsJson(),
      'video_qualities': videoQualities.map((e) => e.toQualityJson()).toList(),
      'suggested_content': suggestedContent.map((e) => e.toPosterJson()).toList(),
    };
  }
}

class ContentData {
  int id;
  String name;
  String type;
  int isDeviceSupported;
  int isInWatchList;
  int isLiked;
  int isAgeRestrictedContent;
  int hasContentAccess;
  int requiredPlanLevel;
  List<String> genres;
  String language;
  String duration;
  String watchedDuration;
  String introEndsAt;
  String introStartsAt;
  String contentRating;
  String releaseDate;
  String imdbRating;
  String access;
  String description;
  String thumbnailImage;
  TvShowData? tvShowData;
  String? shortDescription;
  List<SeasonData> seasonList;
  String? trailerUrl;
  String? trailerUrlType;

  String get releaseYear => releaseDate.isNotEmpty ? releaseDate : "";

  bool get isTvShowDetailsAvailable => tvShowData != null;

  bool get isSeasonAvailable => seasonList.isNotEmpty;

  bool get hasStartedWatching => watchedDuration.isNotEmpty;

  String get streamingAccess => access.getContentAccess(requiredPlanLevel: requiredPlanLevel);

  String get buttonTitle => hasContentAccess.getBoolInt()
      ? watchedDuration.isNotEmpty
          ? "Resume"
          : locale.value.watchNow
      : access == MovieAccess.payPerView
          ? locale.value.rent
          : access == MovieAccess.paidAccess
              ? locale.value.subscribe
              : locale.value.watchNow;

  //region getters
  bool get isEpisode => type == VideoType.episode;

  int get entertainmentId => isEpisode
      ? tvShowData!.id
      : id > -1
          ? id
          : 0;

  String get entertainmentType => isEpisode ? VideoType.episode : type;

  ContentData({
    this.name = "",
    this.type = "",
    this.id = -1,
    this.isDeviceSupported = 0,
    this.isInWatchList = 0,
    this.isLiked = 0,
    this.isAgeRestrictedContent = 0,
    this.genres = const <String>[],
    this.language = "",
    this.duration = "",
    this.watchedDuration = "",
    this.introEndsAt = "",
    this.introStartsAt = "",
    this.contentRating = "",
    this.releaseDate = "",
    this.imdbRating = "",
    this.access = "",
    this.description = "",
    this.thumbnailImage = "",
    this.hasContentAccess = 0,
    this.requiredPlanLevel = -1,
    this.tvShowData,
    this.shortDescription,
    this.seasonList = const <SeasonData>[],
    this.trailerUrl,
    this.trailerUrlType,
  });

  factory ContentData.fromDetailsJson(Map<String, dynamic> json) {
    return ContentData(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      type: json['type'] is String ? json['type'] : "",
      isDeviceSupported: json['is_device_supported'] is int ? json['is_device_supported'] : 0,
      isInWatchList: json['is_in_watchlist'] is int ? json['is_in_watchlist'] : 0,
      isLiked: json['is_like'] is int ? json['is_like'] : 0,
      isAgeRestrictedContent: json['is_restricted'] is int ? json['is_restricted'] : 0,
      hasContentAccess: json['has_content_access'] is int ? json['has_content_access'] : 0,
      requiredPlanLevel: json['required_plan_level'] is int ? json['required_plan_level'] : -1,
      genres: json['genres'] is List ? List<String>.from(json['genres'].map((x) => x)) : [],
      language: json['language'] is String ? json['language'] : "",
      duration: json['total_duration'] is String ? json['total_duration'] : "",
      watchedDuration: json['watched_duration'] is String ? json['watched_duration'] : "",
      introEndsAt: json['intro_ends_at'] is String ? json['intro_ends_at'] : "",
      introStartsAt: json['intro_starts_at'] is String ? json['intro_starts_at'] : "",
      contentRating: json['content_rating'] is String ? json['content_rating'] : "",
      releaseDate: json['release_date'] is String ? json['release_date'] : "",
      imdbRating: json['imdb_rating'] is String ? json['imdb_rating'] : "",
      access: json['access'] is String ? json['access'] : json['movie_access'] is String ? json['movie_access'] : "",
      description: json['description'] is String ? json['description'] : "",
      thumbnailImage: json['thumbnail_image'] is String ? json['thumbnail_image'] : "",
      tvShowData: json['tv_show_data'] is Map ? TvShowData.fromJson(json['tv_show_data']) : TvShowData(),
      seasonList: json['season_data'] is List
          ? List<SeasonData>.from(json['season_data'].map((x) => SeasonData.fromJson(x))).where((season) => season.totalEpisode > 0).toList()
          : [],
      shortDescription: json['short_description'] is String ? json['short_description'] : "",
      trailerUrl: json['trailer_url'] is String ? json['trailer_url'] : null,
      trailerUrlType: json['trailer_url_type'] is String ? json['trailer_url_type'] : null,
    );
  }

  Map<String, dynamic> toDetailsJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_device_supported': isDeviceSupported,
      'is_restricted': isAgeRestrictedContent,
      'is_in_watchlist': isInWatchList,
      'is_like': isLiked,
      'genres': genres.map((e) => e).toList(),
      'language': language,
      'total_duration': duration,
      'watched_duration': watchedDuration,
      'intro_ends_at': introEndsAt,
      'intro_starts_at': introStartsAt,
      'content_rating': contentRating,
      'release_date': releaseDate,
      'imdb_rating': imdbRating,
      'access': access,
      'description': description,
      'thumbnail_image': thumbnailImage,
      'has_content_access': hasContentAccess,
      'required_plan_level': requiredPlanLevel,
      'tv_show_data': tvShowData?.toJson(),
      'season_data': seasonList.map((e) => e.toJson()).toList(),
      'short_description': shortDescription,
      'trailer_url': trailerUrl,
      'trailer_url_type': trailerUrlType,
    };
  }

  factory ContentData.fromSliderDetailsJson(Map<String, dynamic> json) {
    return ContentData(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      type: json['type'] is String ? json['type'] : "",
      isInWatchList: json['is_in_watchlist'] is int ? json['is_in_watchlist'] : 0,
      isAgeRestrictedContent: json['is_restricted'] is int ? json['is_restricted'] : 0,
      hasContentAccess: json['has_content_access'] is int ? json['has_content_access'] : 0,
      requiredPlanLevel: json['required_plan_level'] is int ? json['required_plan_level'] : -1,
      genres: json['genres'] is List ? List<String>.from(json['genres'].map((x) => x)) : [],
      language: json['language'] is String ? json['language'] : "",
      duration: json['duration'] is String ? json['duration'] : "",
      releaseDate: json['release_date'] is String ? json['release_date'] : "",
      imdbRating: json['imdb_rating'] is String ? json['imdb_rating'] : "",
      isDeviceSupported: json['is_device_supported'] is int ? json['is_device_supported'] : 0,
      access: json['access'] is String ? json['access'] : json['movie_access'] is String ? json['movie_access'] : "",
      tvShowData: json['tv_show_data'] is Map ? TvShowData.fromJson(json['tv_show_data']) : TvShowData(),
      seasonList: json['season_data'] is List
          ? List<SeasonData>.from(json['season_data'].map((x) => SeasonData.fromJson(x))).where((season) => season.totalEpisode > 0).toList()
          : [],
      shortDescription: json['short_description'] is String ? json['short_description'] : "",
      trailerUrl: json['trailer_url'] is String ? json['trailer_url'] : null,
      trailerUrlType: json['trailer_url_type'] is String ? json['trailer_url_type'] : null,
    );
  }

  Map<String, dynamic> toSliderDetailsJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_device_supported': isDeviceSupported,
      'is_restricted': isAgeRestrictedContent,
      'is_in_watchlist': isInWatchList,
      'genres': genres.map((e) => e).toList(),
      'language': language,
      'total_duration': duration,
      'release_date': releaseDate,
      'imdb_rating': imdbRating,
      'access': access,
      'has_content_access': hasContentAccess,
      'required_plan_level': requiredPlanLevel,
      'tv_show_data': tvShowData?.toJson(),
      'season_data': seasonList.map((e) => e.toJson()).toList(),
      'trailer_url': trailerUrl,
      'trailer_url_type': trailerUrlType,
    };
  }

  factory ContentData.fromListJson(Map<String, dynamic> json) {
    return ContentData(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      type: json['type'] is String ? json['type'] : "",
      isDeviceSupported: json['is_device_supported'] is int ? json['is_device_supported'] : -1,
      releaseDate: json['release_date'] is String ? json['release_date'] : "",
      access: json['access'] is String ? json['access'] : json['movie_access'] is String ? json['movie_access'] : "",
      hasContentAccess: json['has_content_access'] is int ? json['has_content_access'] : -1,
      requiredPlanLevel: json['required_plan_level'] is int ? json['required_plan_level'] : -1,
      duration: json['duration'] is String
          ? json['duration']
          : (json['total_duration'] is String ? json['total_duration'] : ""),
      watchedDuration: json['watched_duration'] is String ? json['watched_duration'] : "",
      shortDescription: json['short_description'] is String ? json['short_description'] : "",
      trailerUrl: json['trailer_url'] is String ? json['trailer_url'] : null,
      trailerUrlType: json['trailer_url_type'] is String ? json['trailer_url_type'] : null,
    );
  }

  Map<String, dynamic> toListJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_device_supported': isDeviceSupported,
      'content_rating': contentRating,
      'release_date': releaseDate,
      'access': access,
      'thumbnail_image': thumbnailImage,
      'has_content_access': hasContentAccess,
      'required_plan_level': requiredPlanLevel,
      'trailer_url': trailerUrl,
      'trailer_url_type': trailerUrlType,
    };
  }
}

class TvShowData {
  int id;
  String name;
  int seasonId;
  int totalEpisode;

  TvShowData({
    this.id = -1,
    this.name = "",
    this.seasonId = -1,
    this.totalEpisode = -1,
  });

  factory TvShowData.fromJson(Map<String, dynamic> json) {
    return TvShowData(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      seasonId: json['season_id'] is int ? json['season_id'] : -1,
      totalEpisode: json['total_episode'] is int ? json['total_episode'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'season_id': seasonId,
      'total_episode': totalEpisode,
    };
  }
}

class SeasonData {
  int id;
  String name;
  int seasonId;
  int totalEpisode;

  SeasonData({
    this.id = -1,
    this.name = "",
    this.seasonId = -1,
    this.totalEpisode = -1,
  });

  factory SeasonData.fromJson(Map<String, dynamic> json) {
    return SeasonData(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      seasonId: json['season_id'] is int ? json['season_id'] : -1,
      totalEpisode: json['total_episode'] is int ? json['total_episode'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'season_id': seasonId,
      'total_episode': totalEpisode,
    };
  }
}

class DownloadDataModel {
  int downloadEnable;
  int downloadId;
  DownloadQualities downloadQualities;

  DownloadDataModel({
    this.downloadEnable = -1,
    this.downloadId = 0,
    required this.downloadQualities,
  });

  factory DownloadDataModel.fromJson(Map<String, dynamic> json) {
    return DownloadDataModel(
      downloadEnable: json['download_enable'] is int ? json['download_enable'] : -1,
      downloadId: json['download_id'] is int ? json['download_id'] : 0,
      downloadQualities: json['download_qualities'] is Map
          ? DownloadQualities.fromJson(json['download_qualities'])
          : DownloadQualities(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'download_enable': downloadEnable,
      'download_qualities': downloadQualities.toJson(),
    };
  }
}

class DownloadQualities {
  int id;
  String urlType;
  String url;
  String quality;
  int isDownloaded;
  int downloadId;

  DownloadQualities({
    this.id = -1,
    this.urlType = "",
    this.url = "",
    this.quality = "",
    this.isDownloaded = -1,
    this.downloadId = -1,
  });

  factory DownloadQualities.fromJson(Map<String, dynamic> json) {
    return DownloadQualities(
      id: json['id'] is int ? json['id'] : -1,
      urlType: json['url_type'] is String ? json['url_type'] : "",
      url: json['url'] is String ? json['url'] : "",
      quality: json['quality'] is String ? json['quality'] : "",
      isDownloaded: json['is_downloaded'] is int ? json['is_downloaded'] : -1,
      downloadId: json['download_id'] is int ? json['download_id'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url_type': urlType,
      'url': url,
      'quality': quality,
      'is_downloaded': isDownloaded,
      'download_id': downloadId,
    };
  }
}

class VideoData {
  int id;
  String urlType;
  String url;
  String quality;
  String posterImage;
  String title;

  VideoData({
    this.id = -1,
    this.urlType = "",
    this.url = "",
    this.quality = QualityConstants.defaultQuality,
    this.posterImage = '',
    this.title = '',
  });

  factory VideoData.fromTrailerJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'] is int ? json['id'] : -1,
      urlType: json['url_type'] is String ? json['url_type'] : "",
      url: json['url'] is String ? json['url'] : "",
      posterImage: json['poster_tv_image'] is String ? json['poster_tv_image'] : json['poster_image'] is String ? json['poster_image'] : "",
      quality: json['quality'] is String && (json['quality'] as String).isNotEmpty
          ? json['quality']
          : QualityConstants.defaultQuality,
      title: json['title'] is String ? json['title'] : "",
    );
  }

  Map<String, dynamic> toTrailerJson() {
    return {
      'id': id,
      'url_type': urlType,
      'url': url,
      'poster_image': posterImage,
      'quality': quality,
      'title': title,
    };
  }

  factory VideoData.fromQualityJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'] is int ? json['id'] : -1,
      urlType: json['url_type'] is String ? json['url_type'] : "",
      url: json['url'] is String ? json['url'] : "",
      quality: json['quality'] is String ? json['quality'] : "",
      posterImage: json['poster_tv_image'] is String ? json['poster_tv_image'] : json["poster_image"] is String ? json['poster_image'] : "",
      title: json['title'] is String ? json['title'] : "",
    );
  }

  Map<String, dynamic> toQualityJson() {
    return {
      'id': id,
      'url_type': urlType,
      'url': url,
      'quality': quality,
      'poster_image': posterImage,
      'title': title,
    };
  }
}

class Cast {
  int id;
  String name;
  String profileImage;
  String designation;

  String bio;

  String placeOfBirth;
  String dob;

  Cast({
    this.id = -1,
    this.name = "",
    this.profileImage = "",
    this.designation = "",
    this.bio = "",
    this.placeOfBirth = "",
    this.dob = "",
  });

  factory Cast.fromListJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      profileImage: json['profile_image'] is String ? json['profile_image'] : "",
    );
  }

  Map<String, dynamic> toListJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
    };
  }

  factory Cast.fromDetailsJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] is int ? json['id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      profileImage: json['profile_image'] is String ? json['profile_image'] : "",
      designation: json['designation'] is String ? json['designation'] : "",
      bio: json['bio'] is String ? json['bio'] : "",
      placeOfBirth: json['place_of_birth'] is String ? json['place_of_birth'] : "",
      dob: json['dob'] is String ? json['dob'] : "",
    );
  }

  Map<String, dynamic> toDetailsJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
      'designation': designation,
      'bio': bio,
      'place_of_birth': placeOfBirth,
    };
  }
}

class PosterDataModel {
  int id;
  String posterImage;
  ContentData details;
  RxBool hasFocus = false.obs;

  bool get isEpisode => details.type == VideoType.episode;

  int get entertainmentId => isEpisode
      ? (details.id > -1 ? details.id : (id > -1 ? id : -1))
      : (id > -1 ? id : (details.id > -1 ? details.id : -1));
  final FocusNode itemFocusNode = FocusNode();
  final GlobalKey itemGlobalKey = GlobalKey();

  PosterDataModel({
    this.id = -1,
    this.posterImage = '',
    required this.details,
  });

  factory PosterDataModel.fromPosterJson(Map<String, dynamic> json) {
    final detailsJson = json['details'] is Map ? Map<String, dynamic>.from(json['details']) : <String, dynamic>{};
    if (json['trailer_data'] is Map) {
      final trailerData = json['trailer_data'] as Map<String, dynamic>;
      detailsJson['trailer_url'] = trailerData['trailer_url'];
      detailsJson['trailer_url_type'] = trailerData['trailer_url_type'];
    }
    return PosterDataModel(
      id: json['id'] is int ? json['id'] : -1,
      posterImage: json['poster_tv_image'] is String ? json['poster_tv_image'] : json["poster_image"] is String ? json['poster_image'] : "",
      details: ContentData.fromListJson(detailsJson),
    );
  }

  Map<String, dynamic> toPosterJson() {
    return {
      'id': id,
      'poster_image': posterImage,
      'details': details.toListJson(),
    };
  }

  factory PosterDataModel.fromSliderJson(Map<String, dynamic> json) {
    final detailsJson = json['details'] is Map ? Map<String, dynamic>.from(json['details']) : <String, dynamic>{};

    if (json['trailer_data'] is Map) {
      final trailerData = json['trailer_data'] as Map<String, dynamic>;
      detailsJson['trailer_url'] = trailerData['trailer_url'];
      detailsJson['trailer_url_type'] = trailerData['trailer_url_type'];
    }

    return PosterDataModel(
      id: json['id'] is int ? json['id'] : -1,
      posterImage: json['poster_tv_image'] is String ? json['poster_tv_image'] : json["poster_image"] is String ? json['poster_image'] : "",
      details: ContentData.fromSliderDetailsJson(detailsJson),
    );
  }

  Map<String, dynamic> toSliderJson() {
    return {
      'id': id,
      'poster_image': posterImage,
      'details': details.toSliderDetailsJson(),
    };
  }

  factory PosterDataModel.fromThumbnailJson(Map<String, dynamic> json) {
    return PosterDataModel(
      id: json['id'] is int ? json['id'] : -1,
      posterImage: json['thumbnail_image'] is String ? json['thumbnail_image'] : "",
      details: json['details'] is Map ? ContentData.fromListJson(json['details']) : ContentData(),
    );
  }

  Map<String, dynamic> toThumbnailJson() {
    return {
      'id': id,
      'thumbnail_image': posterImage,
      'details': details.toListJson(),
    };
  }
}

class AdsData {
  List<CustomAds> customAds;
  VastAds vastAds;

  bool get isCustomAdsAvailable => customAds.isNotEmpty;

  bool get isVastAdsAvailable =>
      vastAds.overlayAdUrl.isNotEmpty ||
      vastAds.preRoleAdUrl.isNotEmpty ||
      vastAds.midRoleAdUrl.isNotEmpty ||
      vastAds.postRoleAdUrl.isNotEmpty;

  AdsData({
    this.customAds = const <CustomAds>[],
    required this.vastAds,
  });

  factory AdsData.fromJson(Map<String, dynamic> json) {
    return AdsData(
      customAds:
          json['custom_ads'] is List ? List<CustomAds>.from(json['custom_ads'].map((x) => CustomAds.fromJson(x))) : [],
      vastAds: json['vast_ads'] is Map ? VastAds.fromJson(json['vast_ads']) : VastAds(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'custom_ads': customAds.map((e) => e.toJson()).toList(),
      'vast_ads': vastAds.toJson(),
    };
  }
}

class CustomAds {
  String type;
  String url;
  String redirectUrl;

  CustomAds({
    this.type = "",
    this.url = "",
    this.redirectUrl = "",
  });

  factory CustomAds.fromJson(Map<String, dynamic> json) {
    return CustomAds(
      type: json['type'] is String ? json['type'] : "",
      url: json['url'] is String ? json['url'] : "",
      redirectUrl: json['redirect_url'] is String ? json['redirect_url'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'redirect_url': redirectUrl,
    };
  }
}

class VastAds {
  List<String> overlayAdUrl;
  List<String> preRoleAdUrl;
  List<String> midRoleAdUrl;
  List<String> postRoleAdUrl;

  VastAds({
    this.overlayAdUrl = const <String>[],
    this.preRoleAdUrl = const <String>[],
    this.midRoleAdUrl = const <String>[],
    this.postRoleAdUrl = const <String>[],
  });

  factory VastAds.fromJson(Map<String, dynamic> json) {
    return VastAds(
      overlayAdUrl: json['overlay_ad_url'] is List ? List<String>.from(json['overlay_ad_url'].map((x) => x)) : [],
      preRoleAdUrl: json['pre_role_ad_url'] is List ? List<String>.from(json['pre_role_ad_url'].map((x) => x)) : [],
      midRoleAdUrl: json['mid_role_ad_url'] is List ? List<String>.from(json['mid_role_ad_url'].map((x) => x)) : [],
      postRoleAdUrl: json['post_role_ad_url'] is List ? List<String>.from(json['post_role_ad_url'].map((x) => x)) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overlay_ad_url': overlayAdUrl.map((e) => e).toList(),
      'pre_role_ad_url': preRoleAdUrl.map((e) => e).toList(),
      'mid_role_ad_url': midRoleAdUrl.map((e) => e).toList(),
      'post_role_ad_url': postRoleAdUrl.map((e) => e).toList(),
    };
  }
}

class SubtitleModel {
  int id;
  String language;
  String languageCode;
  String subtitleFile;
  int isDefaultLanguage;

  SubtitleModel({
    this.id = -1,
    this.isDefaultLanguage = 0,
    this.language = "",
    this.subtitleFile = "",
    this.languageCode = '',
  });

  factory SubtitleModel.fromJson(Map<String, dynamic> json) {
    return SubtitleModel(
      id: json['id'] is int ? json['id'] : -1,
      isDefaultLanguage: json['is_default'] is int ? json['is_default'] : -1,
      subtitleFile: json['subtitle_file'] is String ? json['subtitle_file'] : '',
      language: json['language'] is String ? json['language'] : '',
      languageCode: json['language_code'] is String ? json['language_code'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_default': isDefaultLanguage,
      'subtitle_file': subtitleFile,
      'language': language,
      'language_code': languageCode,
    };
  }
}

class RentalData {
  num price;
  num discount;
  num discountedPrice;
  int accessDuration;
  int availabilityDays;

  RentalData({
    this.price = 0.0,
    this.discount = 0.0,
    this.discountedPrice = 0.0,
    this.accessDuration = -1,
    this.availabilityDays = -1,
  });

  factory RentalData.fromJson(Map<String, dynamic> json) {
    return RentalData(
      price: json['price'] is num ? json['price'] : 0.0,
      discount: json['discount'] is num ? json['discount'] : 0.0,
      discountedPrice: json['discounted_price'] is num ? json['discounted_price'] : 0.0,
      accessDuration: json['access_duration'] is int ? json['access_duration'] : -1,
      availabilityDays: json['availability_days'] is int ? json['availability_days'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'discount': discount,
      'discounted_price': discountedPrice,
      'access_duration': accessDuration,
      'availability_days': availabilityDays,
    };
  }
}

class OptionData {
  final RxBool isFocused;
  final String text;
  final FocusNode focusNode;
  final VoidCallback handleClick;

  OptionData({
    required this.isFocused,
    required this.text,
    required this.focusNode,
    required this.handleClick,
  });
}
