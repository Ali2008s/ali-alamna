import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../components/shimmer_widget.dart';
import '../../../../utils/app_common.dart';
import '../../../../services/focus_sound_service.dart';
import 'language_component_controller.dart';

class LanguageItemWidget extends StatelessWidget {
  final LanguageModel language;
  final double? height;
  final double? width;
  final Function(bool)? onFocusChange;
  final int? index;
  final FocusNode? focusNode;
  final String? categoryName;
  final GlobalKey? categoryKey;
  final LanguageComponentController? controller;

  LanguageItemWidget({super.key, required this.language, this.height, this.width, this.onFocusChange, this.index, this.focusNode, this.categoryName, this.categoryKey, this.controller});

  final RxBool isFocused = false.obs;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      focusNode: focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        return controller?.handleLanguageCardKeyEvent(event, index ?? -1, categoryName ?? '', language) ?? KeyEventResult.ignored;
      },
      onFocusChange: (value) {
        onFocusChange?.call(value);
        isFocused(value);
        if (value) {
          FocusSoundService.play();
        }
      },
      child: Obx(
        () => Container(
          decoration: boxDecorationDefault(
            borderRadius: radius(4),
            color: cardColor,
            border: isFocused.value ? Border.all(color: white, width: 3) : null,
          ),
          child: Stack(
            children: [
              CachedImageWidget(url: language.languageImage, height: height ?? 190, width: width ?? 256, fit: BoxFit.cover, alignment: Alignment.topCenter),
              IgnorePointer(
                ignoring: true,
                child: Container(
                  height: height ?? 190,
                  width: width ?? 256,
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [black.withValues(alpha: 0.0), black.withValues(alpha: 0.0), black.withValues(alpha: 0.5), black.withValues(alpha: 0.9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageComponent extends StatelessWidget {
  final CategoryListModel languageDetails;
  final bool isLoading;
  final bool isFirstCategory;

  const LanguageComponent({super.key, required this.languageDetails, this.isLoading = false, this.isFirstCategory = false});

  LanguageComponentController get controller => Get.put(
        LanguageComponentController(
          languageDetails: languageDetails,
          isFirstCategory: isFirstCategory,
        ),
        tag: '${languageDetails.name}_${languageDetails.hashCode}',
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      key: languageDetails.categorykey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        viewAllWidget(
          label: languageDetails.name.capitalizeEachWord(),
          showViewAll: false,
        ),
        if (languageDetails.data.length < 6) 16.height,
        HorizontalList(
          physics: const AlwaysScrollableScrollPhysics(),
          runSpacing: 10,
          controller: controller.listController,
          spacing: 10,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: languageDetails.data.length,
          itemBuilder: (context, index) {
            LanguageModel language = languageDetails.data[index];
            final isFirstItem = index == 0;
            final focusNode = isFirstItem ? controller.firstItemFocusNode : null;

            if (isLoading) {
              return ShimmerWidget(height: 120, width: 100).cornerRadiusWithClipRRect(6);
            }
            return LanguageItemWidget(
              focusNode: focusNode,
              categoryName: languageDetails.name,
              controller: controller,
              categoryKey: languageDetails.categorykey,
              onFocusChange: (value) {
                controller.onLanguageCardFocusChange(value, context, languageDetails.name, index, languageDetails.categorykey);
              },
              language: language,
              index: index,
            );
          },
        ),
      ],
    ).paddingSymmetric(vertical: 8);
  }
}
