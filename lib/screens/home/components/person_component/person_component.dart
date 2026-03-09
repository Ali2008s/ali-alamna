import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../../../components/shimmer_widget.dart';
import '../../../../utils/common_base.dart';
import '../../../person/model/person_model.dart';
import '../../../person/person_list/person_list_screen.dart';
import '../../home_controller.dart';
import 'person_card.dart';
import 'person_component_controller.dart';

class PersonComponent extends StatelessWidget {
  final CategoryListModel personDetails;
  final double? height;
  final double? width;
  final bool isLoading;
  final bool isFirstCategory;

  const PersonComponent({super.key, required this.personDetails, this.height, this.width, this.isLoading = false, this.isFirstCategory = false});

  PersonComponentController get controller => Get.put(
        PersonComponentController(personDetails: personDetails, isFirstCategory: isFirstCategory),
        tag: '${personDetails.name}_${personDetails.hashCode}',
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      key: personDetails.categorykey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        viewAllWidget(
          showViewAll: false,
          label: personDetails.name,
          onButtonPressed: () {
            Get.to(() => PersonListScreen(title: personDetails.name.validate()));
          },
        ),
        SizedBox(
          height: 158,
          child: Focus(
            onFocusChange: controller.onCategoryFocusChange,
            child: HorizontalList(
              controller: controller.listController,
              physics: isLoading ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              spacing: 10,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: personDetails.data.length,
              itemBuilder: (context, index) {
                Cast castData = personDetails.data[index];
                final focusNode = controller.getItemFocusNode(index);
                final itemKey = controller.getItemKey(index);
                final totalItems = personDetails.data.length;
                if (isLoading) {
                  return ShimmerWidget(height: height ?? 140, width: width ?? 100, radius: 6);
                } else {
                  return PersonCard(
                    key: itemKey,
                    controller: controller,
                    focusNode: focusNode,
                    categoryName: personDetails.name,
                    totalItems: totalItems,
                    onFocusChange: (value) {
                      if (value && index == 0 && personDetails.categorykey.currentContext != null) {
                        HomeController hCont = getOrPutController(() => HomeController());
                        try {
                          if (hCont.homeScrollController.position.maxScrollExtent >= (hCont.homeScrollController.offset + 7)) {
                            Scrollable.ensureVisible(
                              personDetails.categorykey.currentContext!,
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        } catch (e) {
                          log('homeScrollController.hasClients ${hCont.homeScrollController.hasClients}');
                        }
                      }
                    },
                    personDet: CastResponse(data: [castData]),
                    index: index,
                  );
                }
              },
            ),
          ),
        ),
      ],
    ).paddingSymmetric(vertical: 8);
  }
}
