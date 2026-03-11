import 'package:flutter/material.dart';

enum BottomItem {
  home,
  search,
  movies,
  tvShows,
  videos,
  unlockedVideo,
  comingsoon,
  livetv,
  matchSchedule,
  profile,
}

class BottomBarItem {
  final String Function() title;
  final IconData icon;
  final IconData activeIcon;
  final BottomItem type;
  final FocusNode focusNode;
  Widget screen;

  BottomBarItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.type,
    required this.focusNode,
    required this.screen,
  });
}
