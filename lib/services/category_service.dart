import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class CategoryService {
  static final List<String> defaultCategories = [
    'Wedding',
    'Cathering',
    'Mehndi',
    'Festival',
    'Dj Party',
    'Birthday Party',
    'Celebration',
    'Emergency Supplies',
    'Other',
  ];

  static Future<List<String>> getCategories() async {
    try {
      final Set<String> allCategories = Set.from(defaultCategories);
      
      // Fetch from manager_requests (organizers)
      final requestsResponse = await SupabaseService.client
          .from('manager_requests')
          .select('category');
      
      for (var row in requestsResponse) {
        if (row['category'] != null && row['category'].toString().trim().isNotEmpty) {
          var cat = row['category'].toString().trim();
          // Normalize capitalization if needed, or just let it as is
          allCategories.add(cat);
        }
      }

      // Fetch from events (managers) -> 'categories' is text array
      final eventsResponse = await SupabaseService.client
          .from('events')
          .select('categories');
          
      for (var row in eventsResponse) {
        if (row['categories'] != null) {
          final List<dynamic> cats = row['categories'];
          for (var cat in cats) {
            if (cat.toString().trim().isNotEmpty) {
              allCategories.add(cat.toString().trim());
            }
          }
        }
      }
      
      // Ensure 'Other' is always at the end
      final list = allCategories.toList();
      list.remove('Other');
      // Sort alphabetically for consistency, optional
      // list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      list.add('Other');
      
      return list;
    } catch (e) {
      // Fallback
      return defaultCategories;
    }
  }
}
