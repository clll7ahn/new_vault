import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/ortho_model.dart';

/// 정형외과 API 레포지토리
///
/// - addPainLog    : 통증 일지 추가
/// - getPainLogs   : 통증 기록 조회
/// - getPainTrend  : 통증 트렌드 (일별 평균)
/// - getPrograms   : 재활 프로그램 목록
/// - logExercise   : 운동 수행 기록
/// - getAdherence  : 재활 수행률
class OrthoRepository {
  OrthoRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static final _dateFmt = DateFormat('yyyy-MM-dd');

  static const String _base =
      '${ApiConstants.apiV1}/specialty/orthopedics';

  // ──────────────────────────────────────────
  // 통증 일지 추가
  // ──────────────────────────────────────────

  Future<PainLogModel> addPainLog({
    required BodyPart bodyPart,
    required int intensity,
    PainType? painType,
    String? notes,
    List<String>? triggers,
  }) async {
    final dto = PainLogModel(
      id: '',
      bodyPart: bodyPart,
      intensity: intensity,
      recordedAt: DateTime.now(),
      painType: painType,
      notes: notes,
      triggers: triggers,
    );
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/pain-logs',
      data: dto.toJson(),
    );
    return PainLogModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 통증 기록 목록
  // ──────────────────────────────────────────

  Future<List<PainLogModel>> getPainLogs({
    BodyPart? bodyPart,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/pain-logs',
      queryParameters: {
        if (bodyPart != null) 'body_part': bodyPart.name,
        'from': _dateFmt.format(from),
        'to': _dateFmt.format(to),
      },
    );
    return (response.data ?? [])
        .map((e) => PainLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 통증 트렌드 (일별 평균)
  // ──────────────────────────────────────────

  Future<List<PainTrendPoint>> getPainTrend({
    BodyPart? bodyPart,
    int days = 14,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/pain-logs/trend',
      queryParameters: {
        if (bodyPart != null) 'body_part': bodyPart.name,
        'days': days,
      },
    );
    return (response.data ?? [])
        .map((e) => PainTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 재활 프로그램 목록
  // ──────────────────────────────────────────

  Future<List<RehabProgramModel>> getPrograms({bool activeOnly = true}) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/rehab-programs',
      queryParameters: {'active_only': activeOnly},
    );
    return (response.data ?? [])
        .map((e) => RehabProgramModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 운동 수행 기록
  // ──────────────────────────────────────────

  Future<ExerciseLogModel> logExercise({
    required String programId,
    required String exerciseId,
    required String exerciseName,
    required int completedSets,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/exercise-logs',
      data: {
        'program_id': programId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'completed_sets': completedSets,
        'logged_at': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return ExerciseLogModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 재활 수행률
  // ──────────────────────────────────────────

  Future<RehabAdherence> getAdherence({
    required String programId,
    int days = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/rehab-programs/$programId/adherence',
      queryParameters: {'days': days},
    );
    return RehabAdherence.fromJson(response.data!);
  }
}
