/// 챗봇 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// MessageType
// ──────────────────────────────────────────────────────────────────────────────

enum MessageType {
  text,
  image,
  quickReply,
  emergency,
}

extension MessageTypeX on MessageType {
  static MessageType fromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'quick_reply':
        return MessageType.quickReply;
      case 'emergency':
        return MessageType.emergency;
      default:
        return MessageType.text;
    }
  }

  String get apiValue {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.quickReply:
        return 'quick_reply';
      case MessageType.emergency:
        return 'emergency';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MessageSender
// ──────────────────────────────────────────────────────────────────────────────

enum MessageSender { user, bot }

// ──────────────────────────────────────────────────────────────────────────────
// ChatMessageModel
// ──────────────────────────────────────────────────────────────────────────────

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    required this.type,
    required this.createdAt,
    this.quickReplies,
    this.isEmergency = false,
  });

  final String id;
  final String sessionId;
  final MessageSender sender;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final List<String>? quickReplies;
  final bool isEmergency;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      sender: (json['sender'] as String?) == 'bot'
          ? MessageSender.bot
          : MessageSender.user,
      content: json['content'] as String? ?? '',
      type: MessageTypeX.fromString(json['type'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      quickReplies: (json['quick_replies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isEmergency: json['is_emergency'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'sender': sender == MessageSender.bot ? 'bot' : 'user',
        'content': content,
        'type': type.apiValue,
        'created_at': createdAt.toIso8601String(),
        if (quickReplies != null) 'quick_replies': quickReplies,
        if (isEmergency) 'is_emergency': isEmergency,
      };

  /// 로컬 전송용 임시 메시지 생성
  factory ChatMessageModel.local({
    required String sessionId,
    required String content,
    required MessageSender sender,
    MessageType type = MessageType.text,
  }) {
    return ChatMessageModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      sender: sender,
      content: content,
      type: type,
      createdAt: DateTime.now(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ChatSessionModel
// ──────────────────────────────────────────────────────────────────────────────

class ChatSessionModel {
  const ChatSessionModel({
    required this.id,
    required this.patientId,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.isActive = true,
  });

  final String id;
  final String patientId;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool isActive;

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'created_at': createdAt.toIso8601String(),
        if (lastMessage != null) 'last_message': lastMessage,
        if (lastMessageAt != null)
          'last_message_at': lastMessageAt!.toIso8601String(),
        'is_active': isActive,
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// FaqModel
// ──────────────────────────────────────────────────────────────────────────────

class FaqModel {
  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    this.order = 0,
  });

  final String id;
  final String question;
  final String answer;
  final String? category;
  final int order;

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }
}
