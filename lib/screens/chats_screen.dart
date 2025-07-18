import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:service_app/models/chat.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/services/api_service.dart';
import 'package:service_app/screens/chat_screen.dart';
import 'dart:ui'; // Для эффекта размытия

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  List<Chat> _chats = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _appBarSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadChats();
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

  Future<void> _loadChats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Войдите, чтобы просмотреть чаты')),
      );
      return;
    }

    try {
      final chats = await ApiService.getChats(authProvider.token!);
      print('Загружено чатов: ${chats.length}');
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чатов: $e')),
      );
    }
  }

  Future<void> _deleteChat(int chatId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    final deletedChat = _chats.firstWhere((chat) => chat.chatId == chatId);
    final deletedIndex = _chats.indexOf(deletedChat);

    setState(() {
      _chats.removeWhere((chat) => chat.chatId == chatId);
    });

    try {
      await ApiService.deleteChat(chatId, authProvider.token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Чат удалён'),
          action: SnackBarAction(
            label: 'Отменить',
            textColor: Color(0xFF7B3BEA),
            onPressed: () {
              setState(() {
                _chats.insert(deletedIndex, deletedChat);
              });
            },
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _chats.insert(deletedIndex, deletedChat);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления чата: $e')),
      );
    }
  }

  Future<bool?> _showDeleteDialog(int chatId) async {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent, // Прозрачный барьер для размытия
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Эффект размытия
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Удалить чат',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Вы уверены, что хотите удалить этот чат?',
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
                    'Чаты',
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
        bottom: false, // Контент прокручивается под островком
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: !authProvider.isAuthenticated
                  ? Padding(
                padding: EdgeInsets.all(16.0),
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Войдите, чтобы просматривать чаты',
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
                  ? Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7B3BEA),
                  ),
                ),
              )
                  : _chats.isEmpty
                  ? Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Нет активных чатов',
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
                  : SizedBox.shrink(),
            ),
            if (authProvider.isAuthenticated && !_isLoading && _chats.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 69.0 + 16.0 + MediaQuery.of(context).padding.bottom,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final chat = _chats[index];
                      final otherUser = authProvider.user!.id == chat.customerId
                          ? chat.provider
                          : chat.customer;
                      final title = chat.service?.title ?? 'Услуга';
                      final subtitle = otherUser != null
                          ? '${otherUser.firstName} ${otherUser.lastName}'
                          : 'Пользователь';
                      final lastMessage = chat.lastMessage != null
                          ? chat.lastMessage!.content.length > 30
                          ? '${chat.lastMessage!.content.substring(0, 30)}...'
                          : chat.lastMessage!.content
                          : 'Нет сообщений';

                      return Dismissible(
                        key: Key(chat.chatId.toString()),
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final shouldDelete = await _showDeleteDialog(chat.chatId);
                          return shouldDelete ?? false;
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),// Усиленная тень
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              radius: 24,
                              child: Text(
                                subtitle.isNotEmpty ? subtitle[0] : '?',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  chat.lastMessage?.sentAt
                                      .toLocal()
                                      .toString()
                                      .substring(11, 16) ??
                                      '',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  lastMessage,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(chat: chat),
                                ),
                              );
                            },
                            onLongPress: () async {
                              final shouldDelete = await _showDeleteDialog(chat.chatId);
                              if (shouldDelete == true) {
                                await _deleteChat(chat.chatId);
                              }
                            },
                          ),
                        ),
                      );
                    },
                    childCount: _chats.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}