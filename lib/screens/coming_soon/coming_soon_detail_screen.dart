import 'package:flutter/material.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/tv_show/trailer_clip_video_player.dart';


import 'coming_soon_controller.dart';
import 'model/coming_soon_response.dart';

class ComingSoonDetailScreen extends StatelessWidget {
  final ComingSoonModel comingSoonData;
  final ComingSoonController comingSoonCont;

  const ComingSoonDetailScreen({
    super.key,
    required this.comingSoonCont,
    required this.comingSoonData,
  });

  @override
  Widget build(BuildContext context) {
    return TrailerClipPlayerWidget(
      videoModel: VideoData(
        url: comingSoonData.trailerUrl,
        urlType: comingSoonData.trailerUrlType,
        posterImage: comingSoonData.thumbnailImage,
      ),
      aspectRatio: 16/9,
      onEnded: () {
        Navigator.pop(context);
      },
    );
  }
}
