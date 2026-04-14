import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/neurology_model.dart';

class NeurologyRepository {
  NeurologyRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/neurology';

  Future<HeadacheLogModel> addHeadacheLog(AddHeadacheLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
        '$_base/headache-logs', data: dto.toJson());
    return HeadacheLogModel.fromJson(res.data!);
  }

  Future<List<HeadacheLogModel>> getHeadacheLogs({int limit = 14}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/headache-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => HeadacheLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CognitivScoreModel>> getCognitivScores({int limit = 6}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/cognitive-scores',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => CognitivScoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
