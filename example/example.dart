import 'package:flutter/material.dart';
import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:hyphenatorx/widget/texthyphenated.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HyphenatorExampleWidget(),
    );
  }
}

class HyphenatorExampleWidget extends StatefulWidget {
  const HyphenatorExampleWidget({super.key});

  @override
  State<HyphenatorExampleWidget> createState() =>
      _HyphenatorExampleWidgetState();
}

class _HyphenatorExampleWidgetState extends State<HyphenatorExampleWidget> {
  String text = 'подразделение';
  final controller = TextEditingController();
  final hyphenator = Hyphenator.ru(symbol: '_');

  @override
  void initState() {
    super.initState();
    controller.text = text;
    controller.addListener(() {
      setState(() {
        text = controller.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 2 / 3,
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration:
                      const InputDecoration(hintText: 'Enter some text'),
                ),
                const SizedBox(height: 16),
                text.isEmpty
                    ? const Text('Enter some text')
                    : Text(hyphenator.hyphenateText(text),
                        style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 32),
                if (text.isNotEmpty)
                  Text(
                    'Cached hyphenated:\n\n${hyphenator.cachedHyphendWords}',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                if (text.isNotEmpty)
                  Text(
                    'Cached non-hyphenated:\n\n${hyphenator.cachedNonHyphendWords}',
                    textAlign: TextAlign.center,
                  ),
                const Divider(),
                const Text('Widget test:'),
                const SizedBox(height: 16),
                const TextHyphenated('подразделение', symbol: '@'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
