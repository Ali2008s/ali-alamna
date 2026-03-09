import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:streamit_laravel/network/core_api.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/watch_list/model/watch_list_resp.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../main.dart';
import '../../utils/constants.dart';
import '../home/model/dashboard_res_model.dart';
import 'model/search_list_model.dart';
import 'model/search_response.dart';

class SearchScreenController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isSearchLoading = false.obs;
  RxBool isRefresh = false.obs;

  RxBool isLastPage = false.obs;
  TextEditingController searchTextCont = TextEditingController();
  FocusNode searchFocus = FocusNode();
  FocusNode searchResultsFocus = FocusNode();
  FocusNode voiceIconFocus = FocusNode();
  RxBool voiceIconHasFocus = false.obs;
  RxBool searchResultsHasFocus = false.obs;
  Rx<Future<SearchListResponse>> getSearchListApiFuture = Future(() => SearchListResponse()).obs;
  Rx<Future<SearchResponse>> getSearchMovieFuture = Future(() => SearchResponse()).obs;
  RxList<PosterDataModel> searchMovieDetails = RxList();
  stt.SpeechToText speechToText = stt.SpeechToText();
  RxBool isListening = false.obs;
  RxList<PosterDataModel> searchListData = <PosterDataModel>[].obs;

  CategoryListModel defaultPopularList = CategoryListModel();
  RxBool isTyping = false.obs;
  RxInt page = 1.obs;
  RxString lastSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getSearchList();
  }

  // Method to clear search text field
  void clearSearchField() {
    log(searchMovieDetails);
    searchTextCont.clear();
    searchMovieDetails.clear();
    isTyping.value = false;
  }

  //Get Search Movie Details
  Future<void> getSearchMovieDetail({bool showLoader = true}) async {
    searchMovieDetails.value = [];
    if (showLoader) {
      isSearchLoading(true);
    }
    await getSearchMovieFuture(CoreServiceApis.searchContent(
      search: searchTextCont.text.trim(),
    )).then((value) {
      searchMovieDetails.clear();
      searchMovieDetails.addAll(value.movieList);
      searchMovieDetails.addAll(value.tvShowList);
      searchMovieDetails.addAll(value.videoList);
      searchMovieDetails.addAll(value.seasonList);
    }).whenComplete(() => isSearchLoading(false));
  }

  /// Speech to text function
  Future<void> startListening() async {
    try {
      if (isListening.value) {
        await stopListening();
      }
      final bool available = await speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            isListening(false);

            final currentText = searchTextCont.text.trim();
            if (currentText.isNotEmpty && currentText.length > 2) {
              Future.delayed(const Duration(milliseconds: 200), () {
                getSearchMovieDetail();
              });
            } else if (currentText.isNotEmpty) {
              log('Speech done but text length is too short: ${currentText.length}');
            } else {
              log('Speech done but no text was recognized');
            }
          } else if (status == 'listening') {
            log('Speech recognition started, setting isListening to true');
            isListening(true);
          }
        },
        onError: (error) {
          log('=== Speech Recognition Error: $error ===');
          log('Error code: ${error.errorMsg}');
          log('Error details: ${error.toString()}');
          isListening(false);
        },
      );

      log('Speech_to_text available: $available');

      if (!available) {
        log('ERROR: Speech recognition is not available on this device');
        isListening(false);
        return;
      }
      isListening(true);
      await speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            searchTextCont.text = result.recognizedWords.toUpperCase();
            log('Updated searchTextCont.text to: ${searchTextCont.text}');
            if (result.finalResult && result.recognizedWords.trim().length > 2) {
              log('Final result received with length > 2, calling getSearchMovieDetail()');
              Future.delayed(const Duration(milliseconds: 100), () {
                getSearchMovieDetail();
              });
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e, stackTrace) {
      log('=== EXCEPTION in startListening(): $e ===');
      log('Stack trace: $stackTrace');
      isListening(false);
    }
  }

  Future<void> stopListening() async {
    try {
      final currentText = searchTextCont.text.trim();

      await speechToText.stop();
      isListening(false);

      if (currentText.isNotEmpty && currentText.length > 2) {
        Future.delayed(const Duration(milliseconds: 300), () {
          getSearchMovieDetail();
        });
      }
    } catch (e, stackTrace) {
      log('=== EXCEPTION in stopListening(): $e ===');
      log('Stack trace: $stackTrace');
      isListening(false);
    }
  }

  //Get Search List
  Future<void> getSearchListHistory({bool showLoader = true}) async {
    isLoading(showLoader);
    await getSearchListApiFuture(CoreServiceApis.getSearchList()).then((value) {
      searchMovieDetails.clear();
      final data = value.data?.where((element) => element.details.name.trim().isNotEmpty).toList();
      searchListData(data);
    }).whenComplete(() => isLoading(false));
  }

  Future<void> onSearch({required String searchVal}) async {
    if (searchVal.length > 2) {
      lastSearchQuery.value = searchVal;
      searchTextCont.text = searchVal;
      isTyping.value = true;
      await getSearchMovieDetail();
    } else {
      isTyping.value = false;
    }
  }

  void restoreSearchQuery() {
    if (lastSearchQuery.isNotEmpty) {
      searchTextCont.text = lastSearchQuery.value;
    }
  }

  Future<void> saveSearch({required String searchQuery, required String type, required String searchID}) async {
    isLoading(true);
    CoreServiceApis.saveSearch(
      request: {
        "search_query": searchQuery,
        "profile_id": profileId.value,
        "search_id": searchID,
        "type": type,
      },
    ).then((value) async {
      getSearchList();
      searchTextCont.clear();
    }).catchError((e) {
      isLoading(false);
    }).whenComplete(() {
      isLoading(false);
    });
  }

  ///Get search List
  Future<void> getSearchList() async {
    if (getStringAsync(SharedPreferenceConst.POPULAR_MOVIE, defaultValue: '').isNotEmpty) {
      String defaultData = getStringAsync(SharedPreferenceConst.POPULAR_MOVIE);
      final Map<String, dynamic> parsed = jsonDecode(defaultData) as Map<String, dynamic>;
      final ListResponse stored = ListResponse.fromJson(parsed);
      defaultPopularList = CategoryListModel(
        showViewAll: false,
        sectionType: stored.name.isNotEmpty ? stored.name : locale.value.popularMovies,
        data: stored.data,
      );
    }

    if (isLoggedIn.isTrue) {
      await getSearchListHistory();
    }
  }

  /// Particular search Delete
  Future<void> particularSearchDelete({required int id}) async {
    try {
      isLoading(true);
      // Try the API call
      final result = await CoreServiceApis.particularSearchDelete(id, profileId.value);
      log(result.message);
    } catch (e) {
      log("Error: $e");
    } finally {
      isLoading(false);
    }
  }

  /// Clear All
  Future<void> clearAll() async {
    try {
      isLoading(true);
      // Try the API call
      final result = await CoreServiceApis.clearAll(profileId.value).then((value) async {
        await getSearchList();
      });
      log(result.message);
    } catch (e) {
      log("Error: $e");
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    searchTextCont.clear();
    getSearchList();
    super.onClose();
  }
}
