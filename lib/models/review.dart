import 'package:service_app/models/user.dart';

class Review {
  final int id;
  final int serviceId;
  final int userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final User? user;

  Review({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['reviewId'] ?? json['id'] ?? 0) as int,
      serviceId: json['serviceId'] as int,
      userId: json['userId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': id,
      'serviceId': serviceId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}