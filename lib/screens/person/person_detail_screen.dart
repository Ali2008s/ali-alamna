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

  Widget _buildGrid(List<PosterDataModel> list) {
    if (list.isEmpty) {
      return NoDataWidget(
        titleTextStyle: boldTextStyle(color: white),
        subTitleTextStyle: primaryTextStyle(color: white),
        title: locale.value.noDataFound,
        retryText: "",
        imageWidget: const EmptyStateWidget(),
      ).paddingSymmetric(horizontal: 16);
    }
    return AnimatedWrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      alignment: WrapAlignment.start,
      children: List.generate(
        list.length,
        (index) {
          PosterDataModel movieDet = list[index];
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
              if (index == 0) return;
              list[index - 1].itemFocusNode.requestFocus();
            },
            onArrowRight: () {
              if (index == list.length - 1) return;
              list[index + 1].itemFocusNode.requestFocus();
            },
            onArrowUp: () {
              if (index < 4) return;
              list[index - 4].itemFocusNode.requestFocus();
            },
            onArrowDown: () {
              if (index + 4 >= list.length) {
                list.last.itemFocusNode.requestFocus();
                return;
              }
              list[index + 4].itemFocusNode.requestFocus();
            },
          );
        },
      ),
    ).paddingSymmetric(horizontal: 16);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      topBarBgColor: transparentColor,
      hideAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            12.height,
            // --- Movies Section ---
            Obx(() {
              if (!appConfigs.value.enableMovie) return const Offstage();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${locale.value.moviesOf}${personDet.data.isNotEmpty ? ' ${personDet.data.first.name}' : personDet.name}",
                    style: boldTextStyle(),
                  ).paddingOnly(left: 16),
                  12.height,
                  Obx(
                    () => SnapHelperWidget(
                      future: personCont.getOriginalMovieListFuture.value,
                      loadingWidget: const LoaderWidget().paddingTop(40),
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
                        return Obx(() => _buildGrid(personCont.originalMovieList));
                      },
                    ),
                  ),
                ],
              );
            }),

            24.height,

            // --- TV Shows Section ---
            Obx(() {
              if (!appConfigs.value.enableTvShow) return const Offstage();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "مسلسلات ${personDet.data.isNotEmpty ? personDet.data.first.name : personDet.name}",
                    style: boldTextStyle(),
                  ).paddingOnly(left: 16),
                  12.height,
                  Obx(
                    () => SnapHelperWidget(
                      future: personCont.getOriginalTvShowListFuture.value,
                      loadingWidget: const LoaderWidget().paddingTop(40),
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
                        return Obx(() => _buildGrid(personCont.originalTvShowList));
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
