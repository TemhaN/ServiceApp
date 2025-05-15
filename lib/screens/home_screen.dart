import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:service_app/models/category.dart';
import 'package:service_app/models/service.dart';
import 'package:service_app/models/favorite.dart';
import 'package:service_app/screens/service_detail_screen.dart';
import 'package:service_app/services/api_service.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Service> _services = [];
  List<Favorite> _favorites = [];
  int _page = 1;
  bool _isLoading = false;
  bool _isSearchMode = false;
  bool _isTogglingFavorite = false;
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  Category? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedLocation;
  List<Category> _categories = [];
  List<String> _locations = [
    'Все',
    'Алматы',
    'Астана',
    'Шымкент',
    'Актобе',
    'Караганда',
    'Атырау'
  ];
  final ScrollController _scrollController = ScrollController(); // Новый контроллер

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFavorites();
    _loadServices(reset: true);
    _searchController.addListener(_onSearchChanged);
    _minPriceController.text = _minPrice?.toString() ?? '';
    _maxPriceController.text = _maxPrice?.toString() ?? '';

    // Добавляем слушатель для прокрутки
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadServices(); // Загружаем следующую страницу
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _scrollController.dispose(); // Очищаем контроллер
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = [
            Category(categoryId: 0, name: 'Все', isActive: true),
            ...categories
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка загрузки категорий: $e',
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
      }
    }
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      print('Favorites not loaded: not authenticated or no token');
      return;
    }

    try {
      final favorites = await ApiService.getFavorites(authProvider.token!);
      if (mounted) {
        setState(() {
          _favorites = favorites;
          print('Favorites loaded: ${_favorites.length}');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка загрузки избранного: $e',
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
      }
    }
  }

  Future<void> _toggleFavorite(Service service) async {
    if (_isTogglingFavorite) return;
    setState(() {
      _isTogglingFavorite = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      print('Toggle favorite failed: not authenticated or no token');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Войдите, чтобы добавить в избранное',
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
        setState(() {
          _isTogglingFavorite = false;
        });
      }
      return;
    }

    try {
      final isFavorited = _favorites.any((f) => f.serviceId == service.serviceId);
      if (isFavorited) {
        final favorite =
        _favorites.firstWhere((f) => f.serviceId == service.serviceId);
        await ApiService.removeFavorite(favorite.id, authProvider.token!);
        if (mounted) {
          setState(() {
            _favorites.removeWhere((f) => f.serviceId == service.serviceId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Услуга удалена из избранного',
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
        }
      } else {
        final response =
        await ApiService.addFavorite(service.serviceId, authProvider.token!);
        final favoriteId = response['favoriteId'] as int? ?? 0;
        final newFavorite = Favorite(
          id: favoriteId,
          userId: authProvider.user?.id ?? 0,
          serviceId: service.serviceId,
          addedAt: DateTime.now(),
          service: service,
        );
        if (mounted) {
          setState(() {
            _favorites.add(newFavorite);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Услуга добавлена в избранное',
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
        }
      }
      await _loadFavorites();
    } catch (e) {
      print('Toggle favorite error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка: $e',
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final isSearchActive = _searchController.text.isNotEmpty;
    if (isSearchActive != _isSearchMode) {
      setState(() {
        _isSearchMode = isSearchActive;
      });
      _loadServices(reset: true);
    }
  }

  Future<void> _loadServices({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      if (reset) {
        _services.clear();
        _page = 1;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      List<Service> newServices;
      if (_isSearchMode) {
        newServices = await ApiService.getServices(
          search: _searchController.text,
          categoryId: _selectedCategory != null &&
              _selectedCategory!.categoryId != 0
              ? _selectedCategory!.categoryId
              : null,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          location: _selectedLocation != null && _selectedLocation != 'Все'
              ? _selectedLocation
              : null,
          page: _page,
          pageSize: 10,
        );
      } else if (authProvider.isAuthenticated && authProvider.token != null) {
        newServices = await ApiService.getRecommendedServices(
          search: null,
          categoryId: _selectedCategory != null &&
              _selectedCategory!.categoryId != 0
              ? _selectedCategory!.categoryId
              : null,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          location: _selectedLocation != null && _selectedLocation != 'Все'
              ? _selectedLocation
              : null,
          page: _page,
          pageSize: 10,
          token: authProvider.token!,
        );
      } else {
        newServices = await ApiService.getServices(
          search: null,
          categoryId: _selectedCategory != null &&
              _selectedCategory!.categoryId != 0
              ? _selectedCategory!.categoryId
              : null,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          location: _selectedLocation != null && _selectedLocation != 'Все'
              ? _selectedLocation
              : null,
          page: _page,
          pageSize: 10,
        );
      }

      if (mounted) {
        setState(() {
          _services.addAll(newServices);
          if (newServices.isNotEmpty) _page++; // Увеличиваем страницу только если данные есть
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка загрузки: $e',
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    _minPriceController.text = _minPrice?.toString() ?? '';
    _maxPriceController.text = _maxPrice?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: Color(0xFF7B3BEA).withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              padding: EdgeInsets.all(24.0),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Фильтры',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Категория',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B3BEA),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFF7B3BEA).withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Category>(
                              isExpanded: true,
                              value: _selectedCategory ?? _categories[0],
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedCategory = value;
                                });
                              },
                              style: TextStyle(color: Color(0xFF1A1A1A)),
                              dropdownColor: Color(0xFFF8F7FC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Цена (₸)',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B3BEA),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                decoration: InputDecoration(
                                  labelText: 'Мин',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    color: Color(0xFFB0B0B0),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFF8F7FC).withOpacity(0.9),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFF7B3BEA).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFF7B3BEA),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    _minPrice = double.tryParse(value);
                                  });
                                },
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                decoration: InputDecoration(
                                  labelText: 'Макс',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    color: Color(0xFFB0B0B0),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFF8F7FC).withOpacity(0.9),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFF7B3BEA).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFF7B3BEA),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    _maxPrice = double.tryParse(value);
                                  });
                                },
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Местоположение',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B3BEA),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFF7B3BEA).withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedLocation ?? 'Все',
                              items: _locations.map((location) {
                                return DropdownMenuItem(
                                  value: location,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Text(
                                      location,
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 14,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedLocation = value;
                                });
                              },
                              style: TextStyle(color: Color(0xFF1A1A1A)),
                              dropdownColor: Color(0xFFF8F7FC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = _categories[0];
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _selectedLocation = null;
                                  _minPriceController.clear();
                                  _maxPriceController.clear();
                                });
                                Navigator.pop(context);
                                _loadServices(reset: true);
                              },
                              child: Text(
                                'Сбросить',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: Color(0xFFB0B0B0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _minPrice =
                                      double.tryParse(_minPriceController.text);
                                  _maxPrice =
                                      double.tryParse(_maxPriceController.text);
                                });
                                Navigator.pop(context);
                                _loadServices(reset: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7B3BEA),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                elevation: 0,
                              ),
                              child: Text(
                                'Применить',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController, // Подключаем контроллер
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: Color(0xFFF8F7FC),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск услуг',
                            hintStyle: TextStyle(
                              fontFamily: 'Roboto',
                              color: Color(0xFFB0B0B0),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF8F7FC).withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(
                                color: Color(0xFF7B3BEA).withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(
                                color: Color(0xFF7B3BEA),
                                width: 1,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Color(0xFF7B3BEA),
                              size: 20,
                            ),
                          ),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                          onSubmitted: (_) => _loadServices(reset: true),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showFilterDialog,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF7B3BEA), Color(0xFF9B59B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              toolbarHeight: 68.0,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  _isSearchMode
                      ? 'Результаты поиска'
                      : (Provider.of<AuthProvider>(context).isAuthenticated
                      ? 'Рекомендации'
                      : 'Все услуги'),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 85.0,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == _services.length && _isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7B3BEA),
                        ),
                      );
                    }
                    final service = _services[index];
                    final imageUrl = service.serviceImages.isNotEmpty
                        ? service.serviceImages
                        .firstWhere((img) => img.isPrimary,
                        orElse: () => service.serviceImages.first)
                        .imageUrl
                        : null;
                    final isFavorited =
                    _favorites.any((f) => f.serviceId == service.serviceId);

                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                  ServiceDetailScreen(
                                      serviceId: service.serviceId),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.95, end: 1.0)
                                        .animate(
                                      CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic),
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration: Duration(milliseconds: 400),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFF7B3BEA).withOpacity(0.2),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF7B3BEA).withOpacity(0.15),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: imageUrl != null
                                        ? CachedNetworkImage(
                                      imageUrl:
                                      '${ApiService.baseImageUrl}$imageUrl',
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF7B3BEA),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Image.asset(
                                            'assets/images/placeholder.png',
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                    )
                                        : Image.asset(
                                      'assets/images/placeholder.png',
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => _toggleFavorite(service),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF7B3BEA)
                                                  .withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isFavorited
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorited
                                              ? Color(0xFF7B3BEA)
                                              : Color(0xFFB0B0B0),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.price != null
                                                ? '${service.price} \u20B8'
                                                : 'Не указана',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF7B3BEA),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            service.title,
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          Text(
                                            service.categoryName ??
                                                'Без категории',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 12,
                                              color: Color(0xFFB0B0B0),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 12,
                                              color: Color(0xFFB0B0B0),
                                            ),
                                          ),
                                          Text(
                                            service.location ?? 'Не указано',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontSize: 12,
                                              color: Color(0xFFB0B0B0),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _services.length + (_isLoading ? 1 : 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}