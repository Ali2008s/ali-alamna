import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/common_base.dart';

import '../../../main.dart';
import '../../../network/core_api.dart';
import '../../../utils/app_common.dart';
import '../../../utils/empty_error_state_widget.dart';
import '../../continue_watching_list/components/continue_watching_item_component.dart';
import '../../continue_watching_list/components/remove_continue_watching_component.dart';
import '../../continue_watching_list/continue_watching_list_screen.dart';
import '../../profile/profile_controller.dart';
import '../home_controller.dart';
import 'continue_watch_component_controller.dart';

class ContinueWatchComponent extends StatelessWidget {
  final List<PosterDataModel> continueWatchList;
  final bool isFirstCategory;

  const ContinueWatchComponent({super.key, required this.continueWatchList, this.isFirstCategory = false});

  HomeController get homeController => Get.find<HomeController>();

  ContinueWatchComponentController get controller => Get.put(
        ContinueWatchComponentController(isFirstCategory: isFirstCategory),
      );

  @override
  Widget build(BuildContext context) {
    /// Filter out items where watched_duration == total_duration
    final List<PosterDataModel> visibleContinueWatchList = continueWatchList.where((element) {
      final String total = element.details.duration;
      final String watched = element.details.watchedDuration;
      if (total.isEmpty || watched.isEmpty) return true;
      return total != watched;
    }).toList();

    // Register the first focus node after first frame
    if (visibleContinueWatchList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstItemFocusNode = visibleContinueWatchList.first.itemFocusNode;
        controller.registerFirstFocusNode(firstItemFocusNode, locale.value.continueWatching);
      });
    } else {}

    return Column(
      key: homeController.continueWatchingKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        viewAllWidget(
          label: locale.value.continueWatching,
          showViewAll: false,
          onButtonPressed: () {
            Get.to(() => ContinueWatchingListScreen());
          },
        ),
        visibleContinueWatchList.isNotEmpty
            ? Focus(
                onFocusChange: controller.onFocusChange,
                child: HorizontalList(
                    controller: controller.listController,
                    spacing: 12,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(left: 16),
                    itemCount: visibleContinueWatchList.length,
                    itemBuilder: (context, index) {
                      return ContinueWatchingItemComponent(
                        index: index,
                        control: controller.listController,
                        continueWatchData: visibleContinueWatchList[index],
                        onRemoveTap: () {
                          handleRemoveFromContinueWatch(context, visibleContinueWatchList[index].id);
                        },
                      );
                    }),
              )
            : NoDataWidget(
                titleTextStyle: commonW600PrimaryTextStyle(),
                subTitleTextStyle: secondaryTextStyle(),
                title: locale.value.noItemsToContinueWatching,
                retryText: "",
                imageWidget: const EmptyStateWidget(),
              ).paddingSymmetric(horizontal: 16),
      ],
    );
  }

  Future<void> handleRemoveFromContinueWatch(BuildContext context, int id) async {
    Get.bottomSheet(
      RemoveContinueWatchingComponent(
        onRemoveTap: () {
          hideKeyboard(context);
          Get.back();
          final HomeController homeScreenCont = Get.find();

          homeScreenCont.isWatchListLoading(true);
          CoreServiceApis.removeContinueWatching(continueWatchingId: id).then((value) async {
            Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : Get.put(ProfileController());
            await homeScreenCont.getDashboardDetail(showLoader: true);
            ProfileController profileController = Get.put(ProfileController());
            await profileController.getProfileDetail();
            successSnackBar(locale.value.removedFromContinueWatch);
          }).catchError((e) {
            homeScreenCont.isWatchListLoading(false);
            errorSnackBar(error: e);
          }).whenComplete(() => homeScreenCont.isWatchListLoading(false));
        },
      ),
    );
  }
}
