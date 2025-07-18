import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_app/models/category.dart';
import 'package:service_app/models/service.dart';
import 'package:service_app/services/api_service.dart';

class ServiceEditScreen extends StatefulWidget {
  final Service? service;

  ServiceEditScreen({this.service});

  @override
  _ServiceEditScreenState createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends State<ServiceEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  List<String> _locations = [
    'Все',
    'Алматы',
    'Астана',
    'Шымкент',
    'Актобе',
    'Караганда',
    'Атырау'
  ];
  String? _selectedLocation;

  List<File> _newImages = [];
  List<ServiceImage> _existingImages = [];
  int? _primaryImageIndex;
  int? _categoryId;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  double _pickImagesButtonScale = 1.0; // Для анимации кнопки "Выбрать изображения"
  double _saveButtonScale = 1.0; // Для анимации кнопки "Создать/Сохранить"

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.service != null) {
      _titleController.text = widget.service!.title;
      _descriptionController.text = widget.service!.description ?? '';
      _priceController.text = widget.service!.price?.toString() ?? '';
      _locationController.text = widget.service!.location ?? '';
      _selectedLocation = widget.service!.location ?? 'Все';
      _categoryId = widget.service!.categoryId;
      _existingImages = widget.service!.serviceImages;
      for (int i = 0; i < _existingImages.length; i++) {
        if (_existingImages[i].isPrimary) {
          _primaryImageIndex = i;
          break;
        }
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories.where((c) => c.isActive).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки категорий: $e';
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _newImages.addAll(pickedFiles.map((file) => File(file.path)));
        if (_primaryImageIndex == null && _newImages.isNotEmpty) {
          _primaryImageIndex = _existingImages.length;
        }
      });
    }
  }

  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
    });
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _existingImages.length) {
        _existingImages.removeAt(index);
      } else {
        _newImages.removeAt(index - _existingImages.length);
      }
      if (_primaryImageIndex == index) {
        _primaryImageIndex = null;
      } else if (_primaryImageIndex != null && _primaryImageIndex! > index) {
        _primaryImageIndex = _primaryImageIndex! - 1;
      }
      if (_primaryImageIndex == null &&
          (_existingImages.isNotEmpty || _newImages.isNotEmpty)) {
        _primaryImageIndex = 0;
      }
    });
  }

  Future<void> _saveService() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_titleController.text.isEmpty) {
        throw Exception('Название обязательно');
      }
      if (_titleController.text.length > 100) {
        throw Exception('Название не должно превышать 100 символов');
      }
      if (_descriptionController.text.isEmpty) {
        throw Exception('Описание обязательно');
      }
      if (_descriptionController.text.length > 1000) {
        throw Exception('Описание не должно превышать 1000 символов');
      }
      if (_locationController.text.length > 200) {
        throw Exception('Местоположение не должно превышать 200 символов');
      }
      if (_categoryId == null) {
        throw Exception('Категория обязательна');
      }
      final price = double.tryParse(_priceController.text);
      if (_priceController.text.isNotEmpty && price == null) {
        throw Exception('Некорректная цена');
      }
      if (!_categories.any((c) => c.categoryId == _categoryId)) {
        throw Exception('Выбранная категория недействительна');
      }
      if ((_existingImages.isNotEmpty || _newImages.isNotEmpty) &&
          _primaryImageIndex == null) {
        throw Exception('Выберите основное изображение');
      }

      int? serverPrimaryImageIndex;
      List<int> existingImageIds = _existingImages.map((img) => img.imageId).toList();
      if (_primaryImageIndex != null) {
        if (_primaryImageIndex! < _existingImages.length) {
          serverPrimaryImageIndex = null;
        } else {
          serverPrimaryImageIndex = _primaryImageIndex! - _existingImages.length;
        }
      }

      if (widget.service == null) {
        await ApiService.createService(
          title: _titleController.text,
          description: _descriptionController.text,
          price: price ?? 0,
          location: _selectedLocation == 'Все' ? '' : _selectedLocation!,
          categoryId: _categoryId!,
          images: _newImages,
          primaryImageIndex: serverPrimaryImageIndex,
        );
      } else {
        await ApiService.updateService(
          id: widget.service!.serviceId,
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          location: _selectedLocation == 'Все' ? '' : _selectedLocation!,
          categoryId: _categoryId!,
          images: _newImages.isNotEmpty ? _newImages : null,
          primaryImageIndex: serverPrimaryImageIndex,
          existingImageIds: existingImageIds,
          primaryExistingImageId: _primaryImageIndex != null &&
              _primaryImageIndex! < _existingImages.length
              ? _existingImages[_primaryImageIndex!].imageId
              : null,
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.service == null ? 'Услуга создана' : 'Услуга обновлена',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Color(0xFF7B3BEA).withOpacity(0.3),
              width: 0.5,
            ),
          ),
          elevation: 8,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Ошибка сохранения услуги: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _existingImages.length + _newImages.length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.0),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              widget.service == null ? 'Добавить услугу' : 'Редактировать услугу',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Секция изображений
            Text(
              'Изображения',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTapDown: (_) => setState(() => _pickImagesButtonScale = 0.95),
              onTapUp: (_) {
                setState(() => _pickImagesButtonScale = 1.0);
                _pickImages();
              },
              onTapCancel: () => setState(() => _pickImagesButtonScale = 1.0),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_pickImagesButtonScale),
                transformAlignment: Alignment.center, // Центрирование анимации
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B3BEA), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7B3BEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Выбрать изображения',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 12),
            totalImages > 0
                ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(totalImages, (index) {
                final isExisting = index < _existingImages.length;
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _primaryImageIndex == index
                              ? Color(0xFF7B3BEA)
                              : Color(0xFFB0B0B0),
                          width: _primaryImageIndex == index ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF7B3BEA).withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isExisting
                            ? Image.network(
                          '${ApiService.baseImageUrl}${_existingImages[index].imageUrl}',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'assets/images/placeholder.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                        )
                            : Image.file(
                          _newImages[index - _existingImages.length],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Transform.scale(
                        scale: 0.8,
                        child: Checkbox(
                          value: _primaryImageIndex == index,
                          onChanged: (value) {
                            if (value == true) _setPrimaryImage(index);
                          },
                          activeColor: Color(0xFF7B3BEA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            )
                : Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(45),
              ),
              child: Text(
                'Изображения не выбраны',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(1),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Поля формы
            Text(
              'Основная информация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Название',
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Roboto',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
              ),
              maxLines: 4,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Цена (KZT)',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Roboto',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLocation ?? _locations[0],
              decoration: InputDecoration(
                labelText: 'Местоположение',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Roboto',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
              ),
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                  _locationController.text = value == 'Все' ? '' : value!; // Синхронизация с _locationController
                });
              },
            ),
            SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _categoryId,
          decoration: InputDecoration(
            labelText: 'Категория',
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
          ),
          items: _categories
              .map((category) => DropdownMenuItem(
            value: category.categoryId,
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _categoryId = value;
            });
          },
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SizedBox(height: 24),
            GestureDetector(
              onTapDown: (_) => setState(() => _saveButtonScale = 0.95),
              onTapUp: (_) {
                setState(() => _saveButtonScale = 1.0);
                _saveService();
              },
              onTapCancel: () => setState(() => _saveButtonScale = 1.0),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(_saveButtonScale),
                transformAlignment: Alignment.center, // Центрирование анимации
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B3BEA), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7B3BEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.service == null ? 'Создать' : 'Сохранить',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}