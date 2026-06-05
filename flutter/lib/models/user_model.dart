/// Typed Dart representation of the backend UserResponse schema.
/// Fields mirror `database/schemas.py → UserResponse`.
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final int esgPoints;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.esgPoints,
    required this.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'User',
      esgPoints: map['esg_points'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'esg_points': esgPoints,
        'is_active': isActive,
      };
}

/// Typed representation of the backend EnergyProfileResponse schema.
/// Fields mirror `database/schemas.py → EnergyProfileResponse`.
class EnergyProfileModel {
  final int id;
  final int ownerId;
  final String profileName;
  final double preferredTemp;
  final int autoStandbyTimeoutMins;

  const EnergyProfileModel({
    required this.id,
    required this.ownerId,
    required this.profileName,
    required this.preferredTemp,
    required this.autoStandbyTimeoutMins,
  });

  factory EnergyProfileModel.fromMap(Map<String, dynamic> map) {
    return EnergyProfileModel(
      id: map['id'] as int,
      ownerId: map['owner_id'] as int,
      profileName: map['profile_name'] as String? ?? 'Deep Work',
      preferredTemp: (map['preferred_temp'] as num?)?.toDouble() ?? 24.0,
      autoStandbyTimeoutMins: map['auto_standby_timeout_mins'] as int? ?? 5,
    );
  }
}
