import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

class OTPTextFieldTV extends StatefulWidget {
  final int pinLength;
  final Function(String)? onChanged;
  final Function(String)? onCompleted;
  final bool showUnderline;
  final InputDecoration? decoration;
  final BoxDecoration? boxDecoration;
  final double fieldWidth;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final void Function(List<OTPLengthModel> list)? onListMake;  

  final FocusNode? lastFocusNode;
  final FocusNode? nextFocusNode;

  final Function(FocusNode focusNode)? manageLastFocusMode;

  const OTPTextFieldTV({
    this.pinLength = 4,
    this.fieldWidth = 40,
    this.onChanged,
    this.onCompleted,
    this.showUnderline = false,
    this.decoration,
    this.boxDecoration,
    this.textStyle,
    this.cursorColor,
    this.manageLastFocusMode,
    super.key,
    this.lastFocusNode,
    this.nextFocusNode,
    this.onListMake,
  });

  @override
  OTPTextFieldTVState createState() => OTPTextFieldTVState();
}

class OTPTextFieldTVState extends State<OTPTextFieldTV> {
  List<OTPLengthModel> list = [];
  int currentIndex = 0;
  bool _isNavigating = false;

  String get concatText => list.map((e) => e.textEditingController!.text).join();

  @override
  void initState() {
    super.initState();
    list = List.generate(widget.pinLength, (index) {
      return OTPLengthModel(
        textEditingController: TextEditingController(),
        // FocusNode with an onKeyEvent handler attached directly so the
        // TextField owns focus from the start. This avoids the outer Focus
        // widget creating a *separate* focus node that intercepts events
        // before the TextField's node can process typed characters (Bug 1).
        focusNode: FocusNode(
          onKeyEvent: (node, event) => _handleKeyEvent(index, node, event),
        ),
      );
    });

    // Attach a focus-change listener to each node so currentIndex always
    // reflects the field that actually has focus (required for correct
    // border highlighting and text-selection on first focus).
    for (int i = 0; i < list.length; i++) {
      final idx = i;
      list[idx].focusNode!.addListener(() {
        if (list[idx].focusNode!.hasFocus) {
          if (mounted) setState(() => currentIndex = idx);
        }
      });
    }

    // Request focus after the frame is built to avoid timing issues on
    // physical devices. Using addPostFrameCallback is correct here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && list.first.focusNode != null) {
        list.first.focusNode?.requestFocus();
      }
    });

    widget.onListMake?.call(list);
  }

  /// Centralised key-event handler shared by every field's FocusNode.
  /// Attaching it to the FocusNode (rather than to a wrapping Focus widget)
  /// ensures the TextField itself holds focus, so typed characters are
  /// delivered immediately — even on the very first field after screen load.
  KeyEventResult _handleKeyEvent(int index, FocusNode node, KeyEvent event) {
    final model = list[index];
    if (event is KeyDownEvent) {
      // Right arrow / D-PAD right — advance to next field
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (index < widget.pinLength - 1) {
          moveToNextFocus(index, fromKeyEvent: true);
          return KeyEventResult.handled;
        }
      }

      // Left arrow / D-PAD left — go back to previous field
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (index > 0) {
          moveToPreviousFocus(index, fromKeyEvent: true);
          return KeyEventResult.handled;
        }
      }

      // Down arrow / D-PAD down — leave OTP area downward
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        moveToDownFocus(index);
        return KeyEventResult.handled;
      }

      // Up arrow / D-PAD up — stay inside OTP area; swallow the event so
      // the framework doesn't move focus to an unintended widget above.
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        return KeyEventResult.handled;
      }

      // Select / Enter / D-PAD center — advance or complete
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        if (model.textEditingController!.text.isNotEmpty) {
          if (index == widget.pinLength - 1) {
            moveToDownFocus(index);
          } else {
            moveToNextFocus(index, fromKeyEvent: true);
          }
          return KeyEventResult.handled;
        }
      }

      // Backspace — clear current field; if already empty, go to previous
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (model.textEditingController!.text.isEmpty && index > 0) {
          moveToPreviousFocus(index, fromKeyEvent: true);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void moveToNextFocus(int index, {bool fromKeyEvent = false}) {
    if (_isNavigating && !fromKeyEvent) return;
    _isNavigating = true;

    if (index == list.length - 1) {
      // Last field - move to next external focus node or complete
      widget.onCompleted?.call(concatText);
      if (widget.nextFocusNode != null) {
        Future.microtask(() {
          if (mounted) {
            widget.nextFocusNode?.requestFocus();
            _isNavigating = false;
          }
        });
      } else {
        _isNavigating = false;
      }
    } else {
      // Move to next OTP field
      Future.microtask(() {
        if (mounted) {
          list[index + 1].focusNode!.requestFocus();
          if (!fromKeyEvent) {
            list[index + 1].textEditingController!.clear();
          }
          if (list[index + 1].focusNode != null) {
            widget.manageLastFocusMode?.call(list[index + 1].focusNode!);
          }
          setTextSelection(index + 1);
          _isNavigating = false;
        }
      });
    }
  }

  void moveToPreviousFocus(int index, {bool fromKeyEvent = false}) {
    if (_isNavigating && !fromKeyEvent) return;
    _isNavigating = true;

    if (index > 0) {
      Future.microtask(() {
        if (mounted) {
          list[index - 1].focusNode!.requestFocus();
          if (list[index - 1].focusNode != null) {
            widget.manageLastFocusMode?.call(list[index - 1].focusNode!);
          }
          setTextSelection(index - 1);
          _isNavigating = false;
        }
      });
    } else {
      _isNavigating = false;
    }
  }
  
  void moveToDownFocus(int index) {
    if (widget.nextFocusNode != null) {
      widget.nextFocusNode?.requestFocus();
    }
  }

  void setTextSelection(int index) {
    currentIndex = index;
    final controller = list[index].textEditingController!;
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  }

  @override
  void dispose() {
    for (var element in list) {
      element.textEditingController?.dispose();
      element.focusNode?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.pinLength, (index) {
        final model = list[index];
        return Container(
          width: widget.fieldWidth,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          // Drive border highlight from currentIndex so the indicator
          // updates even before the first navigation round-trip.
          decoration: widget.boxDecoration ??
              BoxDecoration(
                border: Border.all(
                  color: currentIndex == index && (model.focusNode?.hasFocus ?? false)
                      ? context.primaryColor
                      : Colors.white54,
                  width: currentIndex == index && (model.focusNode?.hasFocus ?? false) ? 2 : 1,
                ),
                borderRadius: radius(4),
              ),
          alignment: Alignment.center,
          // No wrapping Focus widget — the TextField's own FocusNode (which
          // already has onKeyEvent attached) is the sole focus owner for
          // this field. This guarantees typed input is received immediately
          // on the very first field without a focus round-trip (Bug 1 fix).
          child: TextField(
            controller: model.textEditingController,
            focusNode: model.focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            // autofillHints intentionally omitted: the oneTimeCode hint
            // makes the autofill framework treat all fields as a single
            // group, so a system-keyboard "clear" wipes every field at
            // once. Without the hint each field is independent and clear
            // only affects the focused field (Bug 2 fix).
            maxLength: 1,
            cursorColor: widget.cursorColor,
            style: widget.textStyle,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: index == widget.pinLength - 1
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: widget.decoration ??
                const InputDecoration(
                  border: InputBorder.none,
                  counter: Offstage(),
                  contentPadding: EdgeInsets.zero,
                ),
            onChanged: (s) {
              if (s.length == widget.pinLength) {
                // Handle a full-OTP paste in a single field
                for (int i = 0; i < widget.pinLength; i++) {
                  list[i].textEditingController!.text = s[i];
                }
                widget.onCompleted?.call(concatText);
                return;
              }

              if (s.isEmpty) {
                model.textEditingController!.clear();
                moveToPreviousFocus(index);
              } else if (s.length == 1) {
                moveToNextFocus(index);
              }

              widget.onChanged?.call(concatText);
              setState(() {});
            },
            onSubmitted: (s) {
              if (s.isEmpty) {
                moveToPreviousFocus(index);
              } else {
                moveToNextFocus(index);
              }
            },
            onTap: () async {
              list[index].focusNode!.requestFocus();
              setTextSelection(index);
            },
          ),
        );
      }),
    );
  }
}

class OTPLengthModel {
  final TextEditingController? textEditingController;
  final FocusNode? focusNode;

  OTPLengthModel({
    this.textEditingController,
    this.focusNode,
  });
}