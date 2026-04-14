import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/ophthalmology_model.dart';

/// 안과 API 레포지토리
class OphthalmologyRepository {
  OphthalmologyRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/ophthalmology';

  // ── 시력 측정 기록 ─────────────────────────────────────────────────────────

  Future<VisionLogModel> addVisionLog(Map<String, dynamic> dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/vision-logs',
      data: dto,
    );
    return VisionLogModel.fromJson(res.data!);
  }

  Future<List<VisionLogModel>> getVisionLogs() async {
    final res = await _dio.get<List<dynamic>>('$_base/vision-logs');
    return (res.data ?? [])
        .map((e) => VisionLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 처방 정보 ──────────────────────────────────────────────────────────────

  Future<List<PrescriptionModel>> getPrescriptions() async {
    final res = await _dio.get<List<dynamic>>('$_base/prescriptions');
    return (res.data ?? [])
        .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 안약 정보 ──────────────────────────────────────────────────────────────

  Future<List<EyeDropModel>> getEyeDrops() async {
    final res = await _dio.get<List<dynamic>>('$_base/eye-drops');
    return (res.data ?? [])
        .map((e) => EyeDropModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
