import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/health_model.dart';

/// 건강 기록 API 레포지토리
///
/// - addRecord       : 건강 수치 추가
/// - getRecords      : 타입 + 기간별 기록 조회
/// - getDailySummary : 특정 날짜 일일 집계
/// - getWeeklySummary: 이번 주 전체 집계
/// - getSnapshot     : 전체 타입 최신 스냅샷
class HealthRepository {
  HealthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  // ──────────────────────────────────────────
  // 건강 기록 추가
  // ──────────────────────────────────────────

  Future<HealthRecordModel> addRecord(AddHealthRecordDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.healthRecords,
      data: dto.toJson(),
    );
    return HealthRecordModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 기간별 기록 조회
  // ──────────────────────────────────────────

  Future<List<HealthRecordModel>> getRecords({
    required HealthRecordType type,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.healthRecords,
      queryParameters: {
        'type': type.apiKey,
        'from': _dateFmt.format(from),
        'to': _dateFmt.format(to),
      },
    );
    return (response.data ?? [])
        .map((e) => HealthRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 일일 집계
  // ──────────────────────────────────────────

  Future<List<HealthSummary>> getDailySummary(DateTime date) async {
    final response = await _dio.get<List<dynamic>>(
      '${ApiConstants.healthRecords}/daily-summary',
      queryParameters: {'date': _dateFmt.format(date)},
    );
    return (response.data ?? [])
        .map((e) => HealthSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 주간 집계
  // ──────────────────────────────────────────

  Future<List<HealthSummary>> getWeeklySummary() async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: now.weekday - 1)); // 이번 주 월요일
    final response = await _dio.get<List<dynamic>>(
      '${ApiConstants.healthRecords}/weekly-summary',
      queryParameters: {
        'from': _dateFmt.format(from),
        'to': _dateFmt.format(now),
      },
    );
    return (response.data ?? [])
        .map((e) => HealthSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 전체 스냅샷
  // ──────────────────────────────────────────

  Future<HealthSnapshot> getSnapshot() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.healthRecords}/snapshot',
    );
    return HealthSnapshot.fromJson(response.data!);
  }
}
