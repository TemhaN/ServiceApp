import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:service_app/models/chat.dart';
import 'package:service_app/models/message.dart';
import 'package:service_app/providers/auth_provider.dart';
import 'package:service_app/services/api_service.dart';
import 'package:service_app/screens/service_detail_screen.dart';
import 'dart:ui';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  ChatScreen({required this.chat});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  List<Message> _messages = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _scale = 1.0; // Для анимации карточки
  late AnimationController _animationController;
  late Animation<double> _appBarSlideAnimation;
  int? _editingmessageId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
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

  Future<void> _loadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: не авторизован')),
      );
      return;
    }

    try {
      final messages = await ApiService.getMessages(widget.chat.chatId, authProvider.token!);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
      _markMessagesAsRead(authProvider);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (e.toString().contains('Чат не найден')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Чат временно недоступен, попробуйте снова'),
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Color(0xFF7B3BEA),
              onPressed: _loadMessages,
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки сообщений: $e')),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead(AuthProvider authProvider) async {
    if (authProvider.token == null) return;

    try {
      final unreadMessages = _messages
          .where((m) => m.senderId != authProvider.user!.id && !m.isRead)
          .map((m) => m.messageId)
          .toList();

      if (unreadMessages.isNotEmpty) {
        await ApiService.markMessagesAsRead(widget.chat.chatId, unreadMessages, authProvider.token!);
        setState(() {
          for (var messageId in unreadMessages) {
            final index = _messages.indexWhere((m) => m.messageId == messageId);
            if (index != -1) {
              _messages[index] = Message(
                messageId: _messages[index].messageId,
                chatId: _messages[index].chatId,
                senderId: _messages[index].senderId,
                senderName: _messages[index].senderName,
                content: _messages[index].content,
                sentAt: _messages[index].sentAt,
                editedAt: _messages[index].editedAt,
                isRead: true,
              );
            }
          }
        });
      }
    } catch (e) {
      print('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  Future<void> _sendOrUpdateMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    try {
      if (_editingmessageId != null) {
        // Проверяем, существует ли сообщение
        final messageIndex = _messages.indexWhere((m) => m.messageId == _editingmessageId);
        if (messageIndex == -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Сообщение не найдено, обновляем список')),
          );
          await _loadMessages();
          setState(() {
            _editingmessageId = null;
            _messageController.clear();
          });
          return;
        }

        final updatedMessage = await ApiService.updateMessage(
          widget.chat.chatId,
          _editingmessageId!,
          _messageController.text.trim(),
          authProvider.token!,
        );
        setState(() {
          _messages[messageIndex] = updatedMessage;
          _messageController.clear();
          _editingmessageId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Сообщение обновлено'),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } else {
        final message = await ApiService.sendMessage(
          widget.chat.chatId,
          _messageController.text.trim(),
          authProvider.token!,
        );
        setState(() {
          _messages.add(message);
          _messageController.clear();
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (e.toString().contains('Сообщение не найдено')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сообщение не найдено, обновляем список')),
        );
        await _loadMessages();
        setState(() {
          _editingmessageId = null;
          _messageController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    try {
      // Проверяем, существует ли сообщение
      final messageIndex = _messages.indexWhere((m) => m.messageId == messageId);
      if (messageIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Сообщение не найдено, обновляем список',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            margin: EdgeInsets.all(16),
          ),
        );
        await _loadMessages();
        return;
      }

      await ApiService.deleteMessage(widget.chat.chatId, messageId, authProvider.token!);
      setState(() {
        _messages.removeAt(messageIndex);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Сообщение удалено',
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
    } catch (e) {
      if (e.toString().contains('Сообщение не найдено')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Сообщение не найдено, обновляем список',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            margin: EdgeInsets.all(16),
          ),
        );
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка удаления сообщения: $e',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _startEditingMessage(Message message) {
    setState(() {
      _editingmessageId = message.messageId;
      _messageController.text = message.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingmessageId = null;
      _messageController.clear();
    });
  }

  void _showDeleteConfirmation(int messageId) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Удалить сообщение',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить это сообщение?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
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
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final otherUser = authProvider.user!.id == widget.chat.customerId
        ? widget.chat.provider
        : widget.chat.customer;
    final title = otherUser != null
        ? '${otherUser.firstName} ${otherUser.lastName}'.trim()
        : 'Пользователь';
    final serviceTitle = widget.chat.service?.title ?? 'Услуга';
    final servicePrice = widget.chat.service?.price != null
        ? '${widget.chat.service!.price!.toInt()} ₸'
        : 'Не указана';
    final serviceImage = widget.chat.service != null && widget.chat.service!.serviceImages.isNotEmpty
        ? widget.chat.service!.serviceImages
        .firstWhere((img) => img.isPrimary, orElse: () => widget.chat.service!.serviceImages.first)
        .imageUrl
        : null;

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
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 24,
                        child: Text(
                          title.isNotEmpty ? title[0] : '?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  elevation: 0,
                  centerTitle: false,
                  actions: [
                    if (widget.chat.service != null)
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceDetailScreen(serviceId: widget.chat.service!.serviceId),
                            ),
                          );
                        },
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
      body: Column(
        children: [
          // Закреплённый элемент с услугой
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _scale = 0.92),
              onTapUp: (_) => setState(() => _scale = 1.0),
              onTapCancel: () => setState(() => _scale = 1.0),
              onTap: () {
                if (widget.chat.service != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailScreen(serviceId: widget.chat.service!.serviceId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Услуга недоступна'),
                      backgroundColor: Colors.white,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }
              },
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()..scale(_scale),
                  transformAlignment: Alignment.center,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 0.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        blurRadius: 12,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: serviceImage != null
                            ? CachedNetworkImage(
                          imageUrl: '${ApiService.baseImageUrl}$serviceImage',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset(
                            'assets/images/placeholder.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/placeholder.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Image.asset(
                          'assets/images/placeholder.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceTitle,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              servicePrice,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              )
            ),
          ),
          // Список сообщений
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF7B3BEA)))
                : _messages.isEmpty
                ? Center(
              child: Text(
                'Нет сообщений',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == authProvider.user!.id;
                final isShortMessage = message.content.length < 10;

                return GestureDetector(
                  onLongPress: isMe
                      ? () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      builder: (context) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                  title: Text(
                                    'Редактировать',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _startEditingMessage(message);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                  title: Text(
                                    'Удалить',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Roboto',
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showDeleteConfirmation(message.messageId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                      : null,
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300),
                    child: Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isMe ? 16 : 4),
                            topRight: Radius.circular(isMe ? 4 : 16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isShortMessage
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                message.content,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.sentAt.toLocal().toString().substring(11, 16),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: isMe
                                        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    message.isRead ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                            if (message.editedAt != null) ...[
                              SizedBox(width: 8),
                              Text(
                                'Изменено',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: isMe
                                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        )
                            : Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.end,
                          children: [
                            Text(
                              message.content,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.sentAt.toLocal().toString().substring(11, 16),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: isMe
                                        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    message.isRead ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                            if (message.editedAt != null)
                              Text(
                                'Изменено',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: isMe
                                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Поле ввода сообщения
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (_editingmessageId != null)
                    IconButton(
                      icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.primary),
                      onPressed: _cancelEditing,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: _editingmessageId != null ? 'Редактировать сообщение...' : 'Введите сообщение...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _sendOrUpdateMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _scale = 0.9),
                    onTapUp: (_) {
                      setState(() => _scale = 1.0);
                      _sendOrUpdateMessage();
                    },
                    onTapCancel: () => setState(() => _scale = 1.0),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_scale),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _editingmessageId != null ? Icons.check : Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
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