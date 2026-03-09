import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

class TabsItemComponent extends StatelessWidget {
  const TabsItemComponent({
    super.key,
    required this.label,
    required this.focusNode,
    required this.isFocused,
    required this.onFocusChange,
    required this.onKeyEvent,
    required this.onTap,
  });

  final String label;
  final FocusNode focusNode;
  final RxBool isFocused;
  final void Function(bool hasFocus) onFocusChange;
  final KeyEventResult Function(FocusNode node, KeyEvent event) onKeyEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onKeyEvent: onKeyEvent,
      child: GestureDetector(
        onTap: onTap,
        child: Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.08),
              borderRadius: radius(6),
              border: isFocused.value ? Border.all(color: white, width: 2) : null,
            ),
            child: Text(label, style: primaryTextStyle(color: white)),
          ),
        ),
      ),
    );
  }
}