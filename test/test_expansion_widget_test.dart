import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test TextPainter truncation', (WidgetTester tester) async {
    final String text = "For a professional baby photography event, the company requirements must prioritize safety, expertise, technical excellence, and a nurturing environment. Photographers must have proven experience in handling newborns, utilizing gentle posing techniques, and understanding baby cues. The studio should be fully equipped with sanitized props, soft, non-irritating fabrics, and advanced lighting setups that are safe for delicate eyes. Photographers must also be fully vaccinated and strictly adhere to hygiene protocols. Patience, an engaging personality, and the ability to capture candid, authentic moments are essential.";

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final style = const TextStyle(fontSize: 13, color: Colors.black87);
                  final span = TextSpan(text: text, style: style);
                  
                  final tp = TextPainter(
                    text: span,
                    textDirection: TextDirection.ltr,
                    maxLines: 10,
                  );
                  // artificially narrow constraint to force wrapping
                  tp.layout(maxWidth: 300);

                  final pos10 = tp.getPositionForOffset(Offset(0, style.fontSize! * 1.5 * 9)).offset;
                  
                  String lines1To9 = '';
                  String line10Render = '';

                  print("pos10: $pos10, length: ${text.length}");

                  if (pos10 > 0 && pos10 < text.length) {
                    lines1To9 = text.substring(0, pos10);
                    String rest = text.substring(pos10).trimLeft();
                    List<String> words10 = rest.split(RegExp(r'\s+'));
                    if (words10.length > 7) {
                      line10Render = words10.take(7).join(' ');
                    } else {
                      line10Render = rest;
                    }
                  } else {
                    final words = text.split(' ');
                    int target = words.length > 40 ? 40 : words.length ~/ 2;
                    lines1To9 = words.take(target - 7).join(' ');
                    line10Render = words.skip(target - 7).take(7).join(' ');
                  }

                  String truncatedText = lines1To9;
                  if (truncatedText.isNotEmpty && !truncatedText.endsWith(' ') && !truncatedText.endsWith('\n')) {
                      truncatedText += ' ';
                  }
                  truncatedText += '$line10Render....';

                  print("RESULTING TEXT:\n$truncatedText");
                  return Text(truncatedText);
                },
              );
            },
          ),
        ),
      ),
    );
  });
}
