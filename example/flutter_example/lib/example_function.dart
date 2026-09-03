import 'package:flutter/material.dart';
import 'package:hyphenatorx/hyphenatorx.dart';

class ExampleFunction extends StatefulWidget {
  const ExampleFunction({super.key});

  @override
  State<ExampleFunction> createState() => _ExampleFunctionState();
}

class _ExampleFunctionState extends State<ExampleFunction> {
  String text = 'Подразделение гидростанции количество творчество.';
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
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "Hyphenator.ru(symbol: '_').hyphenateText(text)",
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                backgroundColor: Color(0xFFFFF9C4),
              ),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter some text'),
            ),
            const SizedBox(height: 16),
            _column(hyphenator),
          ],
        ),
      ),
    );
  }

  Widget _column(Hyphenator hyphenator) {
    return text.isEmpty
        ? const SizedBox.shrink()
        : Column(
            children: [
              Text(
                hyphenator.hyphenateText(text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Cache Hyphenated:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                '${hyphenator.cachedHyphendWords}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Cache Non-Hyphenated:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                '${hyphenator.cachedNonHyphendWords}',
                textAlign: TextAlign.center,
              ),
            ],
          );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
