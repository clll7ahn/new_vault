import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../domain/guardian_model.dart';
import '../domain/user_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// API 경로 상수
// ──────────────────────────────────────────────────────────────────────────────

class _GuardianApiPaths {
  _GuardianApiPaths._();

  static const String base = '/guardian';
  static const String link = '$base/link';
  static const String linkCode = '$base/link-code';
  static const String dependents = '$base/dependents';
  static const String guardians = '$base/guardians';
  static String unlinkPath(String linkId) => '$base/link/$linkId';
  static String switchAccount(String dependentId) =>
      '$base/switch/$dependentId';
}

// ──────────────────────────────────────────────────────────────────────────────
// GuardianRepository
// ──────────────────────────────────────────────────────────────────────────────

/// 보호자 연동 계정 관련 API 호출을 담당하는 레포지토리
///
/// 주요 기능:
/// - [generateLinkCode]: 연결 코드 생성 (내가 코드를 받아서 보호자에게 전달)
/// - [linkGuardian]: 연결 코드를 사용해 보호자 연결
/// - [getMyDependents]: 내가 보호하는 피보호자 목록 조회
/// - [getMyGuardians]: 나를 보호하는 보호자 목록 조회
/// - [unlinkGuardian]: 연결 해제
/// - [switchAccount]: 피보호자 계정으로 대리 관리 모드 전환
class GuardianRepository {
  GuardianRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  // ──────────────────────────────────────────
  // 연결 코드 생성
  // ──────────────────────────────────────────

  /// 내 계정에 대한 연결 코드를 생성합니다.
  ///
  /// 생성된 코드를 보호자에게 전달하면, 보호자가 [linkGuardian]으로
  /// 연결 요청을 완료합니다.
  Future<GuardianLinkCode> generateLinkCode() async {
    final response = await _dio.post<Map<String, dynamic>>(
      _GuardianApiPaths.linkCode,
    );
    return GuardianLinkCode.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 보호자 연결
  // ──────────────────────────────────────────

  /// 연결 코드와 관계를 사용해 보호자-피보호자 연결을 생성합니다.
  ///
  /// 이 메서드를 호출하는 사용자가 **보호자** 역할입니다.
  /// [code]: 피보호자가 발급한 연결 코드
  /// [relationship]: 관계 유형 (부모, 자녀, 배우자 등)
  Future<GuardianLink> linkGuardian({
    required String code,
    required GuardianRelationship relationship,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _GuardianApiPaths.link,
      data: {
        'code': code,
        'relationship': relationship.name,
      },
    );
    return GuardianLink.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 피보호자 목록 조회
  // ──────────────────────────────────────────

  /// 내가 보호하는 피보호자 목록을 반환합니다.
  ///
  /// 반환된 [GuardianLink] 목록에서 [GuardianLink.dependentUserId]가
  /// 피보호자의 userId입니다.
  Future<List<GuardianLink>> getMyDependents() async {
    final response = await _dio.get<List<dynamic>>(
      _GuardianApiPaths.dependents,
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(GuardianLink.fromJson)
        .toList();
  }

  // ──────────────────────────────────────────
  // 보호자 목록 조회
  // ──────────────────────────────────────────

  /// 나를 보호하는 보호자 목록을 반환합니다.
  ///
  /// 반환된 [GuardianLink] 목록에서 [GuardianLink.guardianUserId]가
  /// 보호자의 userId입니다.
  Future<List<GuardianLink>> getMyGuardians() async {
    final response = await _dio.get<List<dynamic>>(
      _GuardianApiPaths.guardians,
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(GuardianLink.fromJson)
        .toList();
  }

  // ──────────────────────────────────────────
  // 연결 해제
  // ──────────────────────────────────────────

  /// 보호자-피보호자 연결을 해제합니다.
  ///
  /// [linkId]: [GuardianLink.id]
  Future<void> unlinkGuardian(String linkId) async {
    await _dio.delete<void>(_GuardianApiPaths.unlinkPath(linkId));
  }

  // ──────────────────────────────────────────
  // 대리 관리 모드 전환
  // ──────────────────────────────────────────

  /// 피보호자 계정으로 대리 관리 모드를 전환합니다.
  ///
  /// 서버는 임시 위임 토큰을 발급하고, 클라이언트는 이 토큰으로
  /// 피보호자 대신 API를 호출할 수 있습니다.
  ///
  /// [dependentId]: 전환 대상 피보호자의 userId
  /// 반환값: 위임 대상 사용자 정보
  Future<UserModel> switchAccount(String dependentId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _GuardianApiPaths.switchAccount(dependentId),
    );
    // 서버가 { "user": {...}, "access_token": "..." } 형태로 응답
    final data = response.data!;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}
