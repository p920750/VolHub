import 'package:flutter/material.dart';

class TextTruncator extends StatefulWidget {
  final String text;
  final int maxLines;
  final int charThreshold;
  final TextStyle? style;
  final String readMoreText;
  final TextStyle? readMoreStyle;
  final bool? isExpanded;
  final VoidCallback? onToggle;

  const TextTruncator({
    super.key,
    required this.text,
    required this.maxLines,
    required this.charThreshold,
    this.style,
    this.readMoreText = '....Read more',
    this.readMoreStyle,
    this.isExpanded,
    this.onToggle,
  });

  @override
  State<TextTruncator> createState() => _TextTruncatorState();
}

class _TextTruncatorState extends State<TextTruncator> {
  bool _internalIsExpanded = false;

  bool get _isExpanded => widget.isExpanded ?? _internalIsExpanded;

  void _handleToggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() {
        _internalIsExpanded = !_internalIsExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const Text('N/A');

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = widget.style ?? const TextStyle(fontSize: 14, color: Colors.black87);
        // Force height 1.5 for offset calculations if not provided
        final effectiveStyle = style.copyWith(height: style.height ?? 1.5);
        
        final span = TextSpan(text: widget.text, style: effectiveStyle);
        
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (!tp.didExceedMaxLines) {
          return Text(widget.text, style: effectiveStyle);
        }

        if (_isExpanded) {
          return RichText(
            text: TextSpan(
              style: effectiveStyle,
              children: [
                TextSpan(text: '${widget.text} '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: _handleToggle,
                    child: const Text(
                      'Read less',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Need to truncate exactly at the maxLines line, 7th word.
        // Get the position of the end of the previous line.
        final targetLinesBefore = widget.maxLines - 1;
        final posLine = tp.getPositionForOffset(Offset(0, effectiveStyle.fontSize! * effectiveStyle.height! * targetLinesBefore)).offset;
        
        String linesBefore = '';
        String lastLineRender = '';

        try {
          if (posLine > 0 && posLine < widget.text.length) {
            linesBefore = widget.text.substring(0, posLine);
            String rest = widget.text.substring(posLine).trimLeft();
            List<String> wordsLast = rest.split(RegExp(r'\s+'));
            if (wordsLast.length > 7) {
              lastLineRender = wordsLast.take(7).join(' ');
            } else {
              lastLineRender = rest;
            }
          } else {
             final words = widget.text.split(' ');
             int target = words.length > 40 ? 40 : words.length ~/ 2;
             linesBefore = words.take(target - 7).join(' ');
             lastLineRender = words.skip(target - 7).take(7).join(' ');
          }
        } catch (e) {
          linesBefore = widget.text.substring(0, widget.text.length > 100 ? 100 : widget.text.length);
          lastLineRender = '';
        }

        String truncatedText = linesBefore;
        if (truncatedText.isNotEmpty && !truncatedText.endsWith(' ') && !truncatedText.endsWith('\n')) {
            truncatedText += ' ';
        }
        truncatedText += '$lastLineRender....';

        return RichText(
          text: TextSpan(
            style: effectiveStyle,
            children: [
              TextSpan(text: truncatedText),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: _handleToggle,
                  child: const Text(
                    'Read more',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

