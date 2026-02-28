import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';
import '../../auth/auth_provider.dart';

class AdminProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String profilePhoto;

  AdminProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.profilePhoto,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      name: map['full_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone_number'] ?? '',
      address: map['address'] ?? '',
      profilePhoto: map['profile_photo'] ?? '',
    );
  }
}

class AdminProfileNotifier extends AsyncNotifier<AdminProfile> {
  @override
  Future<AdminProfile> build() async {
    // Watch userProvider for reactivity
    ref.watch(userProvider);
    return _fetchProfile();
  }

  Future<AdminProfile> _fetchProfile() async {
    final userData = await SupabaseService.getUserProfile();
    return AdminProfile.fromMap(userData ?? {});
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await SupabaseService.upsertUserProfile({
      ...updates,
      'role': 'admin',
    });
    ref.invalidateSelf();
  }
}

final adminProfileProvider = AsyncNotifierProvider<AdminProfileNotifier, AdminProfile>(() {
  return AdminProfileNotifier();
});
