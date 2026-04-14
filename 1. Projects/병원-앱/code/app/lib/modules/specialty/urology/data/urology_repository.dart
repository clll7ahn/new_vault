import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/urology_model.dart';

class UrologyRepository {
  UrologyRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/urology';

  Future<VoidingLogModel> addVoidingLog(AddVoidingLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
        '$_base/voiding-logs', data: dto.toJson());
    return VoidingLogModel.fromJson(res.data!);
  }

  Future<List<VoidingLogModel>> getVoidingLogs({int limit = 20}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/voiding-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => VoidingLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PsaRecordModel>> getPsaRecords({int limit = 10}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/psa-records',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => PsaRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HydrationLogModel> addHydrationLog(AddHydrationLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
        '$_base/hydration-logs', data: dto.toJson());
    return HydrationLogModel.fromJson(res.data!);
  }

  Future<int> getTodayHydrationMl() async {
    final res = await _dio
        .get<Map<String, dynamic>>('$_base/hydration-logs/today-total');
    return (res.data?['total_ml'] as num?)?.toInt() ?? 0;
  }
}
