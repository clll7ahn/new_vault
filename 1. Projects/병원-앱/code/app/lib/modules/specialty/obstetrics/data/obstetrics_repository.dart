import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/obstetrics_model.dart';

/// 산부인과 API 레포지토리
class ObstetricsRepository {
  ObstetricsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/obstetrics';

  // ── 임신 정보 ──────────────────────────────────────────────────────────────

  Future<PregnancyModel?> getPregnancy() async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('$_base/pregnancy');
      return res.data != null ? PregnancyModel.fromJson(res.data!) : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── 산전 검진 ──────────────────────────────────────────────────────────────

  Future<List<CheckupModel>> getCheckups() async {
    final res = await _dio.get<List<dynamic>>('$_base/checkups');
    return (res.data ?? [])
        .map((e) => CheckupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 태동 기록 ──────────────────────────────────────────────────────────────

  Future<FetalMovementModel> addFetalMovement(
      AddFetalMovementDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/fetal-movements',
      data: dto.toJson(),
    );
    return FetalMovementModel.fromJson(res.data!);
  }

  Future<List<FetalMovementModel>> getFetalMovementsToday() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final res = await _dio.get<List<dynamic>>(
      '$_base/fetal-movements',
      queryParameters: {'date': dateStr},
    );
    return (res.data ?? [])
        .map((e) => FetalMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 산모 건강 기록 ─────────────────────────────────────────────────────────

  Future<MaternalLogModel> addMaternalLog(AddMaternalLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/maternal-logs',
      data: dto.toJson(),
    );
    return MaternalLogModel.fromJson(res.data!);
  }

  Future<List<MaternalLogModel>> getMaternalLogs() async {
    final res = await _dio.get<List<dynamic>>('$_base/maternal-logs');
    return (res.data ?? [])
        .map((e) => MaternalLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
