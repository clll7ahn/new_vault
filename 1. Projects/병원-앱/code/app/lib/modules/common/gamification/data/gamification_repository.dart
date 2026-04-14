import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/gamification_model.dart';

/// 게이미피케이션 API 레포지토리
///
/// - getMissions       : 전체 미션 목록
/// - getMyMissions     : 내 참여 미션 (진행/완료 포함)
/// - checkIn           : 출석 체크 → 적립 포인트 반환
/// - getPoints         : 포인트 잔액
/// - getPointHistory   : 포인트 변동 이력
/// - getBadges         : 전체 배지 목록
/// - getMyBadges       : 내가 획득한 배지
class GamificationRepository {
  GamificationRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/gamification';

  // ──────────────────────────────────────────
  // 미션
  // ──────────────────────────────────────────

  Future<List<MissionModel>> getMissions({MissionType? type}) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/missions',
      queryParameters: {
        if (type != null) 'type': type.name,
      },
    );
    return (response.data ?? [])
        .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MissionModel>> getMyMissions() async {
    final response =
        await _dio.get<List<dynamic>>('$_base/missions/me');
    return (response.data ?? [])
        .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 출석 체크
  // ──────────────────────────────────────────

  /// 성공 시 적립된 포인트 반환 (이미 체크인된 경우 0)
  Future<int> checkIn() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/check-in',
    );
    return response.data?['points_earned'] as int? ?? 0;
  }

  // ──────────────────────────────────────────
  // 포인트
  // ──────────────────────────────────────────

  Future<int> getPoints() async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_base/points');
    return response.data?['balance'] as int? ?? 0;
  }

  Future<List<PointHistoryModel>> getPointHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/points/history',
      queryParameters: {'page': page, 'limit': limit},
    );
    return (response.data ?? [])
        .map((e) => PointHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 배지
  // ──────────────────────────────────────────

  Future<List<BadgeModel>> getBadges() async {
    final response =
        await _dio.get<List<dynamic>>('$_base/badges');
    return (response.data ?? [])
        .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BadgeModel>> getMyBadges() async {
    final response =
        await _dio.get<List<dynamic>>('$_base/badges/me');
    return (response.data ?? [])
        .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
