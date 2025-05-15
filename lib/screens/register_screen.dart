import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/screens/login_screen.dart';
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Клиентская валидация
      if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
        throw Exception('Введите корректный email');
      }
      if (_passwordController.text.isEmpty) {
        throw Exception('Введите пароль');
      }
      if (_passwordController.text.length < 6) {
        throw Exception('Пароль должен быть не менее 6 символов');
      }
      if (_firstNameController.text.isEmpty) {
        throw Exception('Введите имя');
      }
      if (_lastNameController.text.isEmpty) {
        throw Exception('Введите фамилию');
      }

      await Provider.of<AuthProvider>(context, listen: false).register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
      );
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Парсим серверную ошибку
      if (errorMessage.contains('Ошибка запроса: 400')) {
        try {
          // Предполагаем, что AuthProvider возвращает JSON ошибки в сообщении
          final errorJson = jsonDecode(errorMessage.split('Ошибка запроса: 400 ')[1]);
          final errors = errorJson['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.containsKey('Password')) {
            final passwordErrors = errors['Password'] as List<dynamic>;
            if (passwordErrors.any((err) => err.toString().contains('minimum length of \'6\''))) {
              errorMessage = 'Пароль должен быть не менее 6 символов';
            } else {
              errorMessage = passwordErrors.first.toString();
            }
          } else {
            errorMessage = 'Ошибка регистрации. Проверьте введённые данные.';
          }
        } catch (_) {
          errorMessage = 'Ошибка регистрации. Проверьте введённые данные.';
        }
      }
      setState(() {
        _error = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    final maxContentWidth = isLargeScreen ? 400.0 : screenWidth * 0.9;
    final titleFontSize = isSmallScreen ? 32.0 : 36.0;
    final buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final spacing = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Отключаем кнопку "Назад"
        backgroundColor: Colors.transparent, // Прозрачный аппбар
        elevation: 0, // Убираем тень
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7B3BEA),
        ),
      )
          : Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Регистрация',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacing * 2.5),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Color(0xFF7B3BEA)),
                      prefixIcon: Icon(Icons.email, color: Color(0xFF7B3BEA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      labelStyle: TextStyle(color: Color(0xFF7B3BEA)),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF7B3BEA)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Color(0xFF7B3BEA),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: _obscurePassword,
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      labelStyle: TextStyle(color: Color(0xFF7B3BEA)),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF7B3BEA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Фамилия',
                      labelStyle: TextStyle(color: Color(0xFF7B3BEA)),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF7B3BEA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: spacing),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Телефон (опционально)',
                      labelStyle: TextStyle(color: Color(0xFF7B3BEA)),
                      prefixIcon: Icon(Icons.phone, color: Color(0xFF7B3BEA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF7B3BEA), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(top: spacing * 0.75),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontFamily: 'Roboto',
                          fontSize: isSmallScreen ? 13.0 : 14.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: spacing * 2),
                  Container(
                    width: maxContentWidth * 0.9,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: Color(0xFF7B3BEA),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF7B3BEA).withOpacity(0.25),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _register,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Text(
                            'Зарегистрироваться',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: isSmallScreen ? 16.0 : 18.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(-1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration: Duration(milliseconds: 800),
                        ),
                      );
                    },
                    child: Text(
                      'Вернуться к входу',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        color: Color(0xFF7B3BEA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}