# Post Explorer — СРС 8 и СРС 9

Flutter-приложение для просмотра, поиска и создания постов из [JSONPlaceholder](https://jsonplaceholder.typicode.com).

**Стек:** Dio · Retrofit · json_serializable · build_runner · Provider · SharedPreferences.

## Запуск

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # генерирует *.g.dart
flutter run
```

Иконка приложения (СРС 9):

```bash
dart run flutter_launcher_icons
```

Тесты:

```bash
flutter test
```

> **СРС 9** — своя Launcher Icon (с Adaptive Icon), 34 Unit Test и 12 Widget Test.
> Подробный отчёт и ответы на контрольные вопросы: [SRS9_REPORT.md](SRS9_REPORT.md).

## Архитектура

```
UI (screens, widgets)
   │  context.watch / context.read
   ▼
State (PostsProvider — ChangeNotifier)
   │
   ▼
Repository (PostRepository) — преобразование ошибок в AppException, кэш
   │                      │
   ▼                      ▼
Remote: PostApi        Local: PostCache
(Retrofit + Dio)       (SharedPreferences)
   │
   ▼
JSONPlaceholder REST API
```

UI никогда не обращается к Dio напрямую — только через Provider и Repository.

```
lib/
├── core/
│   ├── network/  dio_client.dart (один Dio), api_interceptor.dart (заголовки, логи)
│   └── error/    app_exception.dart (единая обработка ошибок)
├── data/
│   ├── models/   post.dart, comment.dart, user.dart (+ вложенные Address, Company)
│   ├── remote/   post_api.dart (Retrofit, 7 запросов)
│   ├── local/    post_cache.dart (SharedPreferences)
│   └── repositories/ post_repository.dart
├── presentation/
│   ├── screens/  posts_screen, post_detail_screen, create_post_screen
│   ├── widgets/  post_tile, state_views (Error / Empty / Cached)
│   └── state/    posts_provider.dart
└── main.dart
```

## API-запросы (Retrofit)

| № | Метод | Endpoint | Где используется |
|---|-------|----------|------------------|
| 1 | GET | `/posts?_page=&_limit=10` | список, пагинация |
| 2 | GET | `/posts/{id}` | экран деталей |
| 3 | GET | `/posts?userId=&_page=&_limit=10` | фильтр по автору |
| 4 | GET | `/posts/{id}/comments` | экран деталей |
| 5 | POST | `/posts` | создание поста |
| + | GET | `/users` | выбор автора (фильтр и форма) |
| + | GET | `/users/{id}` | автор на экране деталей |

Коллекция для Postman: `postman/SRS8_JSONPlaceholder.postman_collection.json`.

## Состояния экрана

`ListStatus`: **loading**, **success**, **cached**, **error**, **empty**.
Отдельно от них: `isLoadingMore` и `loadMoreError` (подгрузка страницы), `_isSending` (отправка формы) — разные операции не делят один флаг `isLoading`.

## Пагинация

* Первая загрузка — 10 постов, при прокрутке к концу — следующая страница.
* Защита от двойной загрузки: если уже идёт загрузка (`isLoadingMore`) — новый запрос не отправляется.
* Ошибка подгрузки показывается внизу списка с кнопкой «Повторить».
* При смене автора страницы сбрасываются, а ответы старых запросов игнорируются (`_requestId`), поэтому результаты не смешиваются.

## Поиск и фильтры

* Поиск по заголовку — **локально, среди загруженных постов** (это написано под полем поиска).
* Фильтр по автору — запрос на сервер `/posts?userId=`.
* Сортировка по ID (стрелка в шапке), кнопка сброса фильтров.

## Кэширование и офлайн

| Ситуация | Поведение |
|----------|-----------|
| Первый запуск | Кэша нет → индикатор загрузки → данные с сервера → первая страница сохраняется в кэш. |
| Повторное открытие | Сразу показывается кэш с плашкой «Показаны сохранённые данные. Обновляем…», параллельно идёт запрос; после ответа список и кэш обновляются. |
| Нет интернета | Показывается кэш с плашкой и сообщением «Нет подключения к интернету». Если кэша нет — экран ошибки с кнопкой «Повторить». Последний успешный результат не удаляется. |
| Pull-to-refresh | Повторный запрос первой страницы. |

## Создание поста

Валидация: title 5–100 символов, body 10–1000, автор обязателен. Кнопка блокируется во время запроса. После ответа показывается объект от сервера, а пост добавляется в список с пометкой **«создан локально»**, потому что JSONPlaceholder не сохраняет POST.

## Ошибки

`AppException.from()` различает: нет соединения, таймаут, HTTP 4xx, HTTP 5xx, ошибку JSON, неизвестную ошибку. Пользователь видит понятный текст, технические детали пишутся в консоль (`debugPrint`, `LogInterceptor`).

## Тесты

| Файл | Что проверяет |
|------|---------------|
| `models_test.dart` | 1) JSON → Post, 2) Post → JSON, вложенный User, отсутствующее поле |
| `repository_test.dart` | 3) успешная загрузка, 4) ошибка сервера 500, нет соединения |
| `posts_provider_test.dart` | 5) фильтрация, 6) защита от двойной загрузки, смена фильтра, офлайн-кэш |
| `create_post_dio_test.dart` | POST через Retrofit с mock-адаптером Dio, валидация |
| `widget_test.dart` | пометка «создан локально» |
| **СРС 9:** `unit/post_validation_test.dart` | валидация формы: пустой ввод, границы длины, пробелы |
| `unit/filter_posts_test.dart` | поиск, фильтр по автору, сортировка |
| `unit/app_exception_test.dart` | таймаут, нет сети, 404/400/500, неверный JSON |
| `unit/posts_provider_logic_test.dart` | статусы, конец пагинации, повтор после ошибки, локальный пост |
| `widget/posts_screen_test.dart` | главный экран: элементы, поиск, сортировка, фильтр, ошибка + «Повторить» |
| `widget/create_post_screen_test.dart` | форма: ошибки ввода, успешная отправка, ошибка сервера |
| `widget/navigation_test.dart` | переходы: список → детали → назад; «+» → форма → новый пост в списке |

Отчёт о тестах: `flutter test > test_report.txt`.

## Скриншоты

Папка `screenshots/` (`icon_preview.png` — иконка в разных лаунчерах).
