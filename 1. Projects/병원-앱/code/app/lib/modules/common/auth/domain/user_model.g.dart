// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// JsonSerializable - UserModel
// ──────────────────────────────────────────────────────────────────────────────
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// 실제 프로젝트에서는 build_runner가 이 파일을 자동 생성합니다.

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'role': _$UserRoleEnumMap[instance.role]!,
      'phone': instance.phone,
      'profile_image_url': instance.profileImageUrl,
      'date_of_birth': instance.dateOfBirth,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.patient: 'patient',
  UserRole.doctor: 'doctor',
  UserRole.staff: 'staff',
  UserRole.admin: 'admin',
};

T _$enumDecode<T extends Enum>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value for the field is missing in the JSON.',
    );
  }

  return enumValues.entries
      .singleWhere(
        (e) => e.value == source,
        orElse: () {
          if (unknownValue == null) {
            throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}',
            );
          }
          return MapEntry(unknownValue, unknownValue);
        },
      )
      .key;
}
