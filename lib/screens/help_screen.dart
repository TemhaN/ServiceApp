import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _appBarSlideAnimation;

  @override
  void initState() {
    super.initState();
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
                  title: Text(
                    'Помощь',
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
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
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
                      child: Text(
                        'Часто задаваемые вопросы',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildFAQItem(
                      question: 'Как создать новую услугу?',
                      answer:
                      'Перейдите в раздел "Профиль" и нажмите "Создать новую услугу". Заполните все поля и сохраните.',
                    ),
                    _buildFAQItem(
                      question: 'Как связаться с поддержкой?',
                      answer:
                      'Используйте форму ниже, чтобы отправить запрос, или напишите нам на support@serviceapp.com.',
                    ),
                    _buildFAQItem(
                      question: 'Почему мои услуги не отображаются?',
                      answer:
                      'Убедитесь, что вы вошли в аккаунт, и проверьте подключение к интернету. Если проблема сохраняется, свяжитесь с поддержкой.',
                    ),
                    SizedBox(height: 24),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        'Связаться с поддержкой',
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
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email поддержки',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'support@serviceapp.com',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildButton(
                              text: 'Отправить запрос',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Функция отправки запроса в разработке',
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
                                        color:
                                        Color(0xFF7B3BEA).withOpacity(0.3),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 16.0 + MediaQuery.of(context).padding.bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
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
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          )
        );
      },
    );
  }
}