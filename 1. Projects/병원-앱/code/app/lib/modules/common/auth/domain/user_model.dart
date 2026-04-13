import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// 사용자 역할
enum UserRole {
  @JsonValue('patient')
  patient,

  @JsonValue('doctor')
  doctor,

  @JsonValue('staff')
  staff,

  @JsonValue('admin')
  admin,
}

/// 사용자 도메인 모델
///
/// json_serializable을 통해 JSON 직렬화/역직렬화를 지원합니다.
/// build_runner 실행 후 user_model.g.dart 파일이 자동 생성됩니다.
@JsonSerializable()
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.dateOfBirth,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;

  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? profileImageUrl,
    String? dateOfBirth,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, name: $name, role: $role)';
}
