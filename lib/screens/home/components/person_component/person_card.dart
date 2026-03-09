import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../utils/app_common.dart';
import '../../../../utils/colors.dart';
import '../../../../services/focus_sound_service.dart';
import '../../../person/model/person_model.dart';
import 'person_component_controller.dart';

class PersonCard extends StatelessWidget {
  final CastResponse personDet;
  final double? height;
  final double? width;
  final Function(bool)? onFocusChange;
  final int? index;
  final FocusNode? focusNode;
  final String? categoryName;
  final PersonComponentController? controller;
  final VoidCallback? onTap;
  final int? totalItems;

  const PersonCard({super.key, required this.personDet, this.controller, this.height, this.width, this.onFocusChange, this.index, this.focusNode, this.categoryName, this.onTap, this.totalItems});

  @override
  Widget build(BuildContext context) {
    double size = (width ?? height ?? 120);
    return Focus(
      autofocus: false,
      focusNode: focusNode,
      canRequestFocus: true,
      onFocusChange: (value) {
        onFocusChange?.call(value);
        if (index != null && controller != null) {
          controller!.onFocusChange(index!, value);
        }
        if (value) {
          FocusSoundService.play();
        }
      },
      onKeyEvent: controller != null
          ? (node, event) {
              try {
                if (index != null) {
                  // Handle arrow left
                  final leftResult = controller!.handleArrowLeft(index!, event);
                  if (leftResult == KeyEventResult.handled) return leftResult;

                  // Handle arrow right
                  final rightResult = controller!.handleArrowRight(index!, totalItems ?? 0, event);
                  if (rightResult == KeyEventResult.handled) return rightResult;

                  // Handle arrow up
                  final upResult = controller!.handleArrowUp(event, categoryName);
                  if (upResult == KeyEventResult.handled) return upResult;

                  // Handle select
                  final selectResult = controller!.handleSelect(personDet, event);
                  if (selectResult == KeyEventResult.handled) return selectResult;
                }
              } catch (e) {
                log('PersonCard onKeyEvent error: $e');
              }
              return KeyEventResult.ignored;
            }
          : null,
      child: GestureDetector(
        onTap: onTap ??
            () {
              if (controller != null) {
                controller!.openPersonDetails(personDet);
              }
            },
        child: index != null && controller != null
            ? Obx(
                () {
                  final focusState = controller!.getFocusState(index!);
                  final hasFocus = focusState.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(hasFocus ? 0.98 : 1.0),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle, border: focusBorder(hasFocus)),
                        child: ClipOval(
                          child: SizedBox(
                            height: size,
                            width: size,
                            child: CachedImageWidget(url: personDet.data.first.profileImage, height: size, width: size, fit: BoxFit.cover, alignment: Alignment.topCenter),
                          ),
                        ),
                      ),
                      if (hasFocus) Text(personDet.data.first.name, textAlign: TextAlign.center, style: boldTextStyle()),
                    ],
                  );
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
                    child: ClipOval(
                      child: SizedBox(
                        height: size,
                        width: size,
                        child: CachedImageWidget(url: personDet.data.first.profileImage, height: size, width: size, fit: BoxFit.cover, alignment: Alignment.topCenter),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
