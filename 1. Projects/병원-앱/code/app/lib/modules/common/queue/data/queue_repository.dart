import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/queue_model.dart';

/// 대기열 API 레포지토리
///
/// - checkIn         : 대기열 등록(체크인)
/// - getCurrentQueue : 특정 의사의 현재 대기열 조회
/// - getMyStatus     : 내 현재 대기 상태 조회
/// - cancelEntry     : 대기 취소
/// - getEstimate     : 특정 의사의 대기 예측 조회
class QueueRepository {
  QueueRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  // ──────────────────────────────────────────
  // 대기열 등록 (체크인)
  // ──────────────────────────────────────────

  Future<QueueEntryModel> checkIn(CheckInDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.queue,
      data: dto.toJson(),
    );
    return QueueEntryModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 특정 의사의 현재 대기열 목록
  // ──────────────────────────────────────────

  Future<List<QueueEntryModel>> getCurrentQueue(String doctorId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.queue,
      queryParameters: {'doctor_id': doctorId},
    );
    return (response.data ?? [])
        .map((e) => QueueEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 내 현재 대기 상태
  // ──────────────────────────────────────────

  Future<QueueEntryModel?> getMyStatus() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.queueMyStatus,
    );
    if (response.data == null || response.data!.isEmpty) return null;
    return QueueEntryModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 대기 취소
  // ──────────────────────────────────────────

  Future<void> cancelEntry(String id) async {
    await _dio.patch<void>(
      '${ApiConstants.queue}/$id/cancel',
    );
  }

  // ──────────────────────────────────────────
  // 대기 예측 조회
  // ──────────────────────────────────────────

  Future<QueueEstimate> getEstimate(String doctorId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.queueEstimate,
      queryParameters: {'doctor_id': doctorId},
    );
    return QueueEstimate.fromJson(response.data!);
  }
}
