import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/dental_model.dart';

/// 치과 API 레포지토리
class DentalRepository {
  DentalRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/dental';

  // ── 치아 차트 ──────────────────────────────────────────────────────────────

  Future<ToothChartModel> getToothChart() async {
    final res =
        await _dio.get<Map<String, dynamic>>('$_base/tooth-chart');
    return ToothChartModel.fromJson(res.data!);
  }

  // ── 치료 계획 타임라인 ──────────────────────────────────────────────────────

  Future<List<DentalTreatmentModel>> getTreatments() async {
    final res = await _dio.get<List<dynamic>>('$_base/treatments');
    return (res.data ?? [])
        .map((e) => DentalTreatmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 다음 검진 ──────────────────────────────────────────────────────────────

  Future<NextCheckupModel?> getNextCheckup() async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('$_base/next-checkup');
      return res.data != null ? NextCheckupModel.fromJson(res.data!) : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
