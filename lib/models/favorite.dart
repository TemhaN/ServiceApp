import 'package:service_app/models/service.dart';

class Favorite {
  final int id;
  final int userId;
  final int serviceId;
  final DateTime addedAt;
  final Service service;

  Favorite({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.addedAt,
    required this.service,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
      service: Service.fromJson(json['service'] ?? {}),
    );
  }
}