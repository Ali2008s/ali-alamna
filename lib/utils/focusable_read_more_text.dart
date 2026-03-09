import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TrimMode enum
enum FocusableTrimMode { length, line }

/// Add read more button to a long text
class FocusableReadMoreText extends StatefulWidget {
  const FocusableReadMoreText(
    this.data, {
    super.key,
    this.trimExpandedText = ' read less',
    this.trimCollapsedText = ' ...read more',
    this.colorClickableText,
    this.colorFocusedText = Colors.white,
    this.trimLength = 250,
    this.trimLines = 3,
    this.trimMode = FocusableTrimMode.line,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.focusNode,
    this.onKeyEvent,
  });

  final String data;
  final FocusNode? focusNode;
  final String trimExpandedText;
  final String trimCollapsedText;
  final Color? colorClickableText;
  final Color? colorFocusedText;
  final int trimLength;
  final int trimLines;
  final FocusableTrimMode trimMode;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final double? textScaleFactor;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  @override
  FocusableReadMoreTextState createState() => FocusableReadMoreTextState();
}

const String _kEllipsis = '\u2026';

const String _kLineSeparator = '\u2028';

class FocusableReadMoreTextState extends State<FocusableReadMoreText> {
  bool _readMore = true;

  void _onTapLink() {
    setState(() => _readMore = !_readMore);
  }

  @override
  Widget build(BuildContext context) {
    bool isFocusApply = true;
    bool isFocus = widget.focusNode?.hasFocus ?? false;
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = widget.style;

    if (widget.style == null || widget.style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
    }

    final textAlign =
        widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    final textDirection = widget.textDirection ?? Directionality.of(context);
    final textScaleFactor =
        widget.textScaleFactor != null ? TextScaler.linear(widget.textScaleFactor!) : MediaQuery.textScalerOf(context);
    final overflow = defaultTextStyle.overflow;
    final locale = widget.locale ?? Localizations.maybeLocaleOf(context);

    final colorClickableText =
        widget.colorClickableText ?? Theme.of(context).colorScheme.secondary;

    TextSpan link = TextSpan(
      text: _readMore ? widget.trimCollapsedText : widget.trimExpandedText,
      style: effectiveTextStyle!.copyWith(color: isFocus ? widget.colorFocusedText : colorClickableText, decoration: isFocus ? TextDecoration.underline : null, decorationColor: isFocus ? widget.colorFocusedText : null, decorationThickness: isFocus ? 2 : null),
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
    );

    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;

        // Create a TextSpan with data
        final text = TextSpan(style: effectiveTextStyle, text: widget.data);

        // Layout and measure link
        TextPainter textPainter = TextPainter(
          text: link,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaler: textScaleFactor,
          maxLines: widget.trimLines,
          ellipsis: overflow == TextOverflow.ellipsis ? _kEllipsis : null,
          locale: locale,
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final linkSize = textPainter.size;

        // Layout and measure text
        textPainter.text = text;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final textSize = textPainter.size;

        // Get the endIndex of data
        bool linkLongerThanLine = false;
        int? endIndex;

        if (linkSize.width < maxWidth) {
          final pos = textPainter.getPositionForOffset(
            Offset(textSize.width - linkSize.width, textSize.height),
          );
          endIndex = textPainter.getOffsetBefore(pos.offset);
        } else {
          var pos = textPainter.getPositionForOffset(
            textSize.bottomLeft(Offset.zero),
          );
          endIndex = pos.offset;
          linkLongerThanLine = true;
        }

        TextSpan textSpan;
        switch (widget.trimMode) {
          case FocusableTrimMode.length:
            if (widget.trimLength < widget.data.length) {
              isFocusApply = true;
              textSpan = TextSpan(
                style: effectiveTextStyle,
                text: _readMore
                    ? widget.data.substring(0, widget.trimLength)
                    : widget.data,
                children: <TextSpan>[link],
              );
            } else {
              isFocusApply = false;
              textSpan = TextSpan(style: effectiveTextStyle, text: widget.data);
            }
            break;
          case FocusableTrimMode.line:
            if (textPainter.didExceedMaxLines) {
              isFocusApply = true;
              textSpan = TextSpan(
                style: effectiveTextStyle,
                text: _readMore
                    ? widget.data.substring(0, endIndex) +
                          (linkLongerThanLine ? _kLineSeparator : '')
                    : widget.data,
                children: <TextSpan>[link],
              );
            } else {
              isFocusApply = false;
              textSpan = TextSpan(style: effectiveTextStyle, text: widget.data);
            }
            break;
        }

        return SelectableText.rich(
          textSpan,
          textAlign: textAlign,
          textDirection: textDirection,
        );
      },
    );

    return Focus(
            focusNode: isFocusApply ? widget.focusNode : null,
            onFocusChange: (result) => setState(() {}),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                  _onTapLink();
                }
              }
              return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
            },
            child: result
          );
  }
}
