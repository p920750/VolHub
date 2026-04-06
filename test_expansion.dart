void main() {
  String text = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20";
  
  String lines1To9 = '';
  String line10Render = '';
  try {
     final words = text.split(' ');
     int target = words.length > 40 ? 40 : words.length ~/ 2;
     lines1To9 = words.take(target - 7).join(' ');
     line10Render = words.skip(target - 7).take(7).join(' ');
  } catch (e) {
  }
  String truncatedText = lines1To9;
  if (truncatedText.isNotEmpty && !truncatedText.endsWith(' ') && !truncatedText.endsWith('\n')) {
      truncatedText += ' ';
  }
  truncatedText += '$line10Render....';
  print("ORIGINAL: $text");
  print("TRUNCATED: $truncatedText");
}
