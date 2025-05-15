import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/screens/login_screen.dart';
import 'package:service_app/screens/main_screen.dart';
import 'package:animated_background/animated_background.dart';

class RootScreen extends StatefulWidget {
  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  bool _isInitializing = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;
  late Animation<Alignment> _gradientBegin;
  late Animation<Alignment> _gradientEnd;

  @override
  void initState() {
    super.initState();
    // Инициализация анимаций
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8), // Медленная и плавная анимация
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _logoScaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));
    _pulseAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Анимация цветов градиента
    _gradientColor1 = ColorTween(
      begin: Color(0xFF7B3BEA), // Фиолетовый
      end: Color(0xFFB14DFF), // Мягкий розово-фиолетовый
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    _gradientColor2 = ColorTween(
      begin: Color(0xFFB14DFF),
      end: Color(0xFF7B3BEA),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    // Анимация углов градиента (всегда начинается снизу)
    _gradientBegin = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomCenter,
          end: Alignment.bottomLeft,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.bottomRight,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomCenter,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomCenter,
          end: Alignment.bottomCenter,
        ),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _gradientEnd = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topCenter,
          end: Alignment.topRight,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.topLeft,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topCenter,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topCenter,
          end: Alignment.topCenter,
        ),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    // Запуск анимаций
    _fadeController.forward();
    _slideController.forward();
    _logoController.forward();

    // Инициализация авторизации
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.initialize();
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7B3BEA),
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return MainScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Анимированный фон с частицами
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: Color(0xFF6A2FD6),
                spawnMinSpeed: 5,
                spawnMaxSpeed: 15,
                particleCount: 50,
                opacityChangeRate: 0.1,
                maxOpacity: 0.6,
                spawnMaxRadius: 8,
                spawnMinRadius: 3,
              ),
            ),
            child: Container(),
          ),
          // Анимированный градиент внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: _gradientBegin.value,
                      end: _gradientEnd.value,
                      colors: [
                        _gradientColor1.value!.withOpacity(0.8), // Насыщенный низ
                        _gradientColor2.value!.withOpacity(0.3), // Прозрачный центр
                        Colors.transparent, // Полностью прозрачный верх
                      ],
                      stops: [0.0, 0.2, 0.5], // Затухание к 50% высоты
                    ),
                  ),
                );
              },
            ),
          ),
          // Основное содержимое
          SafeArea(
            left: false,
            right: false,
            child: SizedBox(
              width: screenWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Логотип
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 360,
                          height: 360,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  // Приветственное сообщение
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Добро пожаловать',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Найдите лучшие услуги рядом',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C5C5C),
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 70),
                  // Кнопка "Начать"
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration: Duration(milliseconds: 600),
                          ),
                        );
                      },
                      child: Container(
                        width: screenWidth * 0.8,
                        height: 60,
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
                        child: Center(
                          child: Text(
                            'Начать',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}