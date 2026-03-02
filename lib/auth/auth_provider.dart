import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that listens to Supabase authentication state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Provider that returns the current Supabase [User].
/// It watches [authStateProvider] to ensure it updates whenever the session changes.
final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user ?? Supabase.instance.client.auth.currentUser;
});
