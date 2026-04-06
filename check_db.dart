import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient('https://qvnqlfgifuerdqebbvol.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2bnFsZmdpZnVlcmRxZWJidm9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNTU3MjIsImV4cCI6MjA4MDgzMTcyMn0.f5W_Gc6LsPvv1v5xFJHdhZROurMjuvx6Umgl37bkxvE');
  
  try {
    final response = await client.from('events').select().order('created_at', ascending: false).limit(3);
    String out = '';
    for (var i = 0; i < response.length; i++) {
      out += '=== EVENT $i ===\n';
      out += 'TITLE: ${response[i]['name']}\n';
      out += 'DESC : ${response[i]['description']}\n';
      out += '------\n';
      out += 'REQS : ${response[i]['requirements']}\n';
      out += '-----------------\n\n';
    }
    File('clean_db_output.txt').writeAsStringSync(out);
    print("DONE");
    exit(0);
  } catch (e) {
    print("Error: $e");
    exit(1);
  }
}
