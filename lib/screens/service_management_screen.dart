import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/models/service.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/screens/service_detail_screen.dart';
import 'package:service_app/screens/service_edit_screen.dart';
import 'package:service_app/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class ServiceManagementScreen extends StatefulWidget {
  @override
  _ServiceManagementScreenState createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> with SingleTickerProviderStateMixin {
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _appBarSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadServices();

    // Инициализация анимации для AppBar (как в FavoritesScreen)
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _appBarSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.token == null) {
        throw Exception('Not authenticated');
      }

      final services = await ApiService.getServices(
        page: 1,
        pageSize: 100, // Загружаем все услуги пользователя
      );
      setState(() {
        _services = services.where((s) => s.userId == authProvider.user!.id).toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка загрузки услуг: $e',
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      await ApiService.deleteService(id);
      setState(() {
        _services.removeWhere((s) => s.serviceId == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Услуга удалена',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          elevation: 8,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка удаления услуги: $e',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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

  Future<bool?> _showDeleteDialog(int serviceId, String serviceTitle) async {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Удалить услугу',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Вы уверены, что хотите удалить "$serviceTitle"?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Отмена',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Удалить',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true, // Контент прокручивается под островком
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(76.0),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _appBarSlideAnimation.value * 64.0),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                child: AppBar(
                  automaticallyImplyLeading: true,
                  title: Text(
                    'Мои услуги',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Roboto',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  elevation: 0,
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: _loadServices,
                    ),
                  ],
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
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false, // Контент прокручивается под островком
        child: !authProvider.isAuthenticated
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(height: 12),
              Text(
                'Войдите, чтобы управлять услугами',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : _services.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(height: 12),
              Text(
                'Нет услуг. Добавьте новую!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : GridView.builder(
          padding: EdgeInsets.only(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            bottom: 85.0,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.86,
          ),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            final imageUrl = service.serviceImages.isNotEmpty
                ? service.serviceImages
                .firstWhere((img) => img.isPrimary, orElse: () => service.serviceImages.first)
                .imageUrl
                : null;

            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ServiceDetailScreen(serviceId: service.serviceId),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
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
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            child: imageUrl != null
                                ? CachedNetworkImage(
                              imageUrl: '${ApiService.baseImageUrl}$imageUrl',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
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
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ServiceEditScreen(service: service),
                                      ),
                                    ).then((_) => _loadServices());
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final shouldDelete = await _showDeleteDialog(service.serviceId, service.title);
                                    if (shouldDelete == true) {
                                      await _deleteService(service.serviceId);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.price != null ? '${service.price} \u20B8' : 'Не указана',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    service.title,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
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
                                    service.categoryName ?? 'Без категории',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '•',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    service.location ?? 'Не указано',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        ),
      ),
    );
  }
}