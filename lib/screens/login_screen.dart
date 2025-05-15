import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/screens/main_screen.dart';
import 'package:service_app/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
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
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
        throw Exception('Введите корректный email');
      }
      if (_passwordController.text.isEmpty) {
        throw Exception('Введите пароль');
      }

      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text,
        _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    final maxContentWidth = isLargeScreen ? 400.0 : screenWidth * 0.9;
    final titleFontSize = isSmallScreen ? 32.0 : 36.0;
    final buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final spacing = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Color(0xFFF8F7FC),
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
                    'Вход',
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
                        onTap: _login,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Text(
                            'Войти',
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
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => RegisterScreen(),
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
                    },
                    child: Text(
                      'Нет аккаунта? Зарегистрироваться',
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