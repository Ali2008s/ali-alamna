import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/person/person_controller.dart';
import '../../components/category_list/movie_horizontal/poster_card_component.dart';
import '../../components/loader_widget.dart';
import '../../utils/app_common.dart';
import '../../utils/empty_error_state_widget.dart';
import 'model/person_model.dart';

class PersonDetailScreen extends StatelessWidget {
  final CastResponse personDet;
  final bool isHomeScreen;

  PersonDetailScreen({super.key, required this.personDet, required this.isHomeScreen});

  final PersonController personCont = Get.put(PersonController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      topBarBgColor: transparentColor,
      hideAppBar: true,
      body: Obx(
        () => appConfigs.value.enableMovie
            ? SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    12.height,
                    Text(
                      "${locale.value.moviesOf}${personDet.data.isNotEmpty ? ' ${personDet.data.first.name}' : personDet.name}",
                      style: boldTextStyle(),
                    ).paddingOnly(left: 16),
                    12.height,
                    Obx(
                      () => SnapHelperWidget(
                        future: personCont.getOriginalMovieListFuture.value,
                        loadingWidget: const LoaderWidget().paddingTop(Get.height * 0.36),
                        errorBuilder: (error) {
                          return NoDataWidget(
                            titleTextStyle: secondaryTextStyle(color: white),
                            subTitleTextStyle: primaryTextStyle(color: white),
                            title: error,
                            retryText: locale.value.reload,
                            imageWidget: const ErrorStateWidget(),
                            onRetry: () {
                              personCont.page(1);
                              personCont.getPersonMovieDetails();
                            },
                          );
                        },
                        onSuccess: (res) {
                          if (personCont.originalMovieList.isEmpty) {
                            NoDataWidget(
                              titleTextStyle: boldTextStyle(color: white),
                              subTitleTextStyle: primaryTextStyle(color: white),
                              title: locale.value.noDataFound,
                              retryText: "",
                              imageWidget: const EmptyStateWidget(),
                            );
                          }
                          return Obx(
                            () => AnimatedWrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              alignment: WrapAlignment.start,
                              children: List.generate(
                                personCont.originalMovieList.length,
                                (index) {
                                  PosterDataModel movieDet = personCont.originalMovieList[index];
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
                                    height: 150,
                                    width: Get.width * 0.212,
                                    contentDetail: movieDet,
                                    focusNode: movieDet.itemFocusNode,
                                    isHorizontalList: false,
                                    onArrowLeft: () {
                                      if(index == 0) return;
                                      personCont.originalMovieList[index - 1].itemFocusNode.requestFocus();
                                    },
                                    onArrowRight: () {
                                      if(index == personCont.originalMovieList.length - 1) return;
                                      personCont.originalMovieList[index + 1].itemFocusNode.requestFocus();
                                    },
                                    onArrowUp: () {
                                      if(index < 4) return;
                                      personCont.originalMovieList[index - 4].itemFocusNode.requestFocus();
                                    },
                                    onArrowDown: () {
                                      if(index + 4 >= personCont.originalMovieList.length) {
                                        personCont.originalMovieList.last.itemFocusNode.requestFocus();
                                        return;
                                      }
                                      personCont.originalMovieList[index + 4].itemFocusNode.requestFocus();
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
              )
            : Offstage(),
      ),
    );
  }
}
