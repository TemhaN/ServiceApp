import 'package:service_app/models/service.dart';
import 'package:service_app/models/user.dart';
import 'package:service_app/models/message.dart';

class Chat {
  final int chatId;
  final int serviceId;
  final int customerId;
  final int providerId;
  final DateTime createdAt;
  final bool isActive;
  final Service? service;
  final User? customer;
  final User? provider;
  final Message? lastMessage;

  Chat({
    required this.chatId,
    required this.serviceId,
    required this.customerId,
    required this.providerId,
    required this.createdAt,
    required this.isActive,
    this.service,
    this.customer,
    this.provider,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      return Chat(
        chatId: (json['chatId'] as num?)?.toInt() ?? 0,
        serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
        customerId: (json['customerId'] as num?)?.toInt() ?? 0,
        providerId: (json['providerId'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isActive: json['isActive'] as bool? ?? false,
        service: json['service'] != null ? Service.fromJson(json['service'] as Map<String, dynamic>) : null,
        customer: json['customer'] != null ? User.fromJson(json['customer'] as Map<String, dynamic>) : null,
        provider: json['provider'] != null ? User.fromJson(json['provider'] as Map<String, dynamic>) : null,
        lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>) : null,
      );
    } catch (e) {
      rethrow;
    }
  }
}