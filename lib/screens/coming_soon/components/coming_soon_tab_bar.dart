import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/utils/colors.dart';
import '../../../main.dart';
import '../coming_soon_controller.dart';

class ComingSoonTabBar extends StatelessWidget {
  ComingSoonTabBar({super.key});
  final ComingSoonController _controller = Get.find<ComingSoonController>();

  /// Helper method to get translated tab name
  String _getTranslatedTabName(String tabName) {
    switch (tabName.toLowerCase()) {
      case 'all':
        return locale.value.all;
      case 'movies':
        return locale.value.movies;
      case 'tv shows':
        return locale.value.tVShows;
      case 'videos':
        return locale.value.videos;
      default:
        return tabName;
    }
  }

  /// Handle focus changes and trigger API calls
  void _onFocusChange(bool hasFocus, int index) {
    if (hasFocus) {
      // Only trigger API call if the tab actually changes
      if (_controller.currentSelected.value != index) {
        _controller.currentSelected.value = index;
        _controller.onTabChanged(index);
      } else {
        // Just update the focus without API call for the same tab
        _controller.currentSelected.value = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _controller.filterTabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isFocused = _controller.currentSelected.value == index;
              final isSelected = _controller.currentSelected.value == index;

              return _buildTabItem(
                tab: tab,
                index: index,
                isFocused: isFocused,
                isSelected: isSelected,
              );
            }).toList(),
          );
        }),
      ),
    );
  }

  /// Build individual tab item
  Widget _buildTabItem({
    required String tab,
    required int index,
    required bool isFocused,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Focus(
        focusNode: _controller.focusNodesForTabs[index],
        onFocusChange: (hasFocus) => _onFocusChange(hasFocus, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: _getTabBorder(isFocused, isSelected),
          ),
          child: Center(
            child: Text(
              _getTranslatedTabName(tab).toUpperCase(),
              style: _getTabTextStyle(isFocused, isSelected),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Get border based on focus and selection state
  Border? _getTabBorder(bool isFocused, bool isSelected) {
    if (isSelected) {
      return Border.all(
        color: appColorPrimary,
        width: 2,
      );
    } else if (isFocused) {
      return Border.all(
        color: appColorPrimary,
        width: 1,
      );
    }
    return null;
  }

  /// Get text style based on focus and selection state
  TextStyle _getTabTextStyle(bool isFocused, bool isSelected) {
    Color textColor;
    FontWeight fontWeight;

    if (isSelected) {
      textColor = appColorPrimary;
      fontWeight = FontWeight.bold;
    } else if (isFocused) {
      textColor = appColorPrimary;
      fontWeight = FontWeight.w600;
    } else {
      textColor = secondaryTextColor;
      fontWeight = FontWeight.w500;
    }

    return TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: fontWeight,
      letterSpacing: 0.5,
    );
  }
}
