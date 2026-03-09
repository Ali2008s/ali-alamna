import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/genres/genres_details/genres_details_controller.dart';
import 'package:streamit_laravel/screens/genres/model/genres_model.dart';

import '../../../../components/category_list/movie_horizontal/poster_card_component.dart';
import '../../../../components/loader_widget.dart';
import '../../../../main.dart';
import '../../../../utils/empty_error_state_widget.dart';

class GenresMoviesComponent extends StatelessWidget {
  final GenreModel genreDetail;

  GenresMoviesComponent({super.key, required this.genreDetail});

  final GenresDetailsController genresDetCont = Get.put(GenresDetailsController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SnapHelperWidget(
        future: genresDetCont.getGenresDetailsFuture.value,
        loadingWidget: const LoaderWidget().paddingSymmetric(vertical: 50).paddingTop(Get.height * 0.35),
        errorBuilder: (error) {
          return NoDataWidget(
            titleTextStyle: secondaryTextStyle(color: white),
            subTitleTextStyle: primaryTextStyle(color: white),
            title: error,
            retryText: locale.value.reload,
            imageWidget: const ErrorStateWidget(),
            onRetry: () {
              genresDetCont.page(1);
              genresDetCont.getGenresDetails();
            },
          );
        },
        onSuccess: (res) {
          return Center(
            child: Obx(
              () => genresDetCont.genresDetailsList.isEmpty && genresDetCont.isLoading.isFalse
                  ? NoDataWidget(
                      titleTextStyle: boldTextStyle(color: white),
                      subTitleTextStyle: primaryTextStyle(color: white),
                      title: locale.value.noDataFound,
                      imageWidget: const EmptyStateWidget(),
                    ).paddingSymmetric(horizontal: 16, vertical: 16)
                  : AnimatedWrap(
                      spacing: 16,
                      runSpacing: Get.height * 0.02,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.start,
                      children: List.generate(
                        genresDetCont.genresDetailsList.length,
                        (index) {
                           PosterDataModel movieDet = genresDetCont.genresDetailsList[index];
                          return PosterCardComponent(
                            key: movieDet.itemGlobalKey,
                            onFocusChange: (p0) {
                              if (movieDet.itemGlobalKey.currentContext != null) {
                                Scrollable.ensureVisible(
                                  movieDet.itemGlobalKey.currentContext!,
                                  duration: Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            height: 150,
                            width: Get.width * 0.282,
                            contentDetail: movieDet,
                            isHorizontalList: false,
                          );
                        },
                      ),
                    ).paddingSymmetric(horizontal: 16, vertical: 16),
            ),
          );
        },
      ),
    );
  }
}
