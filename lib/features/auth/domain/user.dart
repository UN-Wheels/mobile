class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.gender,
    this.major,
    this.age,
    required this.role,
    this.profilePicture,
    this.totalTrips,
    this.avgRating,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? gender;
  final String? major;
  final int? age;
  final String role;
  final String? profilePicture;
  final int? totalTrips;
  final double? avgRating;

  // Maneja camelCase (gateway/web) y snake_case (Python backend directamente)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['user_id'])?.toString() ?? '',
      email: (json['email'] as String?) ?? '',
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'])
              as String? ??
          '',
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      major: json['major'] as String?,
      age: json['age'] as int?,
      role: (json['role'] as String?) ?? 'estudiante',
      profilePicture:
          (json['profilePicture'] ?? json['profile_picture']) as String?,
      totalTrips:
          (json['totalTrips'] ?? json['total_trips']) as int?,
      avgRating:
          ((json['avgRating'] ?? json['avg_rating']) as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'gender': gender,
        'major': major,
        'age': age,
        'role': role,
        'profilePicture': profilePicture,
        'totalTrips': totalTrips,
        'avgRating': avgRating,
      };

  User copyWith({
    String? fullName,
    String? phone,
    String? gender,
    String? major,
    int? age,
    String? role,
    String? profilePicture,
    int? totalTrips,
    double? avgRating,
  }) {
    return User(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      major: major ?? this.major,
      age: age ?? this.age,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      totalTrips: totalTrips ?? this.totalTrips,
      avgRating: avgRating ?? this.avgRating,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get isDriver => role == 'docente' || role == 'driver';
}
