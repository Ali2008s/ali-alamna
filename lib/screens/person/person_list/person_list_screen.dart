import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/person/person_detail_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../../components/app_scaffold.dart';
import '../../../components/shimmer_widget.dart';
import '../../../main.dart';
import '../../../utils/empty_error_state_widget.dart';
import '../../home/components/person_component/person_card.dart';
import '../model/person_model.dart';
import '../person_controller.dart';
import 'person_list_controller.dart';

// ignore: must_be_immutable
class PersonListScreen extends StatelessWidget {
  String? title = locale.value.actors;

  PersonListScreen({super.key, this.title});

  final PersonListController personListCont = Get.put(PersonListController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      isLoading: personListCont.isLoading,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      topBarBgColor: transparentColor,
      appBartitleText: title.validate(),
      body: Obx(
        () => SnapHelperWidget(
          future: personListCont.getOriginalPersonFuture.value,
          initialData: cachedChannelList.isEmpty ? cachedChannelList : null,
          loadingWidget: AnimatedScrollView(
            refreshIndicatorColor: appColorPrimary,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(left: Get.width * 0.04, right: Get.width * 0.04, bottom: Get.height * 0.02),
            children: [
              AnimatedWrap(
                spacing: Get.width * 0.03,
                runSpacing: Get.height * 0.02,
                children: List.generate(
                  20,
                  (index) {
                    return ShimmerWidget(
                      height: 100,
                      width: Get.width * 0.286,
                      radius: 6,
                    );
                  },
                ),
              ),
            ],
          ),
          errorBuilder: (error) {
            return NoDataWidget(
              titleTextStyle: secondaryTextStyle(color: white),
              subTitleTextStyle: primaryTextStyle(color: white),
              title: error,
              retryText: locale.value.reload,
              imageWidget: const ErrorStateWidget(),
              onRetry: () {
                personListCont.refreshPersonList();
              },
            );
          },
          onSuccess: (res) {
            return Obx(
              () => personListCont.isLoading.isFalse && personListCont.originalPersonList.isEmpty
                  ? NoDataWidget(
                      titleTextStyle: boldTextStyle(color: white),
                      subTitleTextStyle: primaryTextStyle(color: white),
                      title: locale.value.noDataFound,
                      retryText: "",
                      imageWidget: const EmptyStateWidget(),
                    ).paddingSymmetric(horizontal: 16)
                  : AnimatedScrollView(
                      padding: const EdgeInsets.only(left: 16, bottom: 30),
                      physics: AlwaysScrollableScrollPhysics(),
                      refreshIndicatorColor: appColorPrimary,
                      children: [
                        AnimatedWrap(
                          children: List.generate(
                            personListCont.originalPersonList.length,
                            (index) {
                              CastResponse actorDet = personListCont.originalPersonList[index];
                              if (actorDet.data.isNotEmpty) {
                                Cast cast = actorDet.data.first;
                                return PersonCard(
                                  height: 130,
                                  width: Get.width * 0.27,
                                  personDet: actorDet,
                                  onTap: () {
                                    final PersonController personCont = Get.isRegistered<PersonController>()
                                        ? Get.find<PersonController>()
                                        : Get.put(PersonController());
                                    personCont.isUiLoaded = false;
                                    personCont.page(1);
                                    personCont.actorId(cast.id);
                                    personCont.getPersonMovieDetails();
                                    Get.to(() => PersonDetailScreen(personDet: actorDet, isHomeScreen: false));
                                  },
                                ).paddingOnly(right: 16, bottom: 16);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                      onNextPage: () async {
                        await personListCont.loadMorePersons();
                      },
                      onSwipeRefresh: () async {
                        await personListCont.refreshPersonList();
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
