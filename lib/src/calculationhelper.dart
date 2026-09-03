import 'package:hyphenatorx/languages/languageconfig.dart';

class CalculationHelper {
  final _startEndMarker = '.';
  final Map<String, List<int>> _patterns;
  final Map<String, List<int>> _exceptions;
  final int _minLetterCount;
  final int _minWordLength;
  final String symbol;
  final String hyphen;

  final Map<String, String> cacheHyphendWords = {};
  final Map<String, String> cacheNonHyphendWords = {};
  final Map<String, List<String>> cacheHyphenateSyllables = {};
  final Map<String, List<String>> cacheNonHyphenateSyllables = {};

  /// Upper bound per cache. Cleared when reached to avoid
  /// unbounded memory growth in long-running apps.
  static const int maxCacheSize = 10000;

  CalculationHelper(LanguageConfig config, this._minLetterCount,
      this._minWordLength, this.symbol, this.hyphen)
      : _patterns = _parsePatterns(config.patterns),
        _exceptions = _parseExceptions(config.exceptions);

  String hyphenate(final String word) =>
      _hyphenateByMask(word, _generateHyphenationMask(word));

  List<String> syllables(final String word) => hyphenate(word).split(symbol);

  bool isNotNeedHyphenate(final String input) => input.length < _minWordLength;

  // -------------------------------------------------------------------------
  // Generate mask
  // -------------------------------------------------------------------------

  List<int> _generateHyphenationMask(final String word) {
    final exception = _exceptions[word.toLowerCase()];
    if (exception != null) return exception;

    final levels = _generateLevelsForWord(word.toLowerCase());
    return _correctHyphenationMask(_hyphenatedMaskFromLevels(levels));
  }

  // -------------------------------------------------------------------------
  // Hyphenate by mask
  // -------------------------------------------------------------------------

  String _hyphenateByMask(final String word, final List<int> mask) {
    final result = StringBuffer();

    for (int i = 0; i < word.length; i++) {
      if (mask[i] > 0) {
        result.write(symbol);
      }
      result.write(word[i]);
    }

    return result.toString();
  }

  // -------------------------------------------------------------------------
  // Generate levels
  // -------------------------------------------------------------------------

  /// Exact-match lookup over a [Map]: every substring of the padded word
  /// is probed with O(1) access, replacing the previous sorted-list scan.
  List<int> _generateLevelsForWord(final String word) {
    final wordString = '$_startEndMarker$word$_startEndMarker';

    final levels = List<int>.filled(wordString.length, 0, growable: false);

    for (int i = 0; i < wordString.length - 2; ++i) {
      for (int count = 1; count <= wordString.length - i; ++count) {
        final pattern = _patterns[wordString.substring(i, i + count)];
        if (pattern == null) continue;

        for (int levelIndex = 0;
            levelIndex < pattern.length - 1;
            ++levelIndex) {
          final int level = pattern[levelIndex];

          if (level > levels[i + levelIndex]) {
            levels[i + levelIndex] = level;
          }
        }
      }
    }

    return levels;
  }

  List<int> _hyphenatedMaskFromLevels(final List<int> levels) {
    final int length = levels.length - 2;

    final hyphenationMask = List<int>.filled(length, 0, growable: false);

    for (int i = 1; i < length; i++) {
      if (levels[i + 1] % 2 != 0) hyphenationMask[i] = 1;
    }

    return hyphenationMask;
  }

  /// Returns the modified list itself.
  List<int> _correctHyphenationMask(final List<int> mask) {
    if (mask.length > _minLetterCount) {
      for (int i = 0; i < _minLetterCount; i++) {
        mask[i] = 0;
      }

      final correctionLength = _minLetterCount > 0 ? _minLetterCount - 1 : 0;

      for (int i = mask.length - correctionLength; i < mask.length; i++) {
        mask[i] = 0;
      }
    } else {
      for (int i = 0; i < mask.length; i++) {
        mask[i] = 0;
      }
    }

    return mask;
  }

  // -------------------------------------------------------------------------
  // TeX notation parsers
  // -------------------------------------------------------------------------

  /// Parses patterns like `.аб3р`: digits are the inter-letter levels,
  /// letters and dots form the matched string. A missing leading or
  /// trailing digit means level 0, therefore
  /// `levels.length == result.length + 1`.
  static Map<String, List<int>> _parsePatterns(Iterable<String> sources) {
    final map = <String, List<int>>{};

    for (final source in sources) {
      final levels = <int>[];
      final result = StringBuffer();

      var expectLevel = true;
      for (final rune in source.runes) {
        final digit = rune - 0x30;
        if (digit >= 0 && digit <= 9) {
          levels.add(digit);
          expectLevel = false;
        } else {
          if (expectLevel) levels.add(0);
          result.writeCharCode(rune);
          expectLevel = true;
        }
      }
      if (expectLevel) levels.add(0);

      map[result.toString()] = List.unmodifiable(levels);
    }

    return map;
  }

  /// Parses exceptions like `во-жд`: a `-` marks a break point before
  /// the letter following it. The resulting mask contains one entry per
  /// letter plus one trailing entry, thus
  /// `mask.length == key.length + 1`.
  static Map<String, List<int>> _parseExceptions(Iterable<String> sources) {
    final map = <String, List<int>>{};

    for (final source in sources) {
      final mask = <int>[];
      final key = StringBuffer();

      var breakBeforeNext = false;
      for (final rune in source.runes) {
        if (rune == 0x2D) {
          breakBeforeNext = true;
        } else {
          key.writeCharCode(rune);
          mask.add(breakBeforeNext ? 1 : 0);
          breakBeforeNext = false;
        }
      }
      mask.add(0);

      map[key.toString()] = List.unmodifiable(mask);
    }

    return map;
  }
}
