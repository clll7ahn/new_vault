import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ──────────────────────────────────────────────────────────────────────────────
// LLM Chat Domain (인라인, 경량)
// ──────────────────────────────────────────────────────────────────────────────

enum LlmRole { user, assistant, system }

class LlmMessage {
  const LlmMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isEmergency = false,
  });

  final String id;
  final LlmRole role;
  final String content;
  final DateTime createdAt;
  final bool isEmergency;

  factory LlmMessage.user(String content) => LlmMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: LlmRole.user,
        content: content,
        createdAt: DateTime.now(),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// LLM Chat Provider
// ──────────────────────────────────────────────────────────────────────────────

// 응급 키워드 목록
const _emergencyKeywords = [
  '가슴통증', '호흡곤란', '실신', '의식불명', '뇌졸중', '심장마비',
  '자살', '자해', '응급', '119', '쓰러졌',
];

bool _detectEmergency(String text) {
  return _emergencyKeywords.any((kw) => text.contains(kw));
}

sealed class LlmChatState { const LlmChatState(); }
final class LlmChatIdle extends LlmChatState { const LlmChatIdle(); }
final class LlmChatLoading extends LlmChatState { const LlmChatLoading(); }
final class LlmChatError extends LlmChatState {
  const LlmChatError(this.message);
  final String message;
}

class LlmChatNotifier extends Notifier<LlmChatState> {
  @override
  LlmChatState build() => const LlmChatIdle();

  final List<LlmMessage> _messages = [];
  List<LlmMessage> get messages => List.unmodifiable(_messages);

  bool get hasEmergency =>
      _messages.any((m) => m.isEmergency);

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    final isEmergency = _detectEmergency(text);
    final userMsg = LlmMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: LlmRole.user,
      content: text.trim(),
      createdAt: DateTime.now(),
      isEmergency: isEmergency,
    );
    _messages.add(userMsg);
    state = const LlmChatLoading();

    try {
      // 실제 LLM API 호출 자리 (DioClient + /llm/chat endpoint)
      await Future.delayed(const Duration(milliseconds: 800));
      final assistantMsg = LlmMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_a',
        role: LlmRole.assistant,
        content: isEmergency
            ? '응급 상황이 감지되었습니다. 즉시 119에 연락하거나 가까운 응급실을 방문하세요.'
            : '안녕하세요. 증상에 대해 좀 더 자세히 말씀해 주시겠어요? '
                '(이 답변은 의료 진단을 대체하지 않습니다.)',
        createdAt: DateTime.now(),
        isEmergency: isEmergency,
      );
      _messages.add(assistantMsg);
      state = const LlmChatIdle();
    } on Exception catch (e) {
      state = LlmChatError(e.toString());
    }
  }

  void clear() {
    _messages.clear();
    state = const LlmChatIdle();
  }
}

final llmChatProvider =
    NotifierProvider<LlmChatNotifier, LlmChatState>(LlmChatNotifier.new);

// ──────────────────────────────────────────────────────────────────────────────
// LlmChatPage — 자유 대화형 LLM 챗봇
// ──────────────────────────────────────────────────────────────────────────────

class LlmChatPage extends ConsumerStatefulWidget {
  const LlmChatPage({super.key});

  @override
  ConsumerState<LlmChatPage> createState() => _LlmChatPageState();
}

class _LlmChatPageState extends ConsumerState<LlmChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showEmergencyBanner = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(llmChatProvider);
    final notifier = ref.read(llmChatProvider.notifier);
    final messages = notifier.messages;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = chatState is LlmChatLoading;

    ref.listen(llmChatProvider, (prev, next) {
      if (next is LlmChatIdle) {
        _scrollToBottom();
        // 응급 감지 체크
        final hasEmerg = notifier.hasEmergency;
        if (hasEmerg && !_showEmergencyBanner) {
          setState(() => _showEmergencyBanner = true);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 의료 상담'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '대화 초기화',
            onPressed: () {
              notifier.clear();
              setState(() => _showEmergencyBanner = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 응급 감지 배너
          if (_showEmergencyBanner) _EmergencyBanner(
            onDismiss: () => setState(() => _showEmergencyBanner = false),
          ),

          // 메시지 목록
          Expanded(
            child: messages.isEmpty
                ? _EmptyState(cs: cs, theme: theme)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _MessageBubble(messages[i]),
                  ),
          ),

          // 입력 영역
          _InputBar(
            controller: _inputCtrl,
            isLoading: isLoading,
            onSend: (text) {
              _inputCtrl.clear();
              ref.read(llmChatProvider.notifier).send(text);
            },
          ),

          // 면책 조항 (하단 고정)
          _DisclaimerBar(cs: cs, theme: theme),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 응급 감지 배너
// ──────────────────────────────────────────────────────────────────────────────

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDC2626),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.emergency_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '응급 상황이 감지되었습니다. 즉시 119에 연락하세요.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 메시지 버블
// ──────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(this.message);
  final LlmMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUser = message.role == LlmRole.user;
    final isEmerg = message.isEmergency;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary,
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isEmerg
                    ? const Color(0xFFDC2626).withOpacity(0.1)
                    : isUser
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isEmerg
                    ? Border.all(
                        color: const Color(0xFFDC2626).withOpacity(0.4))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmerg)
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 4),
                      Text('응급',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w700)),
                    ]),
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? cs.onPrimary.withOpacity(0.6)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 입력 바
// ──────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '증상이나 궁금한 점을 입력하세요...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 52,
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) onSend(text);
                    },
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 면책 조항 바 (하단 고정)
// ──────────────────────────────────────────────────────────────────────────────

class _DisclaimerBar extends StatelessWidget {
  const _DisclaimerBar({required this.cs, required this.theme});
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: cs.errorContainer.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        '이 AI 상담은 참고용이며, 의료 진단·처방을 대체하지 않습니다. '
        '응급 상황 시 즉시 119에 연락하거나 응급실을 방문하세요.',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 빈 상태
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs, required this.theme});
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text('AI 의료 상담을 시작하세요',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('증상, 약물, 건강 관련 질문을 입력하세요.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
