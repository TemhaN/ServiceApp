class Category {
  final int categoryId;
  final String name;
  final int? parentCategoryId;
  final bool isActive;

  Category({
    required this.categoryId,
    required this.name,
    this.parentCategoryId,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] ?? 0,
      name: json['name'] ?? '',
      parentCategoryId: json['parentCategoryId'],
      isActive: json['isActive'] ?? false,
    );
  }
}