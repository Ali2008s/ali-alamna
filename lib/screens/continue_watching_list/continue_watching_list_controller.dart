import 'dart:async';

import 'package:streamit_laravel/controllers/base_controller.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';

import '../../network/core_api.dart';

class ContinueWatchingListController extends BaseListController<PosterDataModel> {

  @override
  Future<void> getListData({bool showLoader = true}) async {
    setLoading(showLoader);
    await listContentFuture(
      CoreServiceApis.getContinueWatchingList(
        page: currentPage.value,
        continueWatchList: listContent,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((_) {
      /// Filter out fully watched items where watched_duration == total_duration
      listContent.removeWhere((element) {
        final String total = element.details.duration;
        final String watched = element.details.watchedDuration;
        if (total.isEmpty || watched.isEmpty) return false;
        return total == watched;
      });
    }).catchError((e) {
      setLoading(false);
      throw e;
    }).whenComplete(() => isLoading(false));
  }
}