class ServiceImage {
  final int imageId;
  final int serviceId;
  final String imageUrl;
  final bool isPrimary;
  final DateTime uploadedAt;

  ServiceImage({
    required this.imageId,
    required this.serviceId,
    required this.imageUrl,
    required this.isPrimary,
    required this.uploadedAt,
  });

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      imageId: json['imageId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }
}

class Service {
  final int serviceId;
  final int userId;
  final String userName;
  final int categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final double? price;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<ServiceImage> serviceImages;

  Service({
    required this.serviceId,
    required this.userId,
    required this.userName,
    required this.categoryId,
    this.categoryName,
    required this.title,
    this.description,
    this.price,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.serviceImages,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      serviceId: json['serviceId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'],
      title: json['title'] ?? '',
      description: json['description'],
      price: json['price']?.toDouble(),
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? false,
      serviceImages: (json['serviceImages'] as List<dynamic>?)
          ?.map((e) => ServiceImage.fromJson(e))
          .toList() ??
          [],
    );
  }
}