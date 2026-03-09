import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/shimmer_widget.dart';

class TvShowShimmerScreen extends StatelessWidget {
  const TvShowShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        40.height,
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: boxDecorationDefault(color: context.cardColor),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///Season Card
              Row(
                children: [
                  ...List.generate(2, (index) {
                    return const ShimmerWidget(height: 23, width: 80, radius: 14).paddingRight(16);
                  }),
                ],
              ),
              16.height,
              Row(
                children: [
                  ...List.generate(3, (index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///Episode Card
                        const ShimmerWidget(height: 120, width: 200, radius: 14).paddingRight(16),
                        8.height,

                        ///Episode Number
                        Row(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...List.generate(2, (index) {
                                  return Row(
                                    children: [
                                      const ShimmerWidget(width: 20, height: 15, radius: 14),
                                      4.width,
                                    ],
                                  );
                                }),
                                const ShimmerWidget(width: 140, height: 15, radius: 14),
                              ],
                            ),
                          ],
                        ),
                        8.height,

                        ///Episode Detail
                        const ShimmerWidget(height: 30, width: 200, radius: 12),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    ).paddingSymmetric(horizontal: 8, vertical: 16);
  }
}
