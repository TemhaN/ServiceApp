import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;
import 'package:service_app/models/service.dart';
import 'package:service_app/models/category.dart';
import 'package:service_app/models/favorite.dart';
import 'package:service_app/models/user.dart';
import 'package:service_app/models/chat.dart';
import 'package:service_app/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:service_app/models/review.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.8.158:7113/api';
  static const String baseImageUrl = 'http://192.168.8.158:7113';
  static const String _tokenKey = 'jwt_token';

  // Создаём HTTP-клиент с отключённой проверкой SSL
  static final _client = () {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return io_client.IOClient(httpClient);
  }();

  // Сохранение токена
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Получение токена
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Удаление токена
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Регистрация
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/Auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
      }),
    );

    return _handleResponse(response);
  }

  // Вход
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);
    if (data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  // Получение профиля
  static Future<User> getProfile() async {
    final token = await getToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/Auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  // Обновление профиля
  static Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final token = await getToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/Auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
      }),
    );

    return _handleResponse(response);
  }

  // Удаление профиля
  static Future<Map<String, dynamic>> deleteProfile() async {
    final token = await getToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/Auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    await removeToken();
    return _handleResponse(response);
  }

  // Получение списка категорий
  static Future<List<Category>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/Services/categories');
      final headers = {'Content-Type': 'application/json'};
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['categories'] as List<dynamic>)
            .map((e) => Category.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Get categories error: $e');
      rethrow;
    }
  }

  // Получение списка услуг
  static Future<List<Service>> getServices({
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? location,
    required int page,
    int pageSize = 10,
  }) async {
    final token = await getToken();
    final queryParameters = {
      'search': search,
      'categoryId': categoryId?.toString(),
      'minPrice': minPrice?.toString(),
      'maxPrice': maxPrice?.toString(),
      'location': location,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    }..removeWhere((key, value) => value == null);

    final uri = Uri.parse('$baseUrl/Services').replace(queryParameters: queryParameters);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['services'] as List<dynamic>)
          .map((e) => Service.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load services: ${response.statusCode}');
    }
  }

  // Получение рекомендованных услуг
  static Future<List<Service>> getRecommendedServices({
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? location,
    required int page,
    int pageSize = 10,
    required String token,
  }) async {
    final queryParameters = {
      'search': search,
      'categoryId': categoryId?.toString(),
      'minPrice': minPrice?.toString(),
      'maxPrice': maxPrice?.toString(),
      'location': location,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    }..removeWhere((key, value) => value == null);

    final uri = Uri.parse('$baseUrl/Services/recommended').replace(queryParameters: queryParameters);
    final response = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['services'] as List<dynamic>)
          .map((e) => Service.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load recommended services: ${response.statusCode}');
    }
  }

  // Получение услуги по ID
  static Future<Service> getService(int id) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/Services/$id'),
      headers: headers,
    );

    final data = _handleResponse(response);
    return Service.fromJson(data['service']);
  }

  // Обработка ответа
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['responseMessage'] ?? 'Ошибка запроса: ${response.statusCode}');
    }
  }
  static Future<Service> createService({
    required String title,
    required String description,
    required double price,
    required String location,
    required int categoryId,
    List<File>? images,
    int? primaryImageIndex,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Не авторизован');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/Services'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['price'] = price != null
        ? (price % 1 == 0 ? price.toInt().toString() : price.toString())
        : '';
    request.fields['location'] = location;
    request.fields['categoryId'] = categoryId.toString();

    if (primaryImageIndex != null) {
      request.fields['PrimaryImageIndex'] = primaryImageIndex.toString();
    }

    print(
        'Отправка запроса на создание услуги: title=$title, description=$description, price=$price, location=$location, categoryId=$categoryId, images=${images?.length ?? 0}, primaryImageIndex=$primaryImageIndex');

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        final fileExtension = image.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          throw Exception('Поддерживаются только JPG, JPEG, PNG');
        }
        final fileSize = await image.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Размер изображения не должен превышать 5 МБ');
        }
        print('Добавление изображения: ${image.path}, размер: $fileSize байт');
        request.files.add(await http.MultipartFile.fromPath(
          'Images',
          image.path,
          contentType: MediaType('image', fileExtension),
        ));
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print('Ответ сервера: status=${response.statusCode}, body=$responseBody');
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return Service.fromJson(data['service']);
    } else {
      throw Exception(data['responseMessage'] ?? 'Не удалось создать услугу: ${response.statusCode}');
    }
  }

  static Future<Service> updateService({
    required int id,
    required String title,
    required String description,
    required double? price,
    required String location,
    required int categoryId,
    List<File>? images,
    int? primaryImageIndex,
    List<int>? existingImageIds,
    int? primaryExistingImageId,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Не авторизован');

    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/Services/$id'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['price'] = price != null
        ? (price % 1 == 0 ? price.toInt().toString() : price.toString())
        : '';
    request.fields['location'] = location;
    request.fields['categoryId'] = categoryId.toString();

    if (primaryImageIndex != null) {
      request.fields['PrimaryImageIndex'] = primaryImageIndex.toString();
    }
    // Отправляем ExistingImageIds как массив
    if (existingImageIds != null && existingImageIds.isNotEmpty) {
      for (int i = 0; i < existingImageIds.length; i++) {
        request.fields['ExistingImageIds[$i]'] = existingImageIds[i].toString();
      }
    }
    if (primaryExistingImageId != null) {
      request.fields['PrimaryExistingImageId'] = primaryExistingImageId.toString();
    }

    print(
        'Отправка запроса на обновление услуги: id=$id, title=$title, description=$description, price=$price, location=$location, categoryId=$categoryId, images=${images?.length ?? 0}, primaryImageIndex=$primaryImageIndex, existingImageIds=$existingImageIds, primaryExistingImageId=$primaryExistingImageId');

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        final fileExtension = image.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          throw Exception('Поддерживаются только JPG, JPEG, PNG');
        }
        final fileSize = await image.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Размер изображения не должен превышать 5 МБ');
        }
        print('Добавление изображения: ${image.path}, размер: $fileSize байт');
        request.files.add(await http.MultipartFile.fromPath(
          'Images',
          image.path,
          contentType: MediaType('image', fileExtension),
        ));
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print('Ответ сервера: status=${response.statusCode}, body=$responseBody');
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return Service.fromJson(data['service']);
    } else {
      throw Exception(data['responseMessage'] ?? 'Не удалось обновить услугу: ${response.statusCode}');
    }
  }

  static Future<void> deleteService(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _client.delete(
      Uri.parse('$baseUrl/Services/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['responseMessage'] ?? 'Failed to delete service: ${response.statusCode}');
    }
  }

  static Future<List<Favorite>> getFavorites(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['favorites'] as List).map((e) => Favorite.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load favorites: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addFavorite(int serviceId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'serviceId': serviceId}),
    );

    print('Add favorite: status=${response.statusCode}, body=${response.body}');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception('Failed to add favorite: ${data['responseMessage'] ?? response.body}');
    }
  }

  static Future<void> removeFavorite(int favoriteId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Favorites/$favoriteId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove favorite: ${response.body}');
    }
  }
  // Получение других услуг пользователя
  static Future<List<Service>> getOtherUserServices({
    required int userId,
    required int excludeServiceId,
    required int page,
    int pageSize = 10,
  }) async {
    final token = await getToken();
    final queryParameters = {
      'excludeServiceId': excludeServiceId.toString(),
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/Services/user/$userId/other').replace(queryParameters: queryParameters);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);

    print('Get other user services: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['services'] as List<dynamic>)
          .map((e) => Service.fromJson(e))
          .toList();
    } else {
      throw Exception(jsonDecode(response.body)['responseMessage'] ?? 'Failed to load other user services: ${response.statusCode}');
    }
  }

  // Получение похожих услуг
  static Future<List<Service>> getSimilarServices({
    required int serviceId,
    required int page,
    int pageSize = 10,
  }) async {
    final token = await getToken();
    final queryParameters = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/Services/$serviceId/similar').replace(queryParameters: queryParameters);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);

    print('Get similar services: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['services'] as List<dynamic>)
          .map((e) => Service.fromJson(e))
          .toList();
    } else {
      throw Exception(jsonDecode(response.body)['responseMessage'] ?? 'Failed to load similar services: ${response.statusCode}');
    }
  }

  static Future<User> getUserById(int id) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/Auth/users/$id'),
      headers: headers,
    );

    print('Get user by id: status=${response.statusCode}, body=${response.body}');

    final data = _handleResponse(response);
    return User.fromJson(data);
  }


  // Создание чата
  static Future<Chat> createChat(int serviceId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'serviceId': serviceId}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Chat.fromJson(json['chat']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['responseMessage'] ?? 'Ошибка создания чата');
    }
  }

  // Получение списка чатов
  static Future<List<Chat>> getChats(String token) async {
    try {
      if (token.isEmpty) throw Exception('Недействительный или отсутствующий токен');

      final response = await http.get(
        Uri.parse('$baseUrl/Chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Логируем ответ для отладки
      print('GetChats response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body);
          return (json['chats'] as List).map((item) => Chat.fromJson(item)).toList();
        } catch (e) {
          throw Exception('Ошибка парсинга ответа чатов: $e\nТело ответа: ${response.body}');
        }
      } else {
        String errorMessage;
        try {
          final json = jsonDecode(response.body);
          errorMessage = json['responseMessage'] ?? 'Не удалось загрузить чаты: ${response.statusCode}';
        } catch (e) {
          errorMessage = 'Сервер вернул некорректный ответ: ${response.statusCode}\nТело: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Ошибка GetChats: $e');
      rethrow;
    }
  }

  // Отправка сообщения
  static Future<Message> sendMessage(int chatId, String content, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Chats/$chatId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Message.fromJson(json['message']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['responseMessage'] ?? 'Ошибка отправки сообщения');
    }
  }

  // Получение сообщений
  static Future<List<Message>> getMessages(int chatId, String token) async {
    if (chatId == 0) {
      throw Exception('Некорректный идентификатор чата');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Chats/$chatId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['messages'] as List?)?.map((item) => Message.fromJson(item)).toList() ?? [];
      } else {
        final json = jsonDecode(response.body);
        throw Exception(json['responseMessage'] ?? 'Ошибка получения сообщений');
      }
    } catch (e) {
      if (e.toString().contains('Чат не найден')) {
        await Future.delayed(Duration(seconds: 1));
        final response = await http.get(
          Uri.parse('$baseUrl/Chats/$chatId/messages'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return (json['messages'] as List?)?.map((item) => Message.fromJson(item)).toList() ?? [];
        } else {
          final json = jsonDecode(response.body);
          throw Exception(json['responseMessage'] ?? 'Ошибка получения сообщений');
        }
      }
      rethrow;
    }
  }

  static Future<void> markMessagesAsRead(int chatId, List<int> messageIds, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Chats/$chatId/messages/mark-read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(messageIds),
    );

    print('MarkMessagesAsRead response: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode != 200) {
      try {
        final json = jsonDecode(response.body);
        throw Exception(json['responseMessage'] ?? 'Ошибка отметки сообщений как прочитанных');
      } catch (e) {
        throw Exception('Ошибка сервера: ${response.statusCode}\nОтвет: ${response.body}');
      }
    }
  }

  // Обновление сообщения
  static Future<Message> updateMessage(int chatId, int messageId, String content, String token) async {
    print('Attempting to update message: chatId=$chatId, messageId=$messageId, content=$content');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Chats/$chatId/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      print('UpdateMessage response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Message.fromJson(json['message']);
      } else {
        final json = jsonDecode(response.body);
        throw Exception(json['responseMessage'] ?? 'Ошибка обновления сообщения');
      }
    } catch (e) {
      print('UpdateMessage error: $e');
      rethrow;
    }
  }

  // Удаление сообщения
  static Future<void> deleteMessage(int chatId, int messageId, String token) async {
    print('Attempting to delete message: chatId=$chatId, messageId=$messageId');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/Chats/$chatId/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('DeleteMessage response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body);
        throw Exception(json['responseMessage'] ?? 'Ошибка удаления сообщения');
      }
    } catch (e) {
      print('DeleteMessage error: $e');
      rethrow;
    }
  }

  // Удаление чата
  static Future<void> deleteChat(int chatId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Chats/$chatId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['responseMessage'] ?? 'Ошибка удаления чата');
    }
  }

  static Future<Chat> getChatByService(int serviceId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Chats/by-service/$serviceId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Chat.fromJson(json['chat']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['responseMessage'] ?? 'Ошибка получения чата');
    }
  }


  // Создание отзыва
  static Future<Review> createReview({
    required int serviceId,
    required int rating,
    String? comment,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Не авторизован');

    final response = await _client.post(
      Uri.parse('$baseUrl/Reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'serviceId': serviceId,
        'rating': rating,
        'comment': comment,
      }),
    );

    final data = _handleResponse(response);
    return Review.fromJson(data['review']);
  }

  // Получение отзывов для услуги
  static Future<List<Review>> getReviews(int serviceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/services/$serviceId/reviews'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['reviews'] as List<dynamic>)
          .map((e) => Review.fromJson(e))
          .toList();
    } else {
      throw Exception(jsonDecode(response.body)['responseMessage'] ?? 'Не удалось загрузить отзывы: ${response.statusCode}');
    }
  }

  // Обновление отзыва
  static Future<Review> updateReview({
    required int id,
    required int rating,
    String? comment,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Не авторизован');

    final response = await _client.put(
      Uri.parse('$baseUrl/Reviews/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    final data = _handleResponse(response);
    return Review.fromJson(data['review']);
  }

  // Удаление отзыва
  static Future<void> deleteReview(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Не авторизован');

    final response = await _client.delete(
      Uri.parse('$baseUrl/Reviews/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['responseMessage'] ?? 'Не удалось удалить отзыв: ${response.statusCode}');
    }
  }

}