import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/family_medicine_model.dart';

class FamilyMedicineRepository {
  FamilyMedicineRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/family-medicine';

  Future<List<HealthCheckResultModel>> getHealthCheckResults() async {
    final res = await _dio.get<List<dynamic>>('$_base/health-checks');
    return (res.data ?? [])
        .map((e) => HealthCheckResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LifestyleLogModel>> getLifestyleLogs({int limit = 30}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/lifestyle-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => LifestyleLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LifestyleLogModel> addLifestyleLog(AddLifestyleLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/lifestyle-logs',
      data: dto.toJson(),
    );
    return LifestyleLogModel.fromJson(res.data!);
  }

  Future<List<BmiRecordModel>> getBmiRecords({int limit = 12}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/bmi-records',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => BmiRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BmiRecordModel> addBmiRecord(AddBmiRecordDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/bmi-records',
      data: dto.toJson(),
    );
    return BmiRecordModel.fromJson(res.data!);
  }
}
