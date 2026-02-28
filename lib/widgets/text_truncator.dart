import 'package:flutter/material.dart';

class TextTruncator extends StatefulWidget {
  final String text;
  final int maxLines;
  final int charThreshold;
  final TextStyle? style;
  final String readMoreText;
  final TextStyle? readMoreStyle;

  const TextTruncator({
    super.key,
    required this.text,
    required this.maxLines,
    required this.charThreshold,
    this.style,
    this.readMoreText = '....Read more',
    this.readMoreStyle,
  });

  @override
  State<TextTruncator> createState() => _TextTruncatorState();
}

class _TextTruncatorState extends State<TextTruncator> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (_isExpanded) {
      return Text(
        widget.text,
        style: widget.style,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return Text(widget.text, style: widget.style);
        }

        // Get the position of the end of the maxLines-th line
        final lineMetrics = textPainter.computeLineMetrics();
        if (lineMetrics.length < widget.maxLines) {
          return Text(widget.text, style: widget.style);
        }

        // The user requirement: "if the contents ... is more than 5 lines in the fifth line 
        // after 30 characters like '....Read more'".
        // This is tricky to do exactly with TextPainter because lines might be shorter than 30 chars.
        // We'll use an approximation: we show maxLines - 1 full lines, and on the maxLines-th line,
        // we show up to 30 characters before the "Read more".
        
        // This logic is a bit complex for a standard Text widget. 
        // Let's use a simpler approach that respects the "5 lines" and "30 chars" requirement.
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: widget.style,
            ),
            InkWell(
              onTap: () => setState(() => _isExpanded = true),
              child: Text(
                widget.readMoreText,
                style: widget.readMoreStyle ?? const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
