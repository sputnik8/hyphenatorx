import 'package:flutter/widgets.dart';
import 'package:hyphenatorx/src/token/texthelper.dart';

import 'tokens.dart';
import 'wrapresult.dart';

/// Hyphenates tokens with respect to the attributes of
/// [Text], [TextStyle] and [maxWidth].
class LineWrapperHyphen {
  final String _hyphen;
  late final double _maxWidth;
  final List<List<TextPartToken>> _lines = [];
  late final TextPainter _painter;
  final TextStyle _style;
  final Text _text;
  final List<TextPartToken> _tokens;

  /// Constructor.
  LineWrapperHyphen(List<TextPartToken> tokens, this._text, this._style,
      this._maxWidth, this._hyphen)
      : _tokens = tokens {
    final Map<String, Size> tokensWidthCache = {};

    _painter = TextPainter(
      textDirection: _text.textDirection ?? TextDirection.ltr,
      maxLines: _text.maxLines,
      textScaleFactor: _text.textScaleFactor ?? 1.0,
      locale: _text.locale,
      textAlign: _text.textAlign ?? TextAlign.start,
      textHeightBehavior: _text.textHeightBehavior,
      textWidthBasis: _text.textWidthBasis ?? TextWidthBasis.parent,
    );

    for (final TextPartToken part in tokens) {
      if (part is WordToken) {
        for (final WordPartToken p in part.parts) {
          _setWidths(p.text, tokensWidthCache, p);
        }
      } else if (part is TabsAndSpacesToken) {
        _setWidths(part.text, tokensWidthCache, part);
      } else if (part is NewlineToken) {
        part.sizeHyphen = const Size(0, 0);
        part.sizeNoHyphen = const Size(0, 0);
        part.sizeCurrent = const Size(0, 0);
      }
    }
  }

  /// Sets the widths of the token with respect to hyphend and not-hyphened.
  void _setWidths(String syllable, Map<String, Size> tokensWidthCache,
      TextPartToken token) {
    final syllableHyphened = '$syllable$_hyphen';

    if (tokensWidthCache[syllable] == null) {
      _painter.text = TextSpan(text: syllable, style: _style);
      _painter.layout();
      tokensWidthCache[syllable] = _painter.size;

      _painter.text = TextSpan(text: syllableHyphened, style: _style);
      _painter.layout();
      tokensWidthCache[syllableHyphened] = _painter.size;
    }

    token.sizeHyphen = tokensWidthCache[syllableHyphened]!;
    token.sizeNoHyphen = tokensWidthCache[syllable]!;
    token.sizeCurrent = token.sizeNoHyphen;
  }

  /// Returns the resulting String with hyphens and linebreaks.
  WrapResult render() {
    if (_tokens.isEmpty) {
      return WrapResult(_text, _style, _maxWidth, Size(0, 0), _lines);
    }

    final List<TextPartToken> line = [];

    for (final token in _tokens) {
      // ------------------------------------------------------------
      // NEWLINE
      // ------------------------------------------------------------
      if (token is NewlineToken) {
        _lines.add(_cloneLineAndAddNewline(line));
        line.clear();
      }
      // ------------------------------------------------------------
      // TABS AND SPACES
      // ------------------------------------------------------------
      else if (token is TabsAndSpacesToken && line.isNotEmpty) {
        if (_fits([token], line)) {
          line.add(token);
        } else {
          _lines.add(_cloneLineAndAddNewline(line));
          line.clear();
        }
      }
      // ------------------------------------------------------------
      // WORD
      // ------------------------------------------------------------
      else if (token is WordToken) {
        if (!_tryAddWordToLine(token, line)) {
          if (line.isNotEmpty) {
            _lines.add(_cloneLineAndAddNewline(line));
            line.clear();
          }

          if (!_tryAddWordToLine(token, line)) {
            if (line.isNotEmpty) {
              _lines.add(_cloneLineAndAddNewline(line));
              line.clear();
            }
            // Forced: word does not fit a full line at all.
            line.add(token);
          }
        }
      }
    }

    if (line.isNotEmpty) {
      _lines.add(line);
    }

    if (_text.maxLines != null && _lines.length > _text.maxLines!) {
      return WrapResult(_text, _style, _maxWidth, Size(0, 0), _lines);
    }

    final str = _lines
        .map<String>((line) => line.map((e) => e.render()).join())
        .join();
    _painter.text = TextSpan(text: str, style: _style);
    _painter.layout();

    return WrapResult(
        TextHelper.clone(_text, str), _style, _maxWidth, _painter.size, _lines);
  }

  bool _tryAddWordToLine(WordToken token, List<TextPartToken> line) {
    final partLength = token.parts.length;

    for (int i = partLength; i > 0; i--) {
      final prelist = token.parts.sublist(0, i);
      final postlist = token.parts.sublist(i, partLength);

      if (i == partLength && _fits(prelist, line)) {
        line.addAll(prelist);
        return true;
      }

      if (i < partLength) {
        final hyphened = _doHyphenLast(prelist);
        if (_fits(hyphened, line)) {
          line.addAll(hyphened);
          _lines.add(_cloneLineAndAddNewline(line));
          line.clear();
          line.addAll(postlist);
          return true;
        }
      }
    }
    return false;
  }

  List<TextPartToken> _cloneLineAndAddNewline(List<TextPartToken> line) {
    List<TextPartToken> clone = [...line];
    while (clone.isNotEmpty && clone.last is TabsAndSpacesToken) {
      clone.removeLast();
    }
    clone.add(NewlineToken());
    return clone;
  }

  bool _fits(final List<TextPartToken> tokens, List<TextPartToken> line) {
    double w = line.fold<double>(0, (sum, item) {
      return sum + item.sizeCurrent!.width;
    });

    w += tokens.fold<double>(0, (sum, item) {
      return sum + item.sizeCurrent!.width;
    });

    return w <= _maxWidth;
  }

  List<TextPartToken> _doHyphenLast(List<WordPartToken> tokens) {
    return tokens.sublist(0, tokens.length - 1)
      ..add(tokens.last.toHyphenAndSize(_hyphen));
  }
}
