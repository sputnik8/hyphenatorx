import 'package:flutter/material.dart';
import 'package:hyphenatorx/widget/texthyphenated.dart';

class ExampleWidget extends StatefulWidget {
  const ExampleWidget({super.key});

  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  String text = 'Подразделение гидростанции количество творчество.';
  final controller = TextEditingController();

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
            'TextHyphenated(text, doShowDebug: true, style: TextStyle(fontSize: 56))',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0xFFFFF9C4),
            ),
          ),
          // const Divider(),
          TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter some text')),
          const SizedBox(height: 16),
          TextHyphenated(text,
              doShowDebug: true, style: const TextStyle(fontSize: 56)),
        ],
      ),
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
