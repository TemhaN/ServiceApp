import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:service_app/models/user.dart';
import 'package:service_app/models/service.dart';
import 'package:service_app/models/favorite.dart';
import 'package:service_app/models/review.dart';
import 'package:service_app/screens/full_screen_image.dart';
import 'package:service_app/screens/service_edit_screen.dart';
import 'package:service_app/services/api_service.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:service_app/screens/chat_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;

  ServiceDetailScreen({required this.serviceId});

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> with SingleTickerProviderStateMixin {
  Service? _service;
  User? _author;
  List<Favorite> _favorites = [];
  List<Review> _reviews = [];
  List<Service> _otherServices = [];
  List<Service> _similarServices = [];
  bool _isLoading = true;
  bool _isLoadingAuthor = false;
  bool _isLoadingReviews = false;
  bool _isLoadingOtherServices = false;
  bool _isLoadingSimilarServices = false;
  bool _isTogglingFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double _favoriteButtonScale = 1.0;
  double _shareButtonScale = 1.0;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadService();
    _loadFavorites();
    _loadReviews();
  }

  Future<void> _loadService() async {
    try {
      final service = await ApiService.getService(widget.serviceId);
      setState(() {
        _service = service;
        _isLoading = false;
      });
      if (service != null) {
        _loadAuthor(service.userId);
        _loadOtherServices(service.userId);
        _loadSimilarServices(service.serviceId);
      }
    } catch (e) {
      _showSnackBar('Ошибка загрузки услуги: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAuthor(int userId) async {
    setState(() {
      _isLoadingAuthor = true;
    });
    try {
      final author = await ApiService.getUserById(userId);
      setState(() {
        _author = author;
        _isLoadingAuthor = false;
      });
    } catch (e) {
      print('Ошибка загрузки автора: $e');
      setState(() {
        _isLoadingAuthor = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews = await ApiService.getReviews(widget.serviceId);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Ошибка загрузки отзывов: $e');
      _showSnackBar('Ошибка загрузки отзывов: $e');
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadOtherServices(int userId) async {
    setState(() {
      _isLoadingOtherServices = true;
    });
    try {
      final services = await ApiService.getOtherUserServices(
        userId: userId,
        excludeServiceId: widget.serviceId,
        page: 1,
        pageSize: 10,
      );
      setState(() {
        _otherServices = services;
        _isLoadingOtherServices = false;
      });
    } catch (e) {
      print('Ошибка загрузки других услуг: $e');
      setState(() {
        _isLoadingOtherServices = false;
      });
    }
  }

  Future<void> _loadSimilarServices(int serviceId) async {
    setState(() {
      _isLoadingSimilarServices = true;
    });
    try {
      final services = await ApiService.getSimilarServices(
        serviceId: serviceId,
        page: 1,
        pageSize: 10,
      );
      setState(() {
        _similarServices = services;
        _isLoadingSimilarServices = false;
      });
    } catch (e) {
      print('Ошибка загрузки похожих услуг: $e');
      setState(() {
        _isLoadingSimilarServices = false;
      });
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
      setState(() {
        _favorites = favorites;
        print('Favorites loaded: ${_favorites.length}');
      });
    } catch (e) {
      _showSnackBar('Ошибка загрузки избранного: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    setState(() {
      _isTogglingFavorite = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      print('Toggle favorite failed: not authenticated or no token');
      _showSnackBar('Войдите, чтобы добавить в избранное');
      setState(() {
        _isTogglingFavorite = false;
      });
      return;
    }

    try {
      final isFavorited = _favorites.any((f) => f.serviceId == _service!.serviceId);
      print('Toggling favorite for serviceId: ${_service!.serviceId}, isFavorited: $isFavorited');
      if (isFavorited) {
        final favorite = _favorites.firstWhere((f) => f.serviceId == _service!.serviceId);
        await ApiService.removeFavorite(favorite.id, authProvider.token!);
        setState(() {
          _favorites.removeWhere((f) => f.serviceId == _service!.serviceId);
        });
        _showSnackBar('Услуга удалена из избранного');
      } else {
        final response = await ApiService.addFavorite(_service!.serviceId, authProvider.token!);
        final favoriteId = response['favoriteId'] as int? ?? 0;
        final newFavorite = Favorite(
          id: favoriteId,
          userId: authProvider.user!.id,
          serviceId: _service!.serviceId,
          addedAt: DateTime.now(),
          service: _service!,
        );
        setState(() {
          _favorites.add(newFavorite);
        });
        _showSnackBar('Услуга добавлена в избранное');
      }
      await _loadFavorites();
    } catch (e) {
      print('Toggle favorite error: $e');
      _showSnackBar('Ошибка: $e');
    } finally {
      setState(() {
        _isTogglingFavorite = false;
      });
    }
  }

  Future<void> _shareService() async {
    if (_service == null) {
      print('Шаринг невозможен: услуга не загружена');
      return;
    }
    try {
      final serviceUrl = '${ApiService.baseUrl}/services/${_service!.serviceId}';
      final shareText = 'Посмотрите эту услугу: ${_service!.title}\n$serviceUrl';
      print('Шаринг услуги: ${_service!.title}, URL: $serviceUrl');
      await Share.share(
        shareText,
        subject: _service!.title,
      );
    } catch (e) {
      print('Ошибка шаринга: $e');
      _showSnackBar('Ошибка шаринга: $e');
    }
  }

  void _showContactOptions() {
    if (_author == null || _author!.phone == null) {
      print('Контактная информация недоступна: _author=${_author}, phone=${_author?.phone}');
      _showSnackBar('Контактная информация недоступна');
      return;
    }

    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF7B3BEA).withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Связаться с ${_author!.firstName} ${_author!.lastName}',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.chat, color: Color(0xFF7B3BEA)),
                    title: Text(
                      'Написать в чат',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    onTap: () async {
                      print('Выбрано: Написать в чат');
                      Navigator.pop(bottomSheetContext);
                      final authProvider = Provider.of<AuthProvider>(parentContext, listen: false);
                      if (!authProvider.isAuthenticated || authProvider.token == null) {
                        if (mounted) {
                          _showSnackBar('Войдите, чтобы начать чат');
                        }
                        return;
                      }

                      showDialog(
                        context: parentContext,
                        barrierDismissible: false,
                        builder: (context) => Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA))),
                      );

                      try {
                        final chat = await ApiService.createChat(_service!.serviceId, authProvider.token!);
                        Navigator.pop(parentContext);
                        if (mounted) {
                          Navigator.push(
                            parentContext,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(chat: chat),
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.pop(parentContext);
                        if (e.toString().contains('Чат уже существует')) {
                          try {
                            final chat = await ApiService.getChatByService(_service!.serviceId, authProvider.token!);
                            if (mounted) {
                              Navigator.push(
                                parentContext,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(chat: chat),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              _showSnackBar('Ошибка получения чата: $e');
                            }
                          }
                        } else {
                          if (mounted) {
                            _showSnackBar('Ошибка создания чата: $e');
                          }
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: Color(0xFF7B3BEA)),
                    title: Text(
                      'Позвонить',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    onTap: () async {
                      print('Выбрано: Позвонить, номер: ${_author!.phone}');
                      Navigator.pop(bottomSheetContext);
                      final phoneNumber = _author!.phone!;
                      final Uri phoneUri = Uri.parse('tel:$phoneNumber');
                      try {
                        print('Проверка возможности звонка: $phoneUri');
                        if (await canLaunchUrl(phoneUri)) {
                          print('Запуск звонка: $phoneUri');
                          await launchUrl(phoneUri);
                        } else {
                          print('Не удалось открыть приложение телефона для номера: $phoneNumber');
                          if (mounted) {
                            _showSnackBar('Не удалось открыть приложение телефона');
                          }
                        }
                      } catch (e) {
                        print('Ошибка звонка: $e');
                        if (mounted) {
                          _showSnackBar('Ошибка звонка: $e');
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.message, color: Color(0xFF7B3BEA)),
                    title: Text(
                      'Написать в WhatsApp',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    onTap: () async {
                      print('Выбрано: Написать в WhatsApp, исходный номер: ${_author!.phone}');
                      Navigator.pop(bottomSheetContext);
                      final phoneNumber = _author!.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                      print('Очищенный номер для WhatsApp: $phoneNumber');
                      final Uri whatsappAppUri = Uri.parse('whatsapp://send?phone=$phoneNumber');
                      final Uri whatsappWebUri = Uri.parse('https://wa.me/$phoneNumber');
                      try {
                        print('Проверка наличия WhatsApp: $whatsappAppUri');
                        if (await canLaunchUrl(whatsappAppUri)) {
                          print('Запуск WhatsApp приложения: $whatsappAppUri');
                          await launchUrl(whatsappAppUri);
                        } else {
                          print('WhatsApp не установлен, открытие в браузере: $whatsappWebUri');
                          if (mounted) {
                            _showSnackBar('WhatsApp не установлен, открытие в браузере');
                          }
                          print('Проверка возможности открытия браузера: $whatsappWebUri');
                          if (await canLaunchUrl(whatsappWebUri)) {
                            print('Запуск браузера: $whatsappWebUri');
                            await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
                          } else {
                            print('Не удалось открыть WhatsApp в браузере');
                            if (mounted) {
                              _showSnackBar('Не удалось открыть WhatsApp в браузере');
                            }
                          }
                        }
                      } catch (e) {
                        print('Ошибка WhatsApp: $e');
                        if (mounted) {
                          _showSnackBar('Ошибка WhatsApp: $e');
                        }
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        print('Выбрано: Отмена');
                        Navigator.pop(bottomSheetContext);
                      },
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog({Review? review}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      _showSnackBar('Войдите, чтобы оставить отзыв');
      return;
    }

    int rating = review?.rating ?? 1;
    final commentController = TextEditingController(text: review?.comment);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  review == null ? 'Добавить отзыв' : 'Редактировать отзыв',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Оценка:',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          labelText: 'Комментарий (необязательно)',
                          labelStyle: TextStyle(
                            fontFamily: 'Roboto',
                            color: Color(0xFFB0B0B0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFF7B3BEA).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFF7B3BEA).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFF7B3BEA),
                              width: 1,
                            ),
                          ),
                        ),
                        maxLength: 500,
                        maxLines: 3,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFF7B3BEA),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        if (review == null) {
                          await ApiService.createReview(
                            serviceId: widget.serviceId,
                            rating: rating,
                            comment: commentController.text.isEmpty ? null : commentController.text,
                          );
                          _showSnackBar('Отзыв добавлен');
                        } else {
                          await ApiService.updateReview(
                            id: review.id,
                            rating: rating,
                            comment: commentController.text.isEmpty ? null : commentController.text,
                          );
                          _showSnackBar('Отзыв обновлён');
                        }
                        await _loadReviews();
                        Navigator.pop(context);
                      } catch (e) {
                        _showSnackBar('Ошибка: $e');
                      }
                    },
                    child: Text(
                      review == null ? 'Добавить' : 'Сохранить',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFF7B3BEA),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteReview(int reviewId) async {
    try {
      await ApiService.deleteReview(reviewId);
      _showSnackBar('Отзыв удалён');
      await _loadReviews();
    } catch (e) {
      _showSnackBar('Ошибка удаления отзыва: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthor = authProvider.user != null && _service != null && _service!.userId == authProvider.user!.id;
    final isFavorited = _favorites.any((f) => f.serviceId == _service?.serviceId);
    final userReview = _reviews.firstWhere(
          (r) => r.userId == authProvider.user?.id,
      orElse: () => Review(id: 0, serviceId: 0, userId: 0, rating: 0, createdAt: DateTime.now()),
    );

    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.0),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              _service?.title ?? 'Детали услуги',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xFF7B3BEA).withOpacity(0.8),
            elevation: 0,
            actions: [
              GestureDetector(
                onTapDown: (_) => setState(() => _favoriteButtonScale = 0.9),
                onTapUp: (_) {
                  setState(() => _favoriteButtonScale = 1.0);
                  _toggleFavorite();
                },
                onTapCancel: () => setState(() => _favoriteButtonScale = 1.0),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.identity()..scale(_favoriteButtonScale),
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (_) => setState(() => _shareButtonScale = 0.9),
                onTapUp: (_) {
                  setState(() => _shareButtonScale = 1.0);
                  _shareService();
                },
                onTapCancel: () => setState(() => _shareButtonScale = 1.0),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.identity()..scale(_shareButtonScale),
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.share,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7B3BEA).withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.3),
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
          : _service == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(0xFFB0B0B0)),
            SizedBox(height: 16),
            Text(
              'Услуга не найдена',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                color: Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _service!.title,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_service!.price != null ? "${_service!.price} \u20B8" : "Не указана"}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B3BEA),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Категория: ${_service!.categoryName ?? 'Без категории'}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDescription(),
                    SizedBox(height: 16),
                    _buildDetails(),
                    SizedBox(height: 24),
                    _buildAuthorSection(),
                    SizedBox(height: 24),
                    _buildReviewsSection(authProvider, userReview),
                    SizedBox(height: 24),
                    _buildOtherServices(),
                    SizedBox(height: 24),
                    _buildSimilarServices(),
                    SizedBox(height: 24),
                    Center(
                      child: isAuthor
                          ? _buildButton(
                        text: 'Редактировать',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceEditScreen(service: _service!),
                            ),
                          ).then((_) => _loadService());
                        },
                      )
                          : Column(
                        children: [
                          _buildButton(
                            text: 'Связаться',
                            onPressed: _showContactOptions,
                          ),
                          if (!isAuthor) SizedBox(height: 12),
                          if (!isAuthor)
                            _buildButton(
                              text: userReview.id != 0 ? 'Редактировать отзыв' : 'Оставить отзыв',
                              onPressed: () {
                                if (userReview.id != 0) {
                                  _showReviewDialog(review: userReview);
                                } else {
                                  _showReviewDialog();
                                }
                              },
                              gradient: LinearGradient(
                                colors: [Color(0xFF9B59B6), Color(0xFF7B3BEA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    LinearGradient? gradient,
  }) {
    double _scale = 1.0;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.95),
          onTapUp: (_) {
            setState(() => _scale = 1.0);
            onPressed();
          },
          onTapCancel: () => setState(() => _scale = 1.0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_scale),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
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
              text,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel() {
    if (_service!.serviceImages.isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: 250.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7B3BEA).withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Image.asset(
            'assets/images/placeholder.png',
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final images = _service!.serviceImages;
    int initialPage = 0;
    for (int i = 0; i < images.length; i++) {
      if (images[i].isPrimary) {
        initialPage = i;
        break;
      }
    }
    setState(() {
      _currentCarouselIndex = initialPage;
    });

    return CarouselSlider(
      options: CarouselOptions(
        height: 250.0,
        initialPage: initialPage,
        autoPlay: images.length > 1,
        autoPlayInterval: Duration(seconds: 7),
        autoPlayAnimationDuration: Duration(milliseconds: 1200),
        enlargeCenterPage: true,
        viewportFraction: 1.0,
        enableInfiniteScroll: images.length > 1,
        scrollPhysics: images.length <= 1 ? NeverScrollableScrollPhysics() : ClampingScrollPhysics(),
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      items: images.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        final heroTag = 'service_image_${_service!.serviceId}_$index'; // Уникальный тег

        return Builder(
          builder: (BuildContext context) {
            final imageWidget = CachedNetworkImage(
              imageUrl: '${ApiService.baseImageUrl}${image.imageUrl}',
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA))),
              errorWidget: (context, url, error) {
                print('Image load error: $error, URL: $url');
                return Image.asset(
                  'assets/images/placeholder.png',
                  fit: BoxFit.cover,
                );
              },
            );

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7B3BEA).withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                child: GestureDetector(
                  onTap: () {
                    print('Opening full screen image: ${ApiService.baseImageUrl}${image.imageUrl}');
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: false, // Отключаем закрытие по клику на фон (управляется внутри)
                      barrierColor: Colors.transparent, // Прозрачный барьер для видимости фона
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return FullScreenImage(
                          imageUrl: '${ApiService.baseImageUrl}${image.imageUrl}',
                          heroTag: heroTag,
                        );
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        return FadeTransition(
                          opacity: anim1,
                          child: child,
                        );
                      },
                    );
                  },
                  child: Hero(
                    tag: heroTag,
                    child: imageWidget,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Описание',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _service!.description ?? 'Описание отсутствует',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF7B3BEA), size: 20),
            Text(
              'Местоположение: ${_service!.location ?? "Не указано"}',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFFB0B0B0), size: 20),
            SizedBox(width: 8),
            Text(
              'Создано: ${_service!.createdAt != null ? _service!.createdAt!.toLocal().toString().split('.')[0] : "Не указано"}',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          'Об авторе',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        _isLoadingAuthor
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
            : _author == null
            ? Text(
          'Информация об авторе недоступна',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        )
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF7B3BEA),
              radius: 24,
              child: Text(
                _author!.firstName.isNotEmpty ? _author!.firstName[0] : '?',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_author!.firstName} ${_author!.lastName}',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (_author!.phone != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, color: Color(0xFF7B3BEA), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Телефон: ${_author!.phone}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Color(0xFFB0B0B0), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Зарегистрирован: ${_author!.createdAt != null ? _author!.createdAt!.toLocal().toString().split('.')[0] : "Не указано"}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection(AuthProvider authProvider, Review userReview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Отзывы',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (!authProvider.isAuthenticated || userReview.id == 0)
              TextButton(
                onPressed: () => _showReviewDialog(),
                child: Text(
                  'Оставить отзыв',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF7B3BEA),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        _isLoadingReviews
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
            : _reviews.isEmpty
            ? Text(
          'Отзывы отсутствуют',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            final review = _reviews[index];
            final isUserReview = authProvider.user != null && review.userId == authProvider.user!.id;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF7B3BEA).withOpacity(0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7B3BEA).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.user?.firstName ?? 'Аноним',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (review.comment != null)
                      Text(
                        review.comment!,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    SizedBox(height: 8),
                    Text(
                      'Дата: ${review.createdAt.toLocal().toString().split('.')[0]}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                    if (isUserReview) ...[
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _showReviewDialog(review: review),
                            child: Text(
                              'Редактировать',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Color(0xFF7B3BEA),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _deleteReview(review.id),
                            child: Text(
                              'Удалить',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOtherServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Другие услуги этого пользователя',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        _isLoadingOtherServices
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
            : _otherServices.isEmpty
            ? Text(
          'Нет других услуг',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _otherServices.length,
          itemBuilder: (context, index) {
            final service = _otherServices[index];
            final imageUrl = service.serviceImages.isNotEmpty
                ? service.serviceImages
                .firstWhere((img) => img.isPrimary, orElse: () => service.serviceImages.first)
                .imageUrl
                : null;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF7B3BEA).withOpacity(0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7B3BEA).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(serviceId: service.serviceId),
                    ),
                  );
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: '${ApiService.baseImageUrl}$imageUrl',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(color: Color(0xFF7B3BEA)),
                    errorWidget: (context, url, error) => Image.asset('assets/images/placeholder.png'),
                  )
                      : Image.asset(
                    'assets/images/placeholder.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  service.title,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                subtitle: Text(
                  'Цена: ${service.price != null ? "${service.price} KZT" : "Не указана"}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSimilarServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Похожие услуги',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        _isLoadingSimilarServices
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
            : _similarServices.isEmpty
            ? Text(
          'Нет похожих услуг',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _similarServices.length,
          itemBuilder: (context, index) {
            final service = _similarServices[index];
            final imageUrl = service.serviceImages.isNotEmpty
                ? service.serviceImages
                .firstWhere((img) => img.isPrimary, orElse: () => service.serviceImages.first)
                .imageUrl
                : null;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF7B3BEA).withOpacity(0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7B3BEA).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(serviceId: service.serviceId),
                    ),
                  );
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: '${ApiService.baseImageUrl}$imageUrl',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(color: Color(0xFF7B3BEA)),
                    errorWidget: (context, url, error) => Image.asset('assets/images/placeholder.png'),
                  )
                      : Image.asset(
                    'assets/images/placeholder.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  service.title,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                subtitle: Text(
                  'Цена: ${service.price != null ? "${service.price} KZT" : "Не указана"}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}