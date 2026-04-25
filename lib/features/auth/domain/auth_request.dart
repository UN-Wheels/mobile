class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
  });

  // El backend espera 'username' (que es el email)
  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.gender,
    required this.major,
    required this.age,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final String phone;
  final String gender;
  final String major;
  final int age;
  final String role;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'gender': gender,
        'major': major,
        'age': age,
        'role': role,
      };
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.phone,
    this.gender,
    this.major,
    this.age,
  });

  final String? fullName;
  final String? phone;
  final String? gender;
  final String? major;
  final int? age;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (gender != null) map['gender'] = gender;
    if (major != null) map['major'] = major;
    if (age != null) map['age'] = age;
    return map;
  }
}
