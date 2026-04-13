import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/notification_model.dart';

/// 알림 API 레포지토리
///
/// - getNotifications  : 알림 목록 페이지네이션 조회
/// - getUnreadCount    : 미읽음 알림 수
/// - markAsRead        : 특정 알림 읽음 처리
/// - markAllAsRead     : 전체 읽음 처리
class NotificationRepository {
  NotificationRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  // ──────────────────────────────────────────
  // 알림 목록 (페이지네이션)
  // ──────────────────────────────────────────

  Future<NotificationPage> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.notifications,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return NotificationPage.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 미읽음 알림 수
  // ──────────────────────────────────────────

  Future<int> getUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.notifications}/unread-count',
    );
    return response.data?['count'] as int? ?? 0;
  }

  // ──────────────────────────────────────────
  // 특정 알림 읽음 처리
  // ──────────────────────────────────────────

  Future<void> markAsRead(String id) async {
    await _dio.patch<void>(
      '${ApiConstants.notifications}/$id/read',
    );
  }

  // ──────────────────────────────────────────
  // 전체 읽음 처리
  // ──────────────────────────────────────────

  Future<void> markAllAsRead() async {
    await _dio.patch<void>(
      '${ApiConstants.notifications}/read-all',
    );
  }
}
