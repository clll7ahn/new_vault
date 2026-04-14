import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/plastic_surgery_model.dart';

class PlasticSurgeryRepository {
  PlasticSurgeryRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/plastic-surgery';

  Future<List<ProcedureRecordModel>> getProcedures() async {
    final res = await _dio.get<List<dynamic>>('$_base/procedures');
    return (res.data ?? [])
        .map((e) => ProcedureRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecoveryLogModel>> getRecoveryLogs(
      {required String procedureId}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/recovery-logs',
      queryParameters: {'procedure_id': procedureId},
    );
    return (res.data ?? [])
        .map((e) => RecoveryLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecoveryLogModel> addRecoveryLog(AddRecoveryLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
        '$_base/recovery-logs', data: dto.toJson());
    return RecoveryLogModel.fromJson(res.data!);
  }
}
