class Message {
  final int messageId;
  final int? chatId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final DateTime? editedAt;
  final bool isRead;

  Message({
    required this.messageId,
    this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.editedAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        messageId: (json['messageId'] as num?)?.toInt() ?? 0, // Используем 'id' вместо 'messageId'
        chatId: (json['chatId'] as num?)?.toInt(),
        senderId: (json['senderId'] as num?)?.toInt() ?? 0, // Безопасная обработка
        senderName: json['senderName'] as String? ?? 'Unknown',
        content: json['content'] as String? ?? '',
        sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
        editedAt: json['editedAt'] != null ? DateTime.tryParse(json['editedAt'] as String) : null,
        isRead: json['isRead'] as bool? ?? false,
      );
    } catch (e) {
      print('Ошибка парсинга Message: $e, JSON: $json');
      rethrow;
    }
  }
}