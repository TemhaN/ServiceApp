import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/providers/theme_provider.dart';
import 'package:service_app/screens/login_screen.dart';
import 'package:service_app/services/api_service.dart';
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _appBarSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

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
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      _emailController.text = user.email;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone ?? '';
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).updateProfile(
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Профиль обновлен',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка обновления профиля: $e',
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

  Future<void> _deleteProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.deleteProfile();
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка удаления профиля: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            elevation: 8,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          )
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка выхода: $e',
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

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Редактировать профиль',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Roboto',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Roboto',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Roboto',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Roboto',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Фамилия',
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Roboto',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Roboto',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Телефон',
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Roboto',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Roboto',
                      color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateProfile();
                },
                child: Text(
                  'Сохранить',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          )
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Изменить пароль',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      labelStyle: TextStyle(fontFamily: 'Roboto', color: Color(0xFFB0B0B0)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA).withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                    ),
                    style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF1A1A1A)),
                    obscureText: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Подтвердите пароль',
                      labelStyle: TextStyle(fontFamily: 'Roboto', color: Color(0xFFB0B0B0)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA).withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                    ),
                    style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF1A1A1A)),
                    obscureText: true,
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
                onPressed: () {
                  if (_passwordController.text != _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Пароли не совпадают',
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
                    return;
                  }
                  if (_passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Пароль должен содержать минимум 6 символов',
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
                    return;
                  }
                  Navigator.pop(context);
                  _updateProfile();
                },
                child: Text(
                  'Сохранить',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Color(0xFF7B3BEA),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteProfileConfirmation() {
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
              'Удаление профиля',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            content: Text(
              'Вы уверены, что хотите удалить свой профиль? Это действие нельзя отменить.',
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
                  _deleteProfile();
                },
                child: Text(
                  'Удалить',
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

  void _showThemeSelectionDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Выбрать тему',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'Светлая',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    themeProvider.setTheme(ThemeModeType.light);
                    Navigator.pop(context);
                  },
                  trailing: themeProvider.themeMode == ThemeModeType.light
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                ListTile(
                  title: Text(
                    'Тёмная',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    themeProvider.setTheme(ThemeModeType.dark);
                    Navigator.pop(context);
                  },
                  trailing: themeProvider.themeMode == ThemeModeType.dark
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                ListTile(
                  title: Text(
                    'Системная',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    themeProvider.setTheme(ThemeModeType.system);
                    Navigator.pop(context);
                  },
                  trailing: themeProvider.themeMode == ThemeModeType.system
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          )
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
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
                  automaticallyImplyLeading: true,
                  title: Text(
                    'Настройки',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: Text(
                'Общие настройки',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 12),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: ListTile(
                leading: Icon(
                  Icons.color_lens,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Тема приложения',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  Provider.of<ThemeProvider>(context).themeMode == ThemeModeType.light
                      ? 'Светлая'
                      : Provider.of<ThemeProvider>(context).themeMode == ThemeModeType.dark
                      ? 'Тёмная'
                      : 'Системная',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                onTap: _showThemeSelectionDialog,
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              thickness: 0.5,
              height: 1,
            ),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Уведомления',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Switch(
                  value: true,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Настройка уведомлений пока не реализована',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                  },
                ),
                onTap: () {},
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              thickness: 0.5,
              height: 1,
            ),
            SizedBox(height: 24),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: Text(
                'Управление аккаунтом',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 12),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Редактировать профиль',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: _showEditProfileDialog,
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              thickness: 0.5,
              height: 1,
            ),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: ListTile(
                leading: Icon(
                  Icons.lock,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Изменить пароль',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: _showChangePasswordDialog,
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              thickness: 0.5,
              height: 1,
            ),
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 24,
                ),
                title: Text(
                  'Удалить профиль',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: _showDeleteProfileConfirmation,
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: _showLogoutConfirmation,
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}