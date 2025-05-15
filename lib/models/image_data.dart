import 'dart:io';

class ImageData {
  File? file; // Локальный файл для новых изображений
  String? imageUrl; // URL для существующих изображений
  int? imageId; // ID для существующих изображений (при редактировании)
  bool isPrimary; // Флаг основного изображения

  ImageData({
    this.file,
    this.imageUrl,
    this.imageId,
    this.isPrimary = false,
  });
}