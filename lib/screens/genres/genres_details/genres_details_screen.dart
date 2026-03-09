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

class GenresDetailsScreen extends StatelessWidget {
  final GenreModel generDetails;

  GenresDetailsScreen({super.key, required this.generDetails});

  final GenresDetailsController genresDetCont = Get.put(GenresDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            12.height,
            Text(
              "${locale.value.moviesOf}${generDetails.name}",
              style: boldTextStyle(),
            ).paddingOnly(left: 16),
            12.height,
            Obx(
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
                  return Obx(
                    () => genresDetCont.genresDetailsList.isEmpty && genresDetCont.isLoading.isFalse
                        ? NoDataWidget(
                            titleTextStyle: boldTextStyle(color: white),
                            subTitleTextStyle: primaryTextStyle(color: white),
                            title: locale.value.noDataFound,
                            imageWidget: const EmptyStateWidget(),
                          ).paddingSymmetric(horizontal: 16, vertical: 16)
                        : AnimatedWrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            alignment: WrapAlignment.start,
                            children: List.generate(
                              genresDetCont.genresDetailsList.length,
                              (index) {
                                PosterDataModel movieDet = genresDetCont.genresDetailsList[index];
                                return PosterCardComponent(
                                  key: movieDet.itemGlobalKey,
                                  heightFactor: 1.1,
                                  widthFactor: 1.1,
                                  onFocusChange: (p0) {
                                    if (p0) {
                                      movieDet.hasFocus.value = true;
                                      Scrollable.ensureVisible(
                                        movieDet.itemGlobalKey.currentContext!,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
                                      );
                                      return;
                                    }
                                    movieDet.hasFocus.value = false;
                                  },
                                  focusNode: movieDet.itemFocusNode,
                                  height: 150,
                                  width: Get.width * 0.212,
                                  contentDetail: movieDet,
                                  isHorizontalList: false,
                                  onArrowLeft: () {
                                    if(index == 0) return;
                                    genresDetCont.genresDetailsList[index - 1].itemFocusNode.requestFocus();
                                  },
                                  onArrowRight: () {
                                    if(index == genresDetCont.genresDetailsList.length - 1) return;
                                    genresDetCont.genresDetailsList[index + 1].itemFocusNode.requestFocus();
                                  },
                                  onArrowUp: () {
                                    if(index < 4) return;
                                    genresDetCont.genresDetailsList[index - 4].itemFocusNode.requestFocus();
                                  },
                                  onArrowDown: () {
                                    if(index + 4 >= genresDetCont.genresDetailsList.length) {
                                      genresDetCont.genresDetailsList.last.itemFocusNode.requestFocus();
                                      return;
                                    }
                                    genresDetCont.genresDetailsList[index + 4].itemFocusNode.requestFocus();
                                  },
                                );
                              },
                            ),
                          ).paddingSymmetric(horizontal: 16),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
