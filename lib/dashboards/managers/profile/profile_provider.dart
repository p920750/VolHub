import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';

class UserProfile {
  final String name;
  final String role;
  final String bio;
  final String email;
  final String phone;
  final String location;
  final String profileImage;
  final String linkedinUrl;
  final String certName;
  final String certIssuedDate;
  final String? category;

  UserProfile({
    required this.name,
    required this.role,
    required this.bio,
    required this.email,
    required this.phone,
    required this.location,
    required this.profileImage,
    required this.linkedinUrl,
    required this.certName,
    required this.certIssuedDate,
    this.category,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['full_name'] ?? 'User',
      role: map['role'] ?? 'Event Manager', // Or map from 'role' column if consistent
      bio: map['bio'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone_number'] ?? '',
      location: map['location'] ?? '', // Assuming location is not in users table yet, allow empty
      profileImage: map['profile_photo'] ?? 'https://i.pravatar.cc/150?img=12', // Fallback
      linkedinUrl: map['linkedin_url'] ?? '', // Placeholder if column doesn't exist
      certName: map['cert_name'] ?? '', // Placeholder
      certIssuedDate: map['cert_issued_date'] ?? '', // Placeholder
      category: map['category'],
    );
  }

  UserProfile copyWith({
    String? name,
    String? role,
    String? bio,
    String? email,
    String? phone,
    String? location,
    String? profileImage,
    String? linkedinUrl,
    String? certName,
    String? certIssuedDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      certName: certName ?? this.certName,
      certIssuedDate: certIssuedDate ?? this.certIssuedDate,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return _fetchUserProfile();
  }

  Future<UserProfile> _fetchUserProfile() async {
    final userData = await SupabaseService.getUserFromUsersTable();
    if (userData != null) {
      return UserProfile.fromMap(userData);
    } else {
      // Fallback or throw error if user not found (shouldn't happen if logged in)
      // For now, returning a default empty profile to avoid crashes during dev
       return UserProfile(
        name: 'Guest',
        role: 'Guest',
        bio: '',
        email: '',
        phone: '',
        location: '',
        profileImage: '',
        linkedinUrl: '',
        certName: '',
        certIssuedDate: '',
      );
    }
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    // Optimistic update
    state = AsyncData(newProfile);
    
    // Push changes to Supabase
    try {
      await SupabaseService.updateUsersTableAlias({
        'full_name': newProfile.name,
        'bio': newProfile.bio,
        'phone_number': newProfile.phone,
        // Add other fields when they exist in DB
      });
    } catch (e) {
      // Revert on error? Or just show error
      // state = AsyncError(e, StackTrace.current);
      // For now, strict state management isn't the primary goal, just data flow
    }
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
