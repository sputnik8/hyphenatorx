import 'package:flutter/material.dart';
import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:hyphenatorx/token/wrapresult.dart';

/// Text widget hyphenating and wrapping [text] synchronously.
///
/// The hyphenator is resolved once: either the injected [hyphenator]
/// is used, or `Hyphenator.byAbbr(language)` is created lazily.
/// There is no FutureBuilder - the first frame renders hyphenated text.
class TextHyphenated extends StatefulWidget {
  final String text;

  /// Language abbreviation, e.g. `ru`. Used only when no [hyphenator]
  /// is injected. Kept for forward compatibility with additional
  /// languages.
  final String language;

  /// Optional injected hyphenator. If null, one is created from
  /// [language].
  final Hyphenator? hyphenator;

  final String symbol;
  final TextStyle? style;
  final GlobalKey? textKey;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  //
  final bool doShowDebug;

  const TextHyphenated(
    this.text, {
    super.key,
    this.language = 'ru',
    this.hyphenator,
    this.symbol = '\u{00AD}',
    this.style,
    this.textKey,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.doShowDebug = false,
  });

  @override
  State<TextHyphenated> createState() => _TextHyphenatedState();
}

class _TextHyphenatedState extends State<TextHyphenated> {
  Hyphenator? _ownHyphenator;

  // Rebuilding must not re-hyphenate and re-measure the text unless
  // one of the wrapping inputs actually changed.
  String? _memoText;
  double? _memoMaxWidth;
  Hyphenator? _memoHyphenator;
  TextStyle? _memoStyle;
  bool _hasMemo = false;
  late WrapResult _memoResult;

  Hyphenator get _hyphenator {
    final injected = widget.hyphenator;
    if (injected != null) return injected;
    return _ownHyphenator ??=
        Hyphenator.byAbbr(widget.language, symbol: widget.symbol);
  }

  @override
  void didUpdateWidget(covariant TextHyphenated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hyphenator == null &&
        (oldWidget.language != widget.language ||
            oldWidget.symbol != widget.symbol)) {
      _ownHyphenator = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cnt) {
      final maxWidth = cnt.maxWidth;

      // Unbounded constraints (e.g. inside a scrollable):
      // no wrapping possible, render the plain text.
      if (!maxWidth.isFinite) {
        return _makeText(widget.text);
      }

      final style = widget.style ?? const TextStyle();
      final wrapped = _wrap(style, maxWidth);
      final wrappedText = _makeText(wrapped.textStr);

      if (!widget.doShowDebug) {
        return wrappedText;
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(child: wrappedText),
          Positioned(
            right: 0,
            bottom: -80,
            child: ColoredBox(
                color: wrapped.isSizeMatching
                    ? Colors.green.withAlpha(200)
                    : Colors.red.withAlpha(200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('is-match: ' + wrapped.isSizeMatching.toString()),
                    Text('size-text : ' +
                        wrapped.debugSizeByText.width.toString() +
                        '/' +
                        wrapped.debugSizeByText.height.toString()),
                    Text('size-paint: ' +
                        wrapped.size.width.toString() +
                        '/' +
                        wrapped.size.height.toString()),
                    Text('max-width: ' + wrapped.maxWidth.toString()),
                  ],
                )),
          ),
        ],
      );
    });
  }

  WrapResult _wrap(TextStyle style, double maxWidth) {
    final hyphenator = _hyphenator;

    if (_hasMemo &&
        _memoText == widget.text &&
        _memoMaxWidth == maxWidth &&
        _memoHyphenator == hyphenator &&
        _memoStyle == style) {
      return _memoResult;
    }

    final result = hyphenator.wrap(_makeText(widget.text), style, maxWidth);

    _memoText = widget.text;
    _memoMaxWidth = maxWidth;
    _memoHyphenator = hyphenator;
    _memoStyle = style;
    _memoResult = result;
    _hasMemo = true;
    return result;
  }

  Text _makeText(String str) {
    return Text(
      str,
      style: widget.style,
      key: widget.textKey,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      locale: widget.locale,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      textScaleFactor: widget.textScaleFactor,
      maxLines: widget.maxLines,
      semanticsLabel: widget.semanticsLabel,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionColor: widget.selectionColor,
    );
  }
}
