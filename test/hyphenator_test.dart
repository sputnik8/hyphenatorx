import 'dart:math' as Math show min, max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:hyphenatorx/widget/texthyphenated.dart';

final text =
    '''Подразделение гидростанции количество творчество направление обстоятельство электростанция гидрогеология. Обширное подразделение культуры, состоящее из творческих устремлений и дисциплин. Это более широкое понятие, чем искусство, которое обычно означает только изобразительное искусство. Искусство охватывает изобразительное искусство, литературу и исполнительское искусство. Этот список никоим образом не является исчерпывающим, а лишь служит для введения в концепцию искусства.''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final LanguageConfig config = LanguageRu();
  late TextStyle sRoboto;

  setUpAll(() async {
    final Future<ByteData> data = rootBundle.load('test/Roboto-Regular.ttf');
    final FontLoader fontLoader = FontLoader('roboto')..addFont(data);
    await fontLoader.load();

    sRoboto = TextStyle(
      fontFamily: 'roboto',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      textBaseline: TextBaseline.alphabetic,
      decoration: TextDecoration.none,
      height: 1.17,
    );
  });

  Size rounded(Size size) =>
      Size(size.width.roundToDouble(), size.height.roundToDouble());

  // -------------------------------------------------------------------
  // Instantiation
  // -------------------------------------------------------------------

  test('byAbbr', () {
    final hyphenator = Hyphenator.byAbbr('ru', symbol: '_');
    expect(hyphenator.hyphenateText('подразделение'), 'под_раз_де_ле_ние');
  });

  test('byAbbr-unknown-throws', () {
    expect(() => Hyphenator.byAbbr('xx_yy'), throwsArgumentError);
  });

  test('factory-ru', () {
    final hyphenator = Hyphenator.ru(symbol: '_');
    expect(hyphenator.hyphenateText('подразделение'), 'под_раз_де_ле_ние');
  });

  test('invalid-minWordLength-throws', () {
    expect(() => Hyphenator(config, minWordLength: 0), throwsArgumentError);
  });

  test('invalid-minLetterCount-throws', () {
    expect(() => Hyphenator(config, minLetterCount: -1), throwsArgumentError);
  });

  // -------------------------------------------------------------------
  // hyphenateText()
  // -------------------------------------------------------------------

  test('hyphenate-text', () {
    final hyphenator = Hyphenator(config, symbol: '_');
    expect(hyphenator.hyphenateText('подразделение'), 'под_раз_де_ле_ние');
    expect(hyphenator.hyphenateText('творчество'), 'твор_че_ство');
    expect(hyphenator.hyphenateText('гидростанция'), 'гид_ро_стан_ция');
  });

  test('hyphenate-text-punctuation', () {
    final hyphenator = Hyphenator(config, symbol: '_');
    expect(hyphenator.hyphenateText('Подразделение, творчество: количество!'),
        'Под_раз_де_ле_ние, твор_че_ство: коли_че_ство!');
  });

  test('hyphenate-text-boundaries', () {
    final hyphenator = Hyphenator(config, symbol: '_');
    expect(
        hyphenator.hyphenateText('Подразделение, творчество: количество!',
            hyphenAtBoundaries: true),
        'Под_раз_де_ле_ние,_ _твор_че_ство:_ _коли_че_ство!');
  });

  test('hyphenate-text-empty', () {
    final hyphenator = Hyphenator(config, symbol: '-');
    expect(hyphenator.hyphenateText(''), '');
  });

  // -------------------------------------------------------------------
  // hyphenateWord()
  // -------------------------------------------------------------------

  test('hyphenate-word', () {
    final hyphenator = Hyphenator(config, symbol: '_');

    expect(hyphenator.hyphenateWord('подразделение'), 'под_раз_де_ле_ние');
    expect(hyphenator.hyphenateWord('электростанция'), 'элек_тро_стан_ция');
    expect(hyphenator.hyphenateWord('направление'), 'направ_ле_ние');
  });

  test('hyphenate-word-uppercase', () {
    final hyphenator = Hyphenator(config, symbol: '_');
    expect(hyphenator.hyphenateWord('ПОДРАЗДЕЛЕНИЕ'), 'ПОД_РАЗ_ДЕ_ЛЕ_НИЕ');
  });

  test('soft-hyphen', () {
    final hyphend = Hyphenator(config).hyphenateWord('подразделение');
    expect(hyphend.contains('\u{00AD}'), true);
  });

  // -------------------------------------------------------------------
  // syllablesWord()
  // -------------------------------------------------------------------

  test('hyphenate-word-to-syllables', () {
    final hyphenator = Hyphenator(config, symbol: '_');

    expect(hyphenator.syllablesWord('подразделение'),
        <String>['под', 'раз', 'де', 'ле', 'ние']);
    expect(
        hyphenator.syllablesWord('творчество'), <String>['твор', 'че', 'ство']);
    expect(hyphenator.syllablesWord('гидростанция'),
        <String>['гид', 'ро', 'стан', 'ция']);
  });

  test('hyphenate-word-to-syllables-punctuation', () {
    final hyphenator = Hyphenator(config, symbol: '_');

    expect(hyphenator.syllablesWord('"подразделение"'),
        <String>['"под', 'раз', 'де', 'ле', 'ние"']);
    expect(hyphenator.syllablesWord('творчество...'),
        <String>['твор', 'че', 'ство...']);
    expect(hyphenator.syllablesWord('гидростанция,'),
        <String>['гид', 'ро', 'стан', 'ция,']);
  });

  // -------------------------------------------------------------------
  // exceptions - full roundtrip over all bundled exceptions
  // -------------------------------------------------------------------

  test('exceptions-roundtrip', () {
    final hyphenator = Hyphenator(config, symbol: '_');
    expect(config.exceptions, isNotEmpty);

    for (final source in config.exceptions) {
      final key = StringBuffer();
      final breaks = <int>[];

      var breakBeforeNext = false;
      for (final rune in source.runes) {
        if (rune == 0x2D) {
          breakBeforeNext = true;
        } else {
          key.writeCharCode(rune);
          if (breakBeforeNext) breaks.add(key.length - 1);
          breakBeforeNext = false;
        }
      }

      final expected = StringBuffer();
      final keyStr = key.toString();
      for (int i = 0; i < keyStr.length; i++) {
        if (breaks.contains(i)) expected.write('_');
        expected.write(keyStr[i]);
      }

      expect(hyphenator.hyphenateWord(keyStr), expected.toString(),
          reason: 'exception "$source"');
    }
  });

  test('exception-known-case', () {
    final hyphenator = Hyphenator(config, symbol: '_');
    expect(hyphenator.hyphenateWord('бизнесмен'), 'биз_нес_мен');
    expect(hyphenator.hyphenateWord('сегодня'), 'се_го_дня');
  });

  // -------------------------------------------------------------------
  // hyphenateTextToTokens()
  // -------------------------------------------------------------------

  test('hyphenate-text-to-tokens', () {
    final text = """Обширное подразделение культуры,
        творчество и дисциплины.""";

    final hyphenator = Hyphenator(config);
    final result = hyphenator.hyphenateTextToTokens(text);

    expect(
        result.toString(),
        "[[Обшир, ное], WS, [под, раз, де, ле, ние], WS, [культуры,], NL, "
        "WS, [твор, че, ство], WS, [и], WS, [дис, ци, п, лины.]]");
  });

  // -------------------------------------------------------------------
  // wrap()
  // -------------------------------------------------------------------

  test('wrap-word-too-big', () {
    final str = 'здравствуйте';
    final styleBig = sRoboto.merge(TextStyle(fontSize: 500));
    final hyphenator = Hyphenator(config);
    final wrap = hyphenator.wrap(Text(str), styleBig, 350.0);
    expect(wrap.textStr, str);

    expect(rounded(wrap.size), Size(3189, 585));
    expect(wrap.isSizeMatching, false);
  });

  test('wrap-one-word', () {
    final str = 'здравствуйте';
    final hyphenator = Hyphenator(config);
    final wrap = hyphenator.wrap(Text(str), sRoboto, 360.0);
    expect(wrap.textStr, str);
    expect(rounded(wrap.size), Size(89, 16));
    expect(wrap.isSizeMatching, true);
  });

  test('wrap-two-words', () {
    final str = 'здравствуйте здравствуйте';
    final hyphenator = Hyphenator(config);
    final wrap = hyphenator.wrap(Text(str), sRoboto, 360.0);
    expect(wrap.textStr, str);
    expect(rounded(wrap.size), Size(182, 16));
    expect(wrap.isSizeMatching, true);
  });

  test('wrap-multiple-words-100-width', () {
    final style =
        TextStyle(fontWeight: FontWeight.normal, fontSize: 14).merge(sRoboto);
    final text = Text(
        'Подразделение гидростанции количество творчество направление обстоятельство.');
    final expected = '''Подразделе-
ние гидростан-
ции количе-
ство творче-
ство направ-
ление обстоя-
тельство.''';

    final hyphenator = Hyphenator(config);

    WrapResult res = hyphenator.wrap(text, style, 100.0);
    expect(res.isSizeMatching, true);
    expect(res.textStr, expected);
  });

  test('wrap-multiple-words-160-width', () {
    final style =
        TextStyle(fontWeight: FontWeight.normal, fontSize: 14).merge(sRoboto);
    final text = Text(
        'Подразделение гидростанции количество творчество направление обстоятельство.');
    final expected = '''Подразделение гидро-
станции количество
творчество направле-
ние обстоятельство.''';

    final hyphenator = Hyphenator(config);

    WrapResult res = hyphenator.wrap(text, style, 160.0);
    expect(res.isSizeMatching, true);
    expect(res.textStr, expected);
  });

  test('wrap-word-empty', () {
    final text = Text("");
    final hyphenator = Hyphenator(config);
    WrapResult res = hyphenator.wrap(text, sRoboto, 380.0);
    expect(res.isSizeMatching, false);
    expect(res.textStr, "");
  });

  // -------------------------------------------------------------------
  // no-wrap()
  // -------------------------------------------------------------------

  test('no-wrap-multiple-words-540-width', () {
    final style =
        TextStyle(fontWeight: FontWeight.normal, fontSize: 14).merge(sRoboto);
    final text = Text(
        """A vast subdivision of culture, composed of many creative endeavors and disciplines.""",
        maxLines: 1);
    final expected =
        """A vast subdivision of culture, composed of many creative endeavors and disciplines.""";

    WrapResult res = Hyphenator.wrapNoHyphen(text, style, 540.0);
    expect(res.isSizeMatching, true);
    expect(res.textStr, expected);
    expect(rounded(res.size), Size(522, 16));
  });

  test('no-wrap-multiple-words-270-width', () {
    final style =
        TextStyle(fontWeight: FontWeight.normal, fontSize: 14).merge(sRoboto);
    final text = Text(
        """A vast subdivision of culture, composed of many creative endeavors and disciplines.""",
        maxLines: 2);
    final expected = """A vast subdivision of culture, composed of
many creative endeavors and disciplines.""";

    WrapResult res = Hyphenator.wrapNoHyphen(text, style, 270.0);
    expect(res.isSizeMatching, true);
    expect(res.textStr, expected);
    expect(rounded(res.size), Size(264, 32));
  });

  // -------------------------------------------------------------------
  // min letter count and min word length
  // -------------------------------------------------------------------

  test('hyphenate-test-minletter-4', () {
    final hyphenator = Hyphenator(config, symbol: '_', minLetterCount: 4);
    expect(hyphenator.hyphenateText('гидростанция'), 'гидро_станция');
  });

  test('hyphenate-test-minletter-50', () {
    final hyphenator = Hyphenator(config, symbol: '_', minLetterCount: 50);
    expect(hyphenator.hyphenateText('гидростанция'), 'гидростанция');
  });

  test('hyphenate-text-min-wordlength-50', () {
    final hyphenator = Hyphenator(config, symbol: '_', minWordLength: 50);
    expect(hyphenator.hyphenateText('гидростанция'), 'гидростанция');
  });

  // -------------------------------------------------------------------
  // widget
  // -------------------------------------------------------------------

  testWidgets('widget-renders-hyphenated-sync', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          child: TextHyphenated('подразделение подразделение'),
        ),
      ),
    ));

    // No FutureBuilder: wrapped text is rendered on the very first frame.
    final textFinder = find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('\n') ?? false));
    expect(textFinder, findsOneWidget);
  });

  // -------------------------------------------------------------------
  // stopwatch
  // -------------------------------------------------------------------

  test('stopwatch', () {
    final stopwatchesInit = <int>[];
    final stopwatchesPerform = <int>[];

    final stopwatchInit = Stopwatch()..start();
    final hyphenator = Hyphenator(config, symbol: '-');
    stopwatchInit.stop();
    stopwatchesInit.add(stopwatchInit.elapsedMilliseconds);

    for (int i = 0; i < 1; i++) {
      final stopwatchPerform = Stopwatch()..start();
      final result = hyphenator.hyphenateText(text);
      stopwatchPerform.stop();
      stopwatchesPerform.add(stopwatchPerform.elapsedMilliseconds);

      expect(result, isNotEmpty);
      expect(result.contains('-'), true);
    }

    final avgInit =
        stopwatchesInit.reduce((a, b) => a + b) / stopwatchesInit.length;
    final minInit = stopwatchesInit.reduce(Math.min);
    final maxInit = stopwatchesInit.reduce(Math.max);
    print('''
Stopwatch Init:
   #: ${stopwatchesInit.length}
 min: $minInit millis
 max: $maxInit millis
 avr: ${avgInit.toStringAsFixed(2)} millis = ${(avgInit * 1000).truncate()} micros
''');

    final avgPerform =
        stopwatchesPerform.reduce((a, b) => a + b) / stopwatchesPerform.length;
    final minPerform = stopwatchesPerform.reduce(Math.min);
    final maxPerform = stopwatchesPerform.reduce(Math.max);
    print('''
Stopwatch perform:
   #: ${stopwatchesPerform.length}
 min: $minPerform millis
 max: $maxPerform millis
 avr: ${avgPerform.toStringAsFixed(2)} millis = ${(avgPerform * 1000).truncate()} micros
''');
  });
}
