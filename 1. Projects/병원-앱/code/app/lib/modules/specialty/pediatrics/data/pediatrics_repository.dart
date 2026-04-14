import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/pediatrics_model.dart';

/// 소아과 API 레포지토리
class PediatricsRepository {
  PediatricsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/pediatrics';

  // ── 자녀 관리 ──────────────────────────────────────────────────────────────

  Future<ChildModel> addChild(AddChildDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/children',
      data: dto.toJson(),
    );
    return ChildModel.fromJson(res.data!);
  }

  Future<List<ChildModel>> getChildren() async {
    final res = await _dio.get<List<dynamic>>('$_base/children');
    return (res.data ?? [])
        .map((e) => ChildModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 성장 기록 ──────────────────────────────────────────────────────────────

  Future<GrowthLogModel> addGrowthLog(AddGrowthLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/growth-logs',
      data: dto.toJson(),
    );
    return GrowthLogModel.fromJson(res.data!);
  }

  Future<List<GrowthLogModel>> getGrowthLogs(String childId) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/growth-logs',
      queryParameters: {'child_id': childId},
    );
    return (res.data ?? [])
        .map((e) => GrowthLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 예방접종 ──────────────────────────────────────────────────────────────

  Future<List<VaccinationModel>> getVaccinations(String childId) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/vaccinations',
      queryParameters: {'child_id': childId},
    );
    return (res.data ?? [])
        .map((e) => VaccinationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VaccinationModel> updateVaccination({
    required String vaccinationId,
    required VaccinationStatus status,
    DateTime? administeredDate,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '$_base/vaccinations/$vaccinationId',
      data: {
        'status': status.name,
        if (administeredDate != null)
          'administered_date':
              administeredDate.toIso8601String().substring(0, 10),
      },
    );
    return VaccinationModel.fromJson(res.data!);
  }
}
