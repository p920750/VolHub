import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';
import '../../auth/auth_provider.dart';

class HostProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String bio;
  final String profilePhoto;

  HostProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.bio,
    required this.profilePhoto,
  });

  factory HostProfile.fromMap(Map<String, dynamic> map) {
    return HostProfile(
      name: map['full_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone_number'] ?? '',
      address: map['address'] ?? '',
      bio: map['bio'] ?? '',
      profilePhoto: map['profile_photo'] ?? '',
    );
  }
}

class HostProfileNotifier extends AsyncNotifier<HostProfile> {
  @override
  Future<HostProfile> build() async {
    // Watch userProvider for reactivity
    ref.watch(userProvider);
    return _fetchProfile();
  }

  Future<HostProfile> _fetchProfile() async {
    final userData = await SupabaseService.getUserProfile();
    return HostProfile.fromMap(userData ?? {});
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await SupabaseService.updateUserProfile(updates);
    ref.invalidateSelf();
  }
}

final hostProfileProvider = AsyncNotifierProvider<HostProfileNotifier, HostProfile>(() {
  return HostProfileNotifier();
});
