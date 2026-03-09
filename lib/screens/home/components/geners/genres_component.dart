import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';

import '../../../../components/shimmer_widget.dart';
import '../../../../utils/app_common.dart';
import '../../../genres/genres_controller.dart';
import '../../../genres/genres_list_screen.dart';
import '../../../genres/model/genres_model.dart';
import 'genres_card.dart';

class GenreComponent extends StatelessWidget {
  final CategoryListModel genresDetails;
  final bool isLoading;
  final bool isFirstCategory;

  const GenreComponent({super.key, required this.genresDetails, this.isLoading = false, this.isFirstCategory = false});

  GenresController get controller => Get.put(
        GenresController.forComponent(genresDetails: genresDetails, isFirstCategory: isFirstCategory),
        tag: '${genresDetails.name}_${genresDetails.hashCode}',
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      key: genresDetails.categorykey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        viewAllWidget(
          label: genresDetails.name,
          showViewAll: false,
          onButtonPressed: () {
            Get.to(() => GenresListScreen(title: genresDetails.name));
          },
        ),
        if (genresDetails.data.length < 6) 16.height,
        HorizontalList(
          physics: const AlwaysScrollableScrollPhysics(),
          runSpacing: 10,
          controller: controller.listController!,
          spacing: 10,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: genresDetails.data.length,
          itemBuilder: (context, index) {
            GenreModel movie = genresDetails.data[index];
            final isFirstItem = index == 0;
            final focusNode = isFirstItem ? controller.firstItemFocusNode! : null;

            if (isLoading) {
              return ShimmerWidget(height: 120, width: 100).cornerRadiusWithClipRRect(6);
            }
            return GenresCard(
              focusNode: focusNode,
              categoryName: genresDetails.name,
              controller: controller,
              categoryKey: genresDetails.categorykey,
              onFocusChange: (value) {
                controller.onGenreCardFocusChange(value, context, genresDetails.name, index, genresDetails.categorykey);
              },
              cardDet: movie,
              index: index,
            );
          },
        ),
      ],
    ).paddingSymmetric(vertical: 8);
  }
}
