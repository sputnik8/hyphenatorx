# Hyphenator

Implementation of a Russian hyphenation algorithm based on TeX definitions.

* Offers a `Widget` hyphenating a `String` and wrapping the result based on the available width.
* Offers various function calls to hyphenate a `String` at all possible positions. 

The `tex` patterns used in the algorithm can be at [tug.org](https://tug.org/tex-hyphen/).

Test the live demo [https://xerik.github.io/hyphenatorx/](https://xerik.github.io/hyphenatorx/).

**Wrapping and Scaling Text**

The package [text_wrap_auto_size](https://pub.dev/packages/text_wrap_auto_size) uses
`hyphenatorx` for wrapping and auto scaling text - with and without hyphenation.

## Quickstart

```dart 
import 'package:hyphenatorx/widget/texthyphenated.dart';

// под-
// раз-
// де-
// ле-
// ние
TextHyphenated(
  'подразделение',
  style: TextStyle(fontSize: 56),
)
```

```dart
import 'package:hyphenatorx/hyphenatorx.dart';
final hyphenator = Hyphenator.ru(symbol: '_');

// 'под_раз_де_ле_ние_ _под_раз_де_ле_ние'
print(
  hyphenator.hyphenateText('подразделение подразделение',
    hyphenAtBoundaries: true));

// под_раз_де_ле_ние под_раз_де_ле_ние
print(hyphenator.hyphenateText('подразделение подразделение'));

// под_раз_де_ле_ние
print(hyphenator.hyphenateWord('подразделение'));

// ['под', 'раз', 'де', 'ле', 'ние']
print(hyphenator.syllablesWord('подразделение'));
```

## Usage

Hyphenator uses synchronous pattern data compiled into the package. Russian is
bundled; additional language configurations can be generated from the TeX
sources with `tool/tex2data.dart`.

**Cache**

Internally, hyphenated as well as non-hyphenated words are cached. Complete texts are not cached.

**Hyphen symbol**

The hyphen symbol can be defined, the default is the soft-wrap `'\u{00AD}'`.

### Synchronous Instantiation

Use the Russian factory or instantiate a generated configuration directly.

```dart 
import 'package:hyphenatorx/hyphenatorx.dart';

final hyphenator = Hyphenator.ru(symbol: '_');

// Equivalent abbreviation-based factory:
final sameHyphenator = Hyphenator.byAbbr('ru', symbol: '_');
```

### Widget Usage

This Widget outputs a `Text`. It hyphenates and wraps the input `String` depending on the available width. 

```dart 
import 'package:hyphenatorx/widget/texthyphenated.dart';

TextHyphenated(
  'подразделение',
  style: TextStyle(fontSize: 56),
)

// Wraps the output according to the available width:
// 
// под-
// раз-
// де-
// ле-
// ние
```

### Function Call

Inject the hyphenation symbol at all possible positions.

```dart
final hyphenator = Hyphenator.ru(symbol: '_');

expect(
  hyphenator.hyphenateText('подразделение подразделение',
    hyphenAtBoundaries: true),
  'под_раз_де_ле_ние_ _под_раз_де_ле_ние');

expect(
  hyphenator.hyphenateText('подразделение подразделение'),
  'под_раз_де_ле_ние под_раз_де_ле_ние');

expect(
  hyphenator.hyphenateWord('подразделение'),
  'под_раз_де_ле_ние');

expect(
  hyphenator.syllablesWord('подразделение'),
  ['под', 'раз', 'де', 'ле', 'ние']);
```

Access the wrapped hyphenation result respecting the given width.

```dart
final hyphenator = Hyphenator(Language_en_us());

WrapResult wrap = hyphenator.wrap(
  final Text text, final TextStyle style, final maxWidth);

// The hyphenated text with hyphens and newlines:
// 
// sub-
// di-
// vi-
// sion- 
print( wrap.textStr ); 

// Whether the returned text is equal to 
// or smaller than maxWidth. 
//
// If FALSE, try a different font size.

print( wrap.isSizeMatching );  
```

### Manual Hyphenation 

Iterate through the token tree for a custom approach of hyphenation. Before and after each token a valid hyphen could be added. 

```dart
final text = """A vast subdivision of culture, 
    composed of many creative endeavors and disciplines.""";

final hyphenator = Hyphenator(Language_en_us());
final List<TextPartToken> tokens = hyphenator.hyphenateTextToTokens(text);

tokens.forEach((part) {
  if (part is NewlineToken) {
    print(part.text); // = is always a single newline
  } else if (part is TabsAndSpacesToken) {
    print(part.text); // tabs and spaces found in `text`
  } else if (part is WordToken) {
    part.parts.forEach((syllableAndSurrounding) {
      print(syllableAndSurrounding.text); // sub / di / vi / sion.
    });
  }
});

// A
// vast
// sub
// di
// vi
// sion
```

## Languages and Abbreviations

The abbreviations correspond with the `tex` file names found at [tug.org](https://tug.org/tex-hyphen/).

### Strings 

```dart
List<String> abbr = Hyphenator.languageAbbr();

print(abbr); 

[af, as, bg, bn, ca, cop, cs, cy, da, de_1901, de_1996, de_ch_1901, el_monoton, el_polyton, en_gb, en_us, eo, es, et, eu, fi, fr, fur, ga, gl, grc, gu, hi, hr, hsb, hu, hy, ia, id, is, it, ka, kmr, kn, la_x_classic, la, lt, lv, ml, mn_cyrl_x_lmc, mn_cyrl, mr, mul_ethi, nb, nl, nn, or, pa, pl, pms, pt, rm, ro, ru, sa, sh_cyrl, sk, sl, sv, ta, te, th, tk, tr, uk, zh_latn_pinyin]
```

### Enum

As Islandic is been abbreviated "is", which is a Dart keyword, the prefix "language" had been added.

```dart 
enum Language { language_af,language_as,language_bg,language_bn,
language_ca,language_cop,language_cs,language_cy,language_da,
language_de_1901,language_de_1996,language_de_ch_1901,
language_el_monoton,language_el_polyton,language_en_gb
language_en_us,language_eo,language_es,language_et,
language_eu,language_fi,language_fr,language_fur,language_ga,
language_gl,language_grc,language_gu,language_hi,language_hr,
language_hsb,language_hu,language_hy,language_ia,language_id,
language_is,language_it,language_ka,language_kmr,language_kn,
language_la_x_classic,language_la,language_lt,language_lv,
language_ml,language_mn_cyrl_x_lmc,language_mn_cyrl,language_mr,
language_mul_ethi,language_nb,language_nl,language_nn,
language_or,language_pa,language_pl,language_pms,language_pt,
language_rm,language_ro,language_ru,language_sa,language_sh_cyrl,
language_sk,language_sl,language_sv,language_ta,language_te,
language_th,language_tk,language_tr,language_uk,
language_zh_latn_pinyin }
```

## Performance

Old machine:

* Instantiation via Dart EN_US file: 30 milliseconds
* Hyphenating text with 258 words: 46-56 milliseconds

Internal is-letter-testing impacts performance the most. At the moment, a binary search is performed over a combined set of (complete?) alphabets from various languages, plus an extra check for languages not included. Not terrible efficient, needs improvement.

## Generate JSON and Dart files

```shell
dart run ./tool/tex2dart.dart
```

The tool will delete `assets` and `lib/languages` before generating new files. It processes tex files located in `tool\tex\`.

## Source

This package is a copy and extension of [hyphenator](https://pub.dev/packages/hyphenator).


## Issues

Given this is a generic hyphenator, several issues are to be expected. Please open one at [Github](https://github.com/xErik/hyphenatorx/issues).
