import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/psychiatry_model.dart';

/// 정신건강 API 레포지토리
class PsychiatryRepository {
  PsychiatryRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/psychiatry';

  // ── 기분 기록 ──────────────────────────────────────────────────────────────

  Future<MoodLogModel> addMoodLog(AddMoodLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/mood-logs',
      data: dto.toJson(),
    );
    return MoodLogModel.fromJson(res.data!);
  }

  Future<List<MoodLogModel>> getMoodLogs({int limit = 14}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/mood-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => MoodLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 수면 일지 ──────────────────────────────────────────────────────────────

  Future<SleepLogModel> addSleepLog(AddSleepLogDto dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/sleep-logs',
      data: dto.toJson(),
    );
    return SleepLogModel.fromJson(res.data!);
  }

  Future<List<SleepLogModel>> getSleepLogs({int limit = 7}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/sleep-logs',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => SleepLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 위기 상담 리소스 ───────────────────────────────────────────────────────

  /// 서버에서 최신 리소스를 가져오고, 실패 시 내장 기본값으로 폴백
  Future<List<CrisisResource>> getCrisisResources() async {
    try {
      final res = await _dio.get<List<dynamic>>('$_base/crisis-resources');
      return (res.data ?? [])
          .map((e) {
            final m = e as Map<String, dynamic>;
            return CrisisResource(
              name: m['name'] as String,
              phoneNumber: m['phone_number'] as String,
              description: m['description'] as String,
              available24h: m['available_24h'] as bool? ?? true,
            );
          })
          .toList();
    } on Exception {
      // 네트워크 오류 시 내장 기본값 사용
      return kDefaultCrisisResources;
    }
  }
}
