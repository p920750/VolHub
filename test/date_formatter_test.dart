import 'package:flutter_test/flutter_test.dart';
import 'package:main_volhub/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatChatDate returns "Today" for current date', () {
      final now = DateTime.now();
      expect(DateFormatter.formatChatDate(now), 'Today');
    });

    test('formatChatDate returns formatted date for previous date', () {
      final prevDate = DateTime.now().subtract(const Duration(days: 1));
      final expected = "${prevDate.day.toString().padLeft(2, '0')}/${prevDate.month.toString().padLeft(2, '0')}/${prevDate.year}";
      expect(DateFormatter.formatChatDate(prevDate), expected);
    });

    test('isSameDay returns true for same day', () {
      final date1 = DateTime(2023, 10, 3, 10, 30);
      final date2 = DateTime(2023, 10, 3, 15, 45);
      expect(DateFormatter.isSameDay(date1, date2), true);
    });

    test('isSameDay returns false for different days', () {
      final date1 = DateTime(2023, 10, 3);
      final date2 = DateTime(2023, 10, 4);
      expect(DateFormatter.isSameDay(date1, date2), false);
    });
  });
}
