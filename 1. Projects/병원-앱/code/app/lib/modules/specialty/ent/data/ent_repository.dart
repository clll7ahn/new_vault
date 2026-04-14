import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/ent_model.dart';

/// 이비인후과 API 레포지토리
class EntRepository {
  EntRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/ent';

  Future<SymptomLogModel> addSymptomLog(AddSymptomLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/symptom-logs',
      data: dto.toJson(),
    );
    return SymptomLogModel.fromJson(res.data!);
  }

  Future<List<SymptomLogModel>> getSymptomLogs({int limit = 14}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/symptom-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => SymptomLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AllergyModel>> getAllergies() async {
    final res = await _dio.get<List<dynamic>>('$_base/allergies');
    return (res.data ?? [])
        .map((e) => AllergyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SeasonAlertModel>> getSeasonAlerts() async {
    try {
      final res = await _dio.get<List<dynamic>>('$_base/season-alerts');
      return (res.data ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return SeasonAlertModel(
          id: m['id'] as String,
          title: m['title'] as String,
          body: m['body'] as String,
          season: m['season'] as String,
          iconCode: m['icon_code'] as int?,
        );
      }).toList();
    } on Exception {
      return kDefaultSeasonAlerts;
    }
  }
}

// 기본 시즌 알림
const kDefaultSeasonAlerts = [
  SeasonAlertModel(
    id: 'spring_pollen',
    title: '봄철 화분 주의',
    body: '수목화분 농도가 높습니다. 외출 시 마스크를 착용하세요.',
    season: 'spring',
  ),
  SeasonAlertModel(
    id: 'fall_ragweed',
    title: '가을철 잡초 화분 주의',
    body: '환삼덩굴·쑥 화분이 피크입니다. 코 세척을 권장합니다.',
    season: 'fall',
  ),
];
