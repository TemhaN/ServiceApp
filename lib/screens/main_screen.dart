import 'package:flutter/material.dart';
import 'dart:ui'; // Для эффекта стекла (BackdropFilter)
import 'package:service_app/screens/home_screen.dart';
import 'package:service_app/screens/favorites_screen.dart';
import 'package:service_app/screens/chats_screen.dart';
import 'package:service_app/screens/profile_screen.dart';
import 'package:service_app/screens/service_edit_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
    Container(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.add_rounded,
    Icons.chat_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = [
    'Главная',
    'Избранное',
    'Создать',
    'Чаты',
    'Профиль',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _animationController.forward().then((_) {
        _animationController.reverse();
        _addService();
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _addService() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ServiceEditScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Контент виден под островком
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_selectedIndex],
        key: ValueKey<int>(_selectedIndex),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Отступы от краёв
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25), // Более скруглённые углы
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Эффект стекла
            child: Container(
              height: 76, // Увеличенная высота островка
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Theme.of(context).colorScheme.onSurface,
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                selectedLabelStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                ),
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: List.generate(_icons.length, (index) {
                  return BottomNavigationBarItem(
                    icon: index == 2
                        ? ScaleTransition(
                      scale: _fabScaleAnimation,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _icons[index],
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    )
                        : AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_selectedIndex == index ? 6 : 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _icons[index],
                        color: _selectedIndex == index
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        size: _selectedIndex == index ? 22 : 20,
                      ),
                    ),
                    label: _labels[index],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}