import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/korean_medicine_model.dart';

class KoreanMedicineRepository {
  KoreanMedicineRepository({Dio? dio})
      : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/korean-medicine';

  Future<PatientSasangProfile?> getSasangProfile() async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('$_base/sasang-profile');
      return PatientSasangProfile.fromJson(res.data!);
    } on Exception {
      return null;
    }
  }

  Future<List<TreatmentRecordModel>> getTreatmentRecords(
      {int limit = 20}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/treatment-records',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) =>
            TreatmentRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SasangGuideModel> getSasangGuide(SasangType type) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_base/sasang-guide',
        queryParameters: {'type': type.apiKey},
      );
      return SasangGuideModel.fromJson(res.data!);
    } on Exception {
      return kDefaultSasangGuides[type]!;
    }
  }
}
