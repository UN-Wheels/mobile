enum MessageStatus { sent, delivered, read }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.status,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
    this.isOptimistic = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isOptimistic;

  static MessageStatus _parseStatus(String? s) => switch (s?.toUpperCase()) {
        'DELIVERED' => MessageStatus.delivered,
        'READ' => MessageStatus.read,
        _ => MessageStatus.sent,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['_id'] ?? json['messageId'] ?? json['id'])?.toString() ?? '',
        conversationId: (json['conversationId'] ?? '').toString(),
        senderId: (json['senderId'] ?? '').toString(),
        content: (json['content'] as String?) ?? '',
        status: _parseStatus(json['status'] as String?),
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.tryParse(json['deliveredAt'].toString())
            : null,
        readAt: json['readAt'] != null
            ? DateTime.tryParse(json['readAt'].toString())
            : null,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
            DateTime.now(),
      );

  ChatMessage copyWith({
    MessageStatus? status,
    bool? isOptimistic,
    String? id,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        status: status ?? this.status,
        deliveredAt: deliveredAt,
        readAt: readAt,
        createdAt: createdAt,
        isOptimistic: isOptimistic ?? this.isOptimistic,
      );
}
