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
  final String certName;
  final String certIssuedDate;
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
    required this.certName,
    required this.certIssuedDate,
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
      certName: map['cert_name'] ?? '',
      certIssuedDate: map['cert_issued_date'] ?? '',
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
    String? certName,
    String? certIssuedDate,
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
      certName: certName ?? this.certName,
      certIssuedDate: certIssuedDate ?? this.certIssuedDate,
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
        certName: '',
        certIssuedDate: '',
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
      });
    } catch (e) {
      // Revert or log error
    }
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
