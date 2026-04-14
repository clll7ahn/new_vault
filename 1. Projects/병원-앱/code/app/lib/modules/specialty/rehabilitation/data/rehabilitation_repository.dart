import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/rehabilitation_model.dart';

class RehabilitationRepository {
  RehabilitationRepository({Dio? dio})
      : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/rehabilitation';

  Future<List<EvalScoreModel>> getEvalScores() async {
    final res = await _dio.get<List<dynamic>>('$_base/eval-scores');
    return (res.data ?? [])
        .map((e) => EvalScoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RehabExerciseModel>> getExerciseList() async {
    final res = await _dio.get<List<dynamic>>('$_base/exercises');
    return (res.data ?? [])
        .map((e) => RehabExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SessionPainLogModel>> getSessionPainLogs(
      {int limit = 14}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/session-pain-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) =>
            SessionPainLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SessionPainLogModel> addSessionPainLog(
      AddSessionPainLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
        '$_base/session-pain-logs', data: dto.toJson());
    return SessionPainLogModel.fromJson(res.data!);
  }
}
