import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chatbot_repository.dart';
import '../domain/chatbot_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// FAQ Provider
// ──────────────────────────────────────────────────────────────────────────────

final faqsProvider = FutureProvider<List<FaqModel>>((ref) {
  return ref.read(chatbotRepositoryProvider).getFaqs();
});

// ──────────────────────────────────────────────────────────────────────────────
// 세션 목록 Provider
// ──────────────────────────────────────────────────────────────────────────────

final chatSessionsProvider =
    FutureProvider<List<ChatSessionModel>>((ref) {
  return ref.read(chatbotRepositoryProvider).getSessions();
});

// ──────────────────────────────────────────────────────────────────────────────
// 채팅 상태 — ChatState
// ──────────────────────────────────────────────────────────────────────────────

class ChatState {
  const ChatState({
    required this.messages,
    required this.sessionId,
    this.isLoading = false,
    this.errorMessage,
    this.hasEmergency = false,
  });

  final List<ChatMessageModel> messages;
  final String? sessionId;
  final bool isLoading;
  final String? errorMessage;
  final bool hasEmergency;

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    String? sessionId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? hasEmergency,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasEmergency: hasEmergency ?? this.hasEmergency,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ChatNotifier
// ──────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState(messages: [], sessionId: null);

  ChatbotRepository get _repo => ref.read(chatbotRepositoryProvider);

  /// 기존 세션 메시지 로드
  Future<void> loadSession(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await _repo.getMessages(sessionId);
      state = state.copyWith(
        messages: messages,
        sessionId: sessionId,
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// 메시지 전송
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 사용자 메시지 즉시 UI에 추가 (Optimistic UI)
    final userMsg = ChatMessageModel.local(
      sessionId: state.sessionId ?? '',
      content: text.trim(),
      sender: MessageSender.user,
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final botReply = await _repo.sendMessage(
        sessionId: state.sessionId,
        message: text.trim(),
      );
      final isEmergency = botReply.isEmergency ||
          botReply.type == MessageType.emergency;

      state = state.copyWith(
        messages: [...state.messages, botReply],
        sessionId: botReply.sessionId,
        isLoading: false,
        hasEmergency: isEmergency ? true : state.hasEmergency,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// 빠른 답변 칩 선택 시
  Future<void> sendQuickReply(String reply) => sendMessage(reply);

  void dismissEmergency() => state = state.copyWith(hasEmergency: false);

  void reset() {
    state = const ChatState(messages: [], sessionId: null);
  }

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '메시지 전송 중 오류가 발생했습니다.';
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
