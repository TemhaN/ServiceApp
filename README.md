
# 🛠️ Service App

Service App — мобильное приложение на Flutter для поиска, создания и управления услугами. Пользователи могут регистрироваться, просматривать услуги, общаться с поставщиками в чатах, оставлять отзывы, добавлять услуги в избранное и управлять своим профилем через современный и интуитивный интерфейс. Приложение разработано с акцентом на Android, но благодаря Flutter поддерживает кроссплатформенность.

## ✨ Возможности

- 🔐 Аутентификация: регистрация, вход, просмотр, редактирование и удаление профиля.
- 🛒 Управление услугами: создание, просмотр, редактирование и удаление услуг, просмотр по категориям, рекомендации и похожие услуги.
- 💬 Чаты: начало чатов с поставщиками услуг, отправка сообщений, отметка сообщений как прочитанных.
- ⭐ Избранное: добавление и удаление услуг в избранное.
- 📝 Отзывы: написание, редактирование и удаление отзывов к услугам.
- 🎨 Современный интерфейс: анимации, закруглённые элементы, градиенты и адаптивный дизайн.
- 📱 Поддержка Android: оптимизировано для Android с возможностью расширения на другие платформы.

## 📋 Требования

- Flutter 3.0.0 или выше
- Dart 2.17.0 или выше
- Android SDK для сборки и запуска на Android
- Подключение к серверу Service App (см. Service App Server)

## 🧩 Зависимости

| Библиотека              | Назначение                                 |
|-------------------------|--------------------------------------------|
| flutter                 | Основной SDK для создания интерфейса      |
| provider                | Управление состоянием приложения          |
| cached_network_image    | Кэширование и загрузка изображений        |
| http                    | Выполнение HTTP-запросов к API            |

Полный список зависимостей указан в `pubspec.yaml`.

## 🚀 Установка и запуск

Клонируйте репозиторий:
```bash
git clone https://github.com/TemhaN/ServiceApp.git
cd ServiceApp
```

Установите зависимости:
```bash
flutter pub get
```

Настройте подключение к API:

Укажите URL сервера в файле `lib/services/api_service.dart`, например:
```dart
static const String baseUrl = 'https://your-api-url';
```

Убедитесь, что сервер Service App Server запущен.

Запустите приложение:
```bash
flutter run
```

Для сборки релизной версии APK:
```bash
flutter build apk --release
```
APK будет находиться в `build/app/outputs/flutter-apk/app-release.apk`.

## 🖱️ Использование

1. Запустите приложение с помощью `flutter run`.
2. Зарегистрируйтесь или войдите в аккаунт.
3. Просматривайте услуги на главном экране или создавайте свои в разделе "Профиль".
4. Используйте чаты для общения с поставщиками услуг.
5. Добавляйте услуги в избранное или оставляйте отзывы.
6. Настраивайте профиль или обращайтесь за помощью в разделе "Настройки и поддержка".

## 📦 Сборка приложения

Для создания APK для Android:
```bash
flutter build apk --release
```

Собранный APK будет в `build/app/outputs/flutter-apk/app-release.apk`.

Для установки на устройство скопируйте APK на телефон и установите, разрешив установку из неизвестных источников.

## 📸 Скриншоты

<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/1.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/2.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/3.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/4.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/5.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/6.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/7.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/8.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/9.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/10.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/11.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/12.png" alt="Service App">
<img src="https://github.com/TemhaN/ServiceApp/blob/main/screenshots/13.png" alt="Service App">

## 🧠 Автор

**TemhaN**  
[GitHub профиль](https://github.com/TemhaN)

## 🧾 Лицензия

Проект распространяется под лицензией MIT.

Делайте с ним что угодно — главное, с любовью к Flutter! 😄

## 📬 Обратная связь

Нашли баг или хотите предложить улучшение?

Создавайте issue или присылайте pull request в репозитории!

## ⚙️ Технологии

- Flutter — кроссплатформенный фреймворк для создания UI.
- Dart — язык программирования.
- Provider — управление состоянием.
- REST API — взаимодействие с сервером через HTTP-запросы.
