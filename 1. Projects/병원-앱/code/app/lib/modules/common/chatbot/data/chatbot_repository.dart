import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/chatbot_model.dart';

/// 챗봇 API 레포지토리
///
/// - sendMessage   : 메시지 전송 → 봇 응답 반환
/// - getSessions   : 내 채팅 세션 목록
/// - getMessages   : 특정 세션 메시지 히스토리
/// - getFaqs       : FAQ 목록
class ChatbotRepository {
  ChatbotRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '${ApiConstants.apiV1}/chatbot';

  // ──────────────────────────────────────────
  // 메시지 전송
  // ──────────────────────────────────────────

  /// [sessionId] null이면 새 세션 생성 후 응답
  Future<ChatMessageModel> sendMessage({
    String? sessionId,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/messages',
      data: {
        if (sessionId != null) 'session_id': sessionId,
        'message': message,
        'type': type.apiValue,
      },
    );
    return ChatMessageModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 세션 목록
  // ──────────────────────────────────────────

  Future<List<ChatSessionModel>> getSessions() async {
    final response = await _dio.get<List<dynamic>>('$_base/sessions');
    return (response.data ?? [])
        .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 특정 세션 메시지 목록
  // ──────────────────────────────────────────

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/sessions/$sessionId/messages',
    );
    return (response.data ?? [])
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // FAQ 목록
  // ──────────────────────────────────────────

  Future<List<FaqModel>> getFaqs() async {
    final response = await _dio.get<List<dynamic>>('$_base/faqs');
    return (response.data ?? [])
        .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
