import 'package:flutter/material.dart';
import 'package:hyphenatorx/src/extensions.dart';

import 'package:hyphenatorx/languages/language_ru.dart';
import 'package:hyphenatorx/languages/languageconfig.dart';
import 'package:hyphenatorx/src/calculationhelper.dart';
import 'package:hyphenatorx/src/letterutil.dart';
import 'package:hyphenatorx/token/linewrapperhyphen.dart';
import 'package:hyphenatorx/token/linewrappernohyphen.dart';
import 'package:hyphenatorx/token/tokens.dart';
import 'package:hyphenatorx/token/wrapresult.dart';

export 'package:hyphenatorx/languages/language_ru.dart';
export 'package:hyphenatorx/languages/languageconfig.dart';
export 'package:hyphenatorx/token/tokens.dart';
export 'package:hyphenatorx/token/wrapresult.dart';

/// Wrapper class hyphenating text.
///
/// Fully synchronous: the pattern data is compiled into the package
/// as Dart constants (see [LanguageConfig]). No asset loading involved.
class Hyphenator {
  late final CalculationHelper calc;

  static final RegExp _reBoundaries = RegExp(r'[\t\ ]+');
  static final RegExp _split = RegExp(r'\n|[\t ]+');
  static final RegExp _reCarriageReturn = RegExp(r'\r');

  /// Instantiates a Hyphenator for Russian, using the bundled patterns.
  factory Hyphenator.ru({
    final String symbol = '\u{00AD}',
    final String hyphen = '-',
    final int minWordLength = 5,
    final int minLetterCount = 3,
  }) =>
      Hyphenator(
        const LanguageRu(),
        symbol: symbol,
        hyphen: hyphen,
        minWordLength: minWordLength,
        minLetterCount: minLetterCount,
      );

  /// Instantiates a Hyphenator by language abbreviation, e.g. `ru`.
  ///
  /// Throws [ArgumentError] if the language is not available.
  /// Additional languages can be generated with `tool/tex2data.dart` -
  /// see README.
  factory Hyphenator.byAbbr(
    final String abbr, {
    final String symbol = '\u{00AD}',
    final String hyphen = '-',
    final int minWordLength = 5,
    final int minLetterCount = 3,
  }) {
    switch (abbr) {
      case 'ru':
        return Hyphenator.ru(
          symbol: symbol,
          hyphen: hyphen,
          minWordLength: minWordLength,
          minLetterCount: minLetterCount,
        );
      default:
        throw ArgumentError('Unsupported language "$abbr". Available: ["ru"]. '
            'Additional languages can be generated with tool/tex2data.dart '
            '- see README.');
    }
  }

  /// Instantiates a Hyphenator with a given [LanguageConfig].
  Hyphenator(
    final LanguageConfig config, {
    final String symbol = '\u{00AD}',
    final String hyphen = '-',
    final int minWordLength = 5,
    final int minLetterCount = 3,
  }) {
    if (minWordLength <= 0) {
      throw ArgumentError.value(minWordLength, 'minWordLength', 'must be > 0');
    }

    if (minLetterCount < 0) {
      throw ArgumentError.value(
          minLetterCount, 'minLetterCount', 'must be >= 0');
    }

    calc = CalculationHelper(
        config, minLetterCount, minWordLength, symbol, hyphen);
  }

  /// Returns cached and hyphenated words.
  List<String> get cachedHyphendWords => calc.cacheHyphendWords.values.toList();

  /// Returns cached and non-hyphenated words.
  List<String> get cachedNonHyphendWords =>
      calc.cacheNonHyphendWords.values.toList();

  /// Wraps the [text] with respect to the given [style] and [maxWidth].
  ///
  /// [WrapResult] holds a [Text] with the correctly hyphened [String].
  WrapResult wrap(
      final Text text, final TextStyle style, final double maxWidth) {
    final tokens = hyphenateTextToTokens(text.data!);
    final wrapper =
        LineWrapperHyphen(tokens, text, style, maxWidth, calc.hyphen);
    return wrapper.render();
  }

  /// Service method to wrap a text and NOT perform hyphenation.
  static WrapResult wrapNoHyphen(
      final Text text, final TextStyle style, final double maxWidth) {
    final List<TextPartToken> tokens = [];

    final List<String> parts =
        text.data!.replaceAll(_reCarriageReturn, '').splitWithDelim(_split);

    for (final part in parts) {
      if (part.isEmpty) {
        // Skip empty parts between matches.
      } else if (part == '\n') {
        tokens.add(NewlineToken());
      } else if (part.trim().isEmpty) {
        tokens.add(TabsAndSpacesToken(part));
      } else {
        tokens.add(WordToken([WordPartToken(part)]));
      }
    }

    final wrapper = LineWrapperNoHyphen(tokens, text, style, maxWidth);
    return wrapper.render();
  }

  /// Hyphenates a text and returns this text broken down into a tree.
  /// Each node being a potential candidate for leading and trailing
  /// hyphenation.
  ///
  /// WordPartToken is not only a pure syllable, but includes directly
  /// leading or trailing other symbols like punctuation.
  ///
  /// Returns a tree:
  ///
  ///     WordToken (many syllables)
  ///       - WordPartToken (syllables and surrounding symbols)
  ///     TabsAndSpacesToken
  ///     NewlineToken
  ///
  /// The actual result looks like this, WS meaning Whitespace and NL Newline:
  ///
  ///     [[The], WS, [arts], WS, [are], WS, [a], NL, [vast], WS, [sub, di, vi, sion], WS]
  List<TextPartToken> hyphenateTextToTokens(final String text) {
    final List<TextPartToken> tokens = [];

    final String hyph = hyphenateText(text); // this is expensive

    final List<String> parts =
        hyph.replaceAll(_reCarriageReturn, '').splitWithDelim(_split);

    for (final part in parts) {
      if (part.isEmpty) {
        // Skip empty parts between matches.
      } else if (part == '\n') {
        tokens.add(NewlineToken());
      } else if (part.trim().isEmpty) {
        tokens.add(TabsAndSpacesToken(part));
      } else {
        // Word
        tokens.add(WordToken(part
            .split(calc.symbol)
            .map<WordPartToken>((e) => WordPartToken(e))
            .toList(growable: false)));
      }
    }

    return tokens;
  }

  /// Hyphenates a text.
  ///
  /// The hyphen symbol will be placed inside words only.
  ///
  /// Setting `hyphenAtBoundaries: true` will add additional hyphens at
  /// the outer word boundaries, including punctuation etc.
  String hyphenateText(final String text, {bool hyphenAtBoundaries = false}) {
    final currentWord = StringBuffer();
    final result = StringBuffer();

    for (final rune in text.runes) {
      final c = String.fromCharCode(rune);
      final isLetter =
          LetterUtil.isLetter(c) || c.toUpperCase() != c.toLowerCase();

      if (isLetter) {
        currentWord.write(c);
      } else {
        if (currentWord.isNotEmpty) {
          result.write(hyphenateWord(currentWord.toString()));
          currentWord.clear();
        }

        result.write(c);
      }
    }

    if (currentWord.isNotEmpty) {
      result.write(hyphenateWord(currentWord.toString()));
    }

    if (!hyphenAtBoundaries) {
      return result.toString();
    }

    // Lazy method to add a hyphen symbol to word boundaries,
    // including punctuation etc. following or preceding a syllable.
    return result.toString().splitWithDelim(_reBoundaries).join(calc.symbol);
  }

  /// Hyphenates a single word.
  String hyphenateWord(final String word) {
    if (calc.isNotNeedHyphenate(word)) return word;

    final cachedHyphened = calc.cacheHyphendWords[word];
    if (cachedHyphened != null) return cachedHyphened;

    final cachedNonHyphened = calc.cacheNonHyphendWords[word];
    if (cachedNonHyphened != null) return cachedNonHyphened;

    final result = calc.hyphenate(word);

    if (calc.cacheHyphendWords.length >= CalculationHelper.maxCacheSize) {
      calc.cacheHyphendWords.clear();
    }
    if (calc.cacheNonHyphendWords.length >= CalculationHelper.maxCacheSize) {
      calc.cacheNonHyphendWords.clear();
    }

    if (result == word) {
      calc.cacheNonHyphendWords[word] = result;
    } else {
      calc.cacheHyphendWords[word] = result;
    }
    return result;
  }

  /// Returns syllables of a single word, being candidates for hyphenation.
  List<String> syllablesWord(final String word) {
    if (calc.isNotNeedHyphenate(word)) return <String>[word];

    final cachedHyphened = calc.cacheHyphenateSyllables[word];
    if (cachedHyphened != null) return cachedHyphened;

    final cachedNonHyphened = calc.cacheNonHyphenateSyllables[word];
    if (cachedNonHyphened != null) return cachedNonHyphened;

    final result = calc.syllables(word);

    if (calc.cacheHyphenateSyllables.length >= CalculationHelper.maxCacheSize) {
      calc.cacheHyphenateSyllables.clear();
    }
    if (calc.cacheNonHyphenateSyllables.length >=
        CalculationHelper.maxCacheSize) {
      calc.cacheNonHyphenateSyllables.clear();
    }

    if (result.length == 1) {
      calc.cacheNonHyphenateSyllables[word] = result;
    } else {
      calc.cacheHyphenateSyllables[word] = result;
    }
    return result;
  }
}
