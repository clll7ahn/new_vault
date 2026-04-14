import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/chatbot_model.dart';
import '../providers/chatbot_provider.dart';

/// 챗봇 채팅 페이지
///
/// - 버블: 사용자 우측(primary), 봇 좌측(surface)
/// - 빠른 답변 칩: 입력창 위 가로 스크롤 ["진료시간", "주차", "증상 체크", "예약"]
/// - 응급 감지 시 빨간 배너 + 119 전화 버튼
/// - 하단 입력창 + 전송 버튼
/// - 세션 시작 시 환영 메시지 자동 표시
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // 입력창 위 고정 빠른 답변 칩
  static const _persistentQuickReplies = ['진료시간', '주차', '증상 체크', '예약'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    final notifier = ref.read(chatProvider.notifier);
    if (widget.sessionId != null) {
      await notifier.loadSession(widget.sessionId!);
    } else {
      // 새 세션: 환영 메시지 요청
      notifier.reset();
      await notifier.sendMessage('안녕하세요');
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _call119() async {
    final uri = Uri(scheme: 'tel', path: '119');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 메시지 갱신 시 스크롤
    ref.listen(chatProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 건강 상담'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새 대화',
            onPressed: () {
              ref.read(chatProvider.notifier).reset();
              _initSession();
            },
            constraints:
                const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 응급 배너 ─────────────────────────────────────────────────────
          if (chatState.hasEmergency)
            _EmergencyBanner(
              onCall119: _call119,
              onDismiss: () =>
                  ref.read(chatProvider.notifier).dismissEmergency(),
            ),

          // ── 에러 스낵바 대체 ───────────────────────────────────────────────
          if (chatState.errorMessage != null)
            Material(
              color: cs.errorContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: cs.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.errorMessage!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 메시지 목록 ──────────────────────────────────────────────────
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isLoading
                ? _EmptyChat(
                    onFaqTap: (question) {
                      ref
                          .read(chatProvider.notifier)
                          .sendMessage(question);
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: chatState.messages.length +
                        (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = chatState.messages[index];
                      return _MessageBubble(
                        message: msg,
                        onQuickReply: (reply) {
                          ref
                              .read(chatProvider.notifier)
                              .sendQuickReply(reply);
                        },
                      );
                    },
                  ),
          ),

          // ── 고정 빠른 답변 칩 (입력창 위) ────────────────────────────────
          _PersistentQuickReplies(
            replies: _persistentQuickReplies,
            onSelected: (reply) {
              ref.read(chatProvider.notifier).sendQuickReply(reply);
              _scrollToBottom();
            },
          ),

          // ── 입력창 ───────────────────────────────────────────────────────
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: chatState.isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 응급 배너
// ──────────────────────────────────────────────────────────────────────────────

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({
    required this.onCall119,
    required this.onDismiss,
  });

  final VoidCallback onCall119;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFDC2626),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '응급 상황이 감지되었습니다.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onCall119,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
                minimumSize: const Size(60, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '119 전화',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: onDismiss,
              constraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 메시지 버블
// ──────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onQuickReply,
  });

  final ChatMessageModel message;
  final void Function(String) onQuickReply;

  static final _timeFmt = DateFormat('HH:mm');

  bool get _isUser => message.sender == MessageSender.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bubbleColor = _isUser ? cs.primary : cs.surface;
    final textColor =
        _isUser ? cs.onPrimary : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: _isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 봇 아바타
              if (!_isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.smart_toy_outlined,
                      size: 18, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 8),
              ],

              // 버블
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(_isUser ? 18 : 4),
                      bottomRight: Radius.circular(_isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: textColor),
                  ),
                ),
              ),

              // 시간
              const SizedBox(width: 6),
              Text(
                _timeFmt.format(message.createdAt.toLocal()),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),

          // 빠른 답변 칩
          if (!_isUser &&
              message.quickReplies != null &&
              message.quickReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: message.quickReplies!.map((reply) {
                  return ActionChip(
                    label: Text(reply),
                    onPressed: () => onQuickReply(reply),
                    labelStyle: theme.textTheme.labelMedium
                        ?.copyWith(color: cs.primary),
                    backgroundColor: cs.primaryContainer.withOpacity(0.4),
                    side: BorderSide(color: cs.primary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 타이핑 인디케이터
// ──────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.smart_toy_outlined,
                size: 18, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DotPulse(delay: Duration(milliseconds: i * 200)),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  const _DotPulse({required this.delay});

  final Duration delay;

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 빈 상태 — FAQ 빠른 접근
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyChat extends ConsumerWidget {
  const _EmptyChat({required this.onFaqTap});

  final void Function(String question) onFaqTap;

  // 로컬 FAQ 폴백 (서버 응답 전)
  static const _localFaqs = [
    '예약은 어떻게 하나요?',
    '대기 시간이 얼마나 걸리나요?',
    '처방전 재발급 방법이 궁금해요.',
    '응급실 위치를 알려주세요.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final faqsAsync = ref.watch(faqsProvider);

    final questions = faqsAsync.maybeWhen(
      data: (faqs) => faqs.map((f) => f.question).take(4).toList(),
      orElse: () => _localFaqs,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 36,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.smart_toy_outlined,
                size: 36, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(
            '무엇을 도와드릴까요?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '건강 질문, 예약 안내, 병원 정보를\n편하게 물어보세요.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('자주 묻는 질문', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 12),
          ...questions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onFaqTap(q),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(q, style: theme.textTheme.bodyMedium),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 고정 빠른 답변 칩 (입력창 위 가로 스크롤)
// ──────────────────────────────────────────────────────────────────────────────

class _PersistentQuickReplies extends StatelessWidget {
  const _PersistentQuickReplies({
    required this.replies,
    required this.onSelected,
  });

  final List<String> replies;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      color: cs.surface,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(reply),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                ),
                backgroundColor: cs.primaryContainer.withOpacity(0.2),
                side: BorderSide(color: cs.primary.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onPressed: () => onSelected(reply),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 입력창
// ──────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요…',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: cs.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 전송 버튼 — 최소 48dp
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  minimumSize: const Size(48, 48),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
