import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/im_model.dart';

/// 내과 API 레포지토리
///
/// - addVitals       : 활력 징후 추가
/// - getVitals       : 기간별 활력 징후 조회
/// - getVitalsTrend  : 트렌드 데이터 (차트용)
/// - getMedications  : 복약 목록 조회
/// - logMedication   : 복약 기록 (taken / skipped)
/// - getAdherence    : 순응도 집계
class ImRepository {
  ImRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static final _dateFmt = DateFormat('yyyy-MM-dd');

  static const String _base = '${ApiConstants.apiV1}/specialty/internal-medicine';

  // ──────────────────────────────────────────
  // 활력 징후 추가
  // ──────────────────────────────────────────

  Future<VitalsModel> addVitals({
    required VitalsType type,
    required double value1,
    double? value2,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/vitals',
      data: {
        'type': type.apiKey,
        'value1': value1,
        if (value2 != null) 'value2': value2,
        'measured_at': DateTime.now().toIso8601String(),
        if (note != null) 'note': note,
      },
    );
    return VitalsModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 기간별 활력 징후 조회
  // ──────────────────────────────────────────

  Future<List<VitalsModel>> getVitals({
    required VitalsType type,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/vitals',
      queryParameters: {
        'type': type.apiKey,
        'from': _dateFmt.format(from),
        'to': _dateFmt.format(to),
      },
    );
    return (response.data ?? [])
        .map((e) => VitalsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 트렌드 데이터 (최근 N일 일별 평균)
  // ──────────────────────────────────────────

  Future<List<VitalsTrendPoint>> getVitalsTrend({
    required VitalsType type,
    int days = 7,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/vitals/trend',
      queryParameters: {
        'type': type.apiKey,
        'days': days,
      },
    );
    return (response.data ?? [])
        .map((e) => VitalsTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 복약 목록 (활성 처방)
  // ──────────────────────────────────────────

  Future<List<MedicationModel>> getMedications({bool activeOnly = true}) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/medications',
      queryParameters: {'active_only': activeOnly},
    );
    return (response.data ?? [])
        .map((e) => MedicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 복약 기록 (오늘)
  // ──────────────────────────────────────────

  Future<List<MedLogModel>> getTodayLogs() async {
    final today = _dateFmt.format(DateTime.now());
    final response = await _dio.get<List<dynamic>>(
      '$_base/medication-logs',
      queryParameters: {'date': today},
    );
    return (response.data ?? [])
        .map((e) => MedLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 복약 상태 업데이트
  // ──────────────────────────────────────────

  Future<MedLogModel> logMedication({
    required String logId,
    required MedLogStatus status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/medication-logs/$logId',
      data: {
        'status': status.name,
        if (status == MedLogStatus.taken)
          'taken_at': DateTime.now().toIso8601String(),
      },
    );
    return MedLogModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 복약 순응도 집계
  // ──────────────────────────────────────────

  Future<AdherenceModel> getAdherence({int days = 30}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/adherence',
      queryParameters: {'days': days},
    );
    return AdherenceModel.fromJson(response.data!);
  }
}
