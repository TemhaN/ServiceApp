import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/models/service.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/screens/login_screen.dart';
import 'package:service_app/screens/service_detail_screen.dart';
import 'package:service_app/screens/service_edit_screen.dart';
import 'package:service_app/screens/service_management_screen.dart';
import 'package:service_app/screens/help_screen.dart';
import 'package:service_app/screens/about_screen.dart';
import 'package:service_app/screens/settings_screen.dart';
import 'package:service_app/services/api_service.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  List<Service> _services = [];
  bool _isLoading = true;
  bool _isServicesLoading = true;
  String? _error;
  String? _servicesError;
  late AnimationController _animationController;
  late Animation<double> _appBarSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUserServices();

    // Инициализация анимации для AppBar
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

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user == null) {
        await auth.loadProfile();
      }
      if (auth.user == null) {
        throw Exception('Пользователь не найден');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Выход из аккаунта',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            content: Text(
              'Вы уверены, что хотите выйти из аккаунта?',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF1A1A1A),
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
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                child: Text(
                  'Выйти',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showSnackBar('Ошибка выхода: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserServices() async {
    setState(() {
      _isServicesLoading = true;
      _servicesError = null;
    });

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Не авторизован');

      final services = await ApiService.getServices(
        page: 1,
        pageSize: 100,
      );
      setState(() {
        _services = services
            .where((s) =>
        s.userId == Provider.of<AuthProvider>(context, listen: false).user!.id)
            .take(3)
            .toList();
      });
    } catch (e) {
      setState(() {
        _servicesError = e.toString();
      });
    } finally {
      setState(() {
        _isServicesLoading = false;
      });
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
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
      extendBody: true, // Контент прокручивается под островком
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.0),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _appBarSlideAnimation.value * 64.0),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                child: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Профиль',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Color(0xFF7B3BEA).withOpacity(0.8),
                  elevation: 0,
                  centerTitle: false,
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
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
            : auth.user == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFB0B0B0),
              ),
              SizedBox(height: 16),
              Text(
                _error ?? 'Не удалось загрузить профиль',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Color(0xFFB0B0B0),
                ),
              ),
              SizedBox(height: 16),
              _buildButton(
                text: 'Попробовать снова',
                onPressed: _loadProfile,
              ),
            ],
          ),
        )
            : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFF7B3BEA),
                            radius: 30,
                            child: Text(
                              auth.user!.firstName.isNotEmpty
                                  ? auth.user!.firstName[0]
                                  : '?',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Привет, ${auth.user!.firstName}!',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  auth.user!.email,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    color: Color(0xFFB0B0B0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 300),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: _buildButton(
                        text: 'Создать новую услугу',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceEditScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        'Мои услуги',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _isServicesLoading
                ? SliverToBoxAdapter(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7B3BEA),
                ),
              ),
            )
                : _servicesError != null
                ? SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  _servicesError!,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            )
                : _services.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF7B3BEA)
                          .withOpacity(0.3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF7B3BEA)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Услуги не найдены',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ),
                ),
              ),
            )
                : SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio:
                  1.0, // Уменьшил высоту карточек
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final service = _services[index];
                    final imageUrl = service
                        .serviceImages.isNotEmpty
                        ? service.serviceImages
                        .firstWhere(
                          (img) => img.isPrimary,
                      orElse: () =>
                      service
                          .serviceImages
                          .first,
                    )
                        .imageUrl
                        : null;

                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration:
                      Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceDetailScreen(
                                    serviceId:
                                    service.serviceId,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(
                                16),
                            border: Border.all(
                              color: Color(0xFF7B3BEA)
                                  .withOpacity(0.2),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF7B3BEA)
                                    .withOpacity(0.15),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              ClipRRect(
                                borderRadius:
                                BorderRadius
                                    .vertical(
                                  top: Radius.circular(
                                      16),
                                ),
                                child: imageUrl != null
                                    ? CachedNetworkImage(
                                  imageUrl:
                                  '${ApiService.baseImageUrl}$imageUrl',
                                  height:
                                  100, // Уменьшил высоту
                                  width: double
                                      .infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context,
                                      url) =>
                                      Center(
                                        child:
                                        CircularProgressIndicator(
                                          color: Color(
                                              0xFF7B3BEA),
                                        ),
                                      ),
                                  errorWidget: (context,
                                      url,
                                      error) =>
                                      Image.asset(
                                        'assets/images/placeholder.png',
                                        height: 100,
                                        width: double
                                            .infinity,
                                        fit: BoxFit
                                            .cover,
                                      ),
                                )
                                    : Image.asset(
                                  'assets/images/placeholder.png',
                                  height:
                                  100, // Уменьшил высоту
                                  width: double
                                      .infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                  EdgeInsets.all(
                                      10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            service
                                                .title,
                                            style:
                                            TextStyle(
                                              fontFamily:
                                              'Roboto',
                                              fontSize:
                                              14,
                                              fontWeight:
                                              FontWeight
                                                  .w600,
                                              color: Color(
                                                  0xFF1A1A1A),
                                            ),
                                            maxLines:
                                            2,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                          ),
                                          SizedBox(
                                              height:
                                              4),
                                          Text(
                                            service.price !=
                                                null
                                                ? '${service.price!.toInt()} \u20B8'
                                                : 'Не указана',
                                            style:
                                            TextStyle(
                                              fontFamily:
                                              'Roboto',
                                              fontSize:
                                              20,
                                              fontWeight:
                                              FontWeight
                                                  .w600,
                                              color: Color(
                                                  0xFF7B3BEA),
                                            ),
                                            maxLines:
                                            1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        service
                                            .categoryName ??
                                            'Без категории',
                                        style:
                                        TextStyle(
                                          fontFamily:
                                          'Roboto',
                                          fontSize:
                                          12,
                                          color: Color(
                                              0xFFB0B0B0),
                                        ),
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
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
                  childCount: _services.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 300),
                  child: _buildButton(
                    text: 'Посмотреть все услуги',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceManagementScreen(),
                        ),
                      );
                    },
                    gradient: LinearGradient(
                      colors: [Color(0xFF9B59B6), Color(0xFF7B3BEA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        'Настройки и поддержка',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: ListTile(
                        leading: Icon(
                          Icons.settings,
                          color: Color(0xFF7B3BEA),
                          size: 24,
                        ),
                        title: Text(
                          'Настройки',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(
                      color: Color(0xFF7B3BEA).withOpacity(0.2),
                      thickness: 0.5,
                      height: 1,
                    ),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: ListTile(
                        leading: Icon(
                          Icons.help,
                          color: Color(0xFF7B3BEA),
                          size: 24,
                        ),
                        title: Text(
                          'Помощь',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HelpScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(
                      color: Color(0xFF7B3BEA).withOpacity(0.2),
                      thickness: 0.5,
                      height: 1,
                    ),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: ListTile(
                        leading: Icon(
                          Icons.info,
                          color: Color(0xFF7B3BEA),
                          size: 24,
                        ),
                        title: Text(
                          'О приложении',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AboutScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(
                      color: Color(0xFF7B3BEA).withOpacity(0.2),
                      thickness: 0.5,
                      height: 1,
                    ),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 24,
                        ),
                        title: Text(
                          'Выйти из аккаунта',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        onTap: _showLogoutConfirmation,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    16.0 +
                    MediaQuery.of(context).padding.bottom,
              ),
            ),
          ],
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
}