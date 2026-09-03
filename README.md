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
final hyphenator = Hyphenator.ru();
final text = const Text('подразделение');
final style = const TextStyle(fontSize: 16);

final wrap = hyphenator.wrap(text, style, 100);

// The hyphenated text with hyphens and newlines:
// 
// подразде-
// ление
print(wrap.textStr);

// Whether the returned text is equal to 
// or smaller than maxWidth. 
//
// If FALSE, try a different font size.

print(wrap.isSizeMatching);
```

### Manual Hyphenation 

Iterate through the token tree for a custom approach of hyphenation. Before and after each token a valid hyphen could be added. 

```dart
final text = 'Подразделение культуры и творчества.';

final hyphenator = Hyphenator.ru();
final List<TextPartToken> tokens = hyphenator.hyphenateTextToTokens(text);

for (final part in tokens) {
  if (part is NewlineToken) {
    print(part.text); // = is always a single newline
  } else if (part is TabsAndSpacesToken) {
    print(part.text); // tabs and spaces found in `text`
  } else if (part is WordToken) {
    for (final syllableAndSurrounding in part.parts) {
      print(syllableAndSurrounding.text); // под / раз / де / ле / ние.
    }
  }
}

// Под
// раз
// де
// ле
// ние
```

## Languages and Abbreviations

Russian (`ru`) is bundled. The abbreviation matches the source TeX filename at
[tug.org](https://tug.org/tex-hyphen/). Additional languages require generating
and registering their configurations.

## Performance

Pattern lookup uses a map, and previously hyphenated words are cached. Cache
size is bounded for long-running applications.

## Generate Dart language data

```shell
dart run tool/tex2data.dart ru
```

The generator reads `tool/tex/hyph-<abbr>.tex` and writes
`lib/languages/language_<abbr>.dart`. Register newly generated configurations
in `Hyphenator.byAbbr` before using them by abbreviation.

## Source

This package is a copy and extension of [hyphenator](https://pub.dev/packages/hyphenator).


## Issues

Given this is a generic hyphenator, several issues are to be expected. Please open one at [Github](https://github.com/xErik/hyphenatorx/issues).
