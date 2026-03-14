import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../../../auth/auth_provider.dart';

class UserProfile {
  final String name;
  final String role;
  final String bio;
  final String email;
  final String phone;
  final String companyName;
  final String companyLocation;
  final String profileImage;
  final String linkedinUrl;
  final List<String> certificates;
  final List<String> categories;

  UserProfile({
    required this.name,
    required this.role,
    required this.bio,
    required this.email,
    required this.phone,
    required this.companyName,
    required this.companyLocation,
    required this.profileImage,
    required this.linkedinUrl,
    required this.certificates,
    required this.categories,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['full_name'] ?? '',
      role: map['role'] ?? '',
      bio: map['bio'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone_number'] ?? '',
      companyName: map['company_name'] ?? '',
      companyLocation: map['company_location'] ?? '',
      profileImage: map['profile_photo'] ?? '',
      linkedinUrl: map['linkedin_url'] ?? '',
      certificates: (map['certificates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categories: (map['company_category'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  UserProfile copyWith({
    String? name,
    String? role,
    String? bio,
    String? email,
    String? phone,
    String? companyName,
    String? companyLocation,
    String? profileImage,
    String? linkedinUrl,
    List<String>? certificates,
    List<String>? categories,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      companyLocation: companyLocation ?? this.companyLocation,
      profileImage: profileImage ?? this.profileImage,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      certificates: certificates ?? this.certificates,
      categories: categories ?? this.categories,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    // Watch userProvider to ensure build() re-runs on auth change
    ref.watch(userProvider);
    return _fetchUserProfile();
  }

  Future<UserProfile> _fetchUserProfile() async {
    final userData = await SupabaseService.getUserFromUsersTable();
    if (userData != null) {
      return UserProfile.fromMap(userData);
    } else {
       return UserProfile(
        name: '',
        role: '',
        bio: '',
        email: '',
        phone: '',
        companyName: '',
        companyLocation: '',
        profileImage: '',
        linkedinUrl: '',
        certificates: [],
        categories: [],
      );
    }
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    state = AsyncData(newProfile);
    
    try {
      await SupabaseService.updateUsersTableAlias({
        'full_name': newProfile.name,
        'bio': newProfile.bio,
        'phone_number': newProfile.phone,
        'company_name': newProfile.companyName,
        'company_location': newProfile.companyLocation,
        'company_category': newProfile.categories,
        'profile_photo': newProfile.profileImage,
        'linkedin_url': newProfile.linkedinUrl,
        'certificates': newProfile.certificates,
      });
    } catch (e) {
      if (kDebugMode) print('Error updating profile: $e');
      // Revert state if needed
      ref.invalidateSelf();
    }
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
