import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../main.dart';
import '../../../utils/colors.dart';

class EmptyWatchListComponent extends StatelessWidget {
  const EmptyWatchListComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            locale.value.yourWatchlistIsEmpty,
            style: boldTextStyle(size: 20, color: white),
          ),
          6.height,
          Text(
            locale.value.contentAddedToYourWatchlist,
            style: primaryTextStyle(size: 14, color: darkGrayTextColor),
          ),
        ],
      ),
    );
  }
}
