import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

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

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return UserProfile(
      name: 'Alex Thompson',
      role: 'Event Organizer',
      bio: 'Experienced event manager with over 5 years of experience in corporate and community events.',
      email: 'alex.thompson@example.com',
      phone: '+1 (555) 123-4567',
      location: 'New York, USA',
      profileImage: 'https://i.pravatar.cc/150?img=12',
      linkedinUrl: 'https://linkedin.com/in/alex-thompson',
      certName: 'Certified Event Planner',
      certIssuedDate: 'Issued 2023',
    );
  }

  void updateProfile(UserProfile newProfile) {
    state = newProfile;
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
