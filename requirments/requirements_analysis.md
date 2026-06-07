# Аналіз відповідності проекту вимогам

Детальне порівняння проекту **Salary Leftovers Collector** з вимогами з папки `requirments/`.

---

## ✅ Що відповідає вимогам

| # | Вимога | Статус |
|---|--------|--------|
| 1 | Архітектура MVVM | ✅ ViewModels + Provider |
| 2 | Залежності: provider, camera, shared_preferences, in_app_review | ✅ Всі присутні |
| 3 | Заборонені бібліотеки (Toasts, native_splash, Localization, drift, sqflite) | ✅ Не використовуються |
| 4 | Android Min SDK 24 | ✅ `minSdk = 24` |
| 5 | iOS мінімальна версія 16 | ✅ `IPHONEOS_DEPLOYMENT_TARGET = 16.0` |
| 6 | Одинарні лапки | ✅ Правило `prefer_single_quotes: true` |
| 7 | `pubspec.yaml` без коментарів з описом | ✅ Коментарі видалені |
| 8 | Кольори, шрифти, текстові стилі в константах | ✅ `AppColors`, `AppTypography` |
| 9 | Privacy Policy через `url_launcher` зі строкою `"https://google.com"` | ✅ Реалізовано в `settings_actions.dart` |
| 10 | Share App через `share_plus` зі строкою `"Try this app! :) {APPSTORE_LINK}"` | ✅ Реалізовано в `settings_actions.dart` |
| 11 | Логіка Share App та Privacy Policy в одному файлі | ✅ Обидві в `settings_actions.dart` |
| 12 | Файл `settings-path.txt` з шляхом до файлу | ✅ Вказує на `lib/ui/settings/settings_actions.dart` |
| 13 | Кнопка зі зміною стану при тапі (анімація) | ✅ `AnimatedButton` зі scale-анімацією |
| 14 | Клавіатура закривається тапом по вільній області | ✅ `UnfocusWrapper` на формах |
| 15 | Welcome screen / Onboarding тільки при першому відкритті | ✅ Перевірка `hasSeenOnboarding` в SharedPreferences |
| 16 | Bottom Tab Navigation (Home, Expenses, Wheel, Analytics, Settings) | ✅ В `main_screen.dart` |
| 17 | Trailing commas правило | ✅ `require_trailing_commas: true` в `analysis_options.yaml` |
| 18 | Wheel — раз на добу, множник 1.1–2.0 | ✅ Перевірка дати, `1.1 + Random().nextDouble() * 0.9` |
| 19 | Кольори: primaryAccent `#2A7BDE`, secondaryAccent `#8C3ED6` | ✅ Відповідають |
| 20 | Шрифт Inter, розміри headline1=24, headline2=20, body=16, caption=13 | ✅ Відповідають |
| 21 | Валідація полів: amount, text, image, selection | ✅ `ValidationHelpers` + form validators |

---

## ❌ Невідповідності

### 1. ❌ Відсутні Notification Flows (нотифікації не реалізовані)

> [!CAUTION]
> Вимога (tz_app_2.json, master_promt.txt): Додаток повинен мати **локальні нотифікації** — нагадування щодня о 20:00 якщо не додано витрат, та повідомлення о 19:00 коли Wheel готовий.

**Факт:** У проекті немає жодного пакету для локальних нотифікацій (напр. `flutter_local_notifications`). Кнопка нотифікацій у Settings лише перемикає `bool` значення, але реальне планування нотифікацій відсутнє.

**Файл:** [settings_viewmodel.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/viewmodels/settings_viewmodel.dart) — лише зберігає `notificationsEnabled` в SharedPreferences без реальної логіки.

---

### 2. ❌ Кнопка нотифікацій: неправильна поведінка

> [!WARNING]
> Вимога (requirements.txt, рядок 19): Кнопка нотифікацій у Settings повинна **спершу запитувати дозвіл**, і лише **при наступному натиску** відкривати налаштування нотифікацій у системних Settings телефону.

**Факт:** У [settings_screen.dart:93-103](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/settings_screen.dart#L93-L103) кнопка нотифікацій реалізована як **SwitchListTile** (тоглер), а не як окрема кнопка. Вона викликає `requestNotificationsPermission()` тільки коли вмикається, і відразу ж перемикає `notificationsEnabled` — навіть якщо дозвіл не був наданий. Логіка НЕ відповідає вимозі "спершу запитати дозвіл, потім при наступному натиску відкрити налаштування".

---

### 3. ❌ Відсутній окремий EditExpenseScreen

> [!WARNING]
> Вимога (tz_app_2.json): Має бути окремий **EditExpenseScreen** з `EditExpenseView` та `EditExpenseViewModel`.

**Факт:** Редагування витрати реалізоване через повторне використання `CreateExpenseScreen` з параметром `expense`. Окремого екрану/файлу `edit_expense_screen.dart` немає. Окремого `EditExpenseViewModel` теж немає.

**Файл:** [create_expense_screen.dart:16-17](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/create_expense_screen.dart#L16-L17)

---

### 4. ❌ Відсутня функція Retake Photo на ExpenseDetailScreen

> [!WARNING]
> Вимога (tz_app_2.json + master_promt.txt): На екрані деталей витрати має бути дія **"Retake Photo"** — повторна фотофіксація для оновлення зображення.

**Факт:** [expense_detail_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/expense_detail_screen.dart) має лише кнопки Edit і Delete. Кнопки "Retake Photo" немає.

---

### 5. ❌ Відсутні фільтри на ExpensesScreen

> [!WARNING]
> Вимога (tz_app_2.json + master_promt.txt): Екран списку витрат повинен мати **фільтрацію** за датою, категорією та наявністю фото.

**Факт:** [expenses_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/expenses_screen.dart) показує простий список без будь-яких фільтрів.

---

### 6. ❌ `cardBackground` колір не відповідає специфікації

> [!NOTE]
> Вимога (tz_app_2.json): `cardBackground` = `#F1F5FB`

**Факт:** В [app_colors.dart:14](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/core/theme/app_colors.dart#L14) визначено `cardBackground = Color(0xFFFFFFFF)` — це `#FFFFFF` (білий), а має бути `#F1F5FB`.

---

### 7. ❌ Відсутній Export Data на AnalyticsScreen

> [!WARNING]
> Вимога (tz_app_2.json): На екрані аналітики має бути дія **"Export Data"**.

**Факт:** [analytics_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/analytics_screen.dart) — немає жодної кнопки або функції експорту даних.

---

### 8. ❌ Відсутній Change Period на AnalyticsScreen

> [!WARNING]
> Вимога (tz_app_2.json): На екрані аналітики має бути дія **"Change Period"** — перемикання періоду перегляду аналітики.

**Факт:** [analytics_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/analytics_screen.dart) показує всі дані без можливості вибору періоду.

---

### 9. ❌ Onboarding не містить ілюстрацій

> [!NOTE]
> Вимога (master_promt.txt): Кожен екран онбордингу має супроводжуватися **ілюстраціями** та підказками.

**Факт:** [onboarding_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/onboarding_screen.dart) містить лише текст (`Text` віджети), без жодних ілюстрацій/зображень.

---

### 10. ❌ Status bar / Home Indicator — немає фону або блюру при скролі

> [!NOTE]
> Вимога (requirements.txt, рядок 18): Status bar і Home Indicator не перекривають контент, мають **свій бекграунд або блюр** при скролі.

**Факт:** Екрани використовують `SafeArea`, але не мають спеціального фону чи блюру для status bar при скролі. На скролячих екранах (Home, Expenses, Analytics, Settings) status bar просто прозорий або має стандартний бекграунд AppBar.

---

### 11. ❌ Відсутня валідація фото на формат і розмір

> [!WARNING]
> Вимога (tz_app_2.json): `imageRules` — JPEG/PNG, **max 5MB**, must be photo (not blank).

**Факт:** [image_helper.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/core/utils/image_helper.dart) просто зберігає фото без перевірки формату (JPEG/PNG), розміру (max 5MB) та того, чи це реальне фото.

---

### 12. ❌ Відсутня дата-валідація

> [!NOTE]
> Вимога (tz_app_2.json): `dateFieldRules` — Valid date, not in future.

**Факт:** У [validation_helpers.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/core/utils/validation_helpers.dart) є тільки `validateText` та `validateAmount`. Валідатора дати (`validateDate`) немає.

---

### 13. ❌ Відсутні стани: loading shimmer, empty state з ілюстрацією, error з retry

> [!WARNING]
> Вимога (tz_app_2.json + master_promt.txt): Кожен екран має мати стани — **Shimmer** при завантаженні, мотивуючу **ілюстрацію** при порожніх даних, та **інформативне повідомлення з retry** при помилках.

**Факт:**
- **Loading:** Використовується простий `CircularProgressIndicator`, а не **Shimmer** ефект (вимога: Shimmer для Home, Expenses, Expense Detail, Profile, Analytics, Settings)
- **Empty state:** Простий `Text('No expenses yet')` — без мотивуючих ілюстрацій
- **Error state:** Не реалізований — немає обробки помилок з можливістю retry на жодному екрані

---

### 14. ❌ Відсутній `charts_flutter` — використовується `fl_chart`

> [!NOTE]
> Вимога (tz_app_2.json): Залежність `charts_flutter`.

**Факт:** У [pubspec.yaml:18](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/pubspec.yaml#L18) використовується `fl_chart: ^0.69.0` замість `charts_flutter`. Це інша бібліотека. `charts_flutter` вже давно deprecated, тому `fl_chart` — це навіть краще рішення, але формально це розбіжність з вимогами.

---

### 15. ❌ Preloader не виконує перевірку залежностей

> [!NOTE]
> Вимога (tz_app_2.json + master_promt.txt): На екрані предзавантаження має бути перевірка: camera permissions, storage permissions, local DB availability.

**Факт:** [preloader_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/preloader_screen.dart) лише робить `Future.delayed(2 sec)` та перевіряє `hasSeenOnboarding`. Реальних перевірок дозволів камери, зберігання та доступності БД — немає.

---

### 16. ❌ Профіль доступний тільки в onboarding, немає доступу з Settings

> [!WARNING]
> Вимога (tz_app_2.json): ProfileScreen має навігацію до HomeScreen та **SettingsScreen**. SettingsScreen повинен мати навігацію до **ProfileScreen**.

**Факт:** [settings_screen.dart](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/settings_screen.dart) не має кнопки для переходу до редагування профілю. Після створення профілю під час онбордингу, **змінити ім'я, фото або daily limit неможливо**.

---

### 17. ❌ Додаткові залежності не в специфікації

> [!NOTE]
> Вимога (tz_app_2.json): Залежності — provider, camera, shared_preferences, charts_flutter, in_app_review.

**Факт:** В `pubspec.yaml` додані пакети, яких **немає** в специфікації:
- `url_launcher` (потрібен для Privacy Policy за requirements.txt)
- `share_plus` (потрібен для Share App за requirements.txt)
- `intl`, `uuid`, `image_picker`, `path_provider`, `path`, `permission_handler`

Деякі з них виправдані (url_launcher, share_plus потрібні за requirements.txt), але інші — це інструменти реалізації, не зазначені в ТЗ. Це може бути прийнятно, але варто звернути увагу.

---

### 18. ❌ Валідація name поля ProfileScreen — required, але вимога каже required: false

> [!NOTE]
> Вимога (tz_app_2.json): Поле `userName` має `required: false`.

**Факт:** В [profile_screen.dart:117](file:///c:/Users/Sergiy/Desktop/tz_app_2%20Salary%20Leftovers%20Collector/lib/ui/screens/profile_screen.dart#L117) `validator: ValidationHelpers.validateText` — а `validateText` вимагає обов'язковість (повертає 'Field is required' якщо порожнє). Поле name не повинно бути обов'язковим.

---

## Підсумок

| Категорія | Відповідає | Не відповідає |
|-----------|:----------:|:-------------:|
| Сетап проекту (SDK, лінтер, pubspec) | 7 | 1 |
| Екрани та навігація | 5 | 5 |
| Функціональність | 4 | 6 |
| Валідація | 2 | 3 |
| UI/UX | 3 | 3 |
| **Разом** | **21** | **18** |

> [!IMPORTANT]
> Знайдено **18 невідповідностей**, з яких найкритичніші:
> 1. Нотифікації не реалізовані зовсім
> 2. Відсутні фільтри витрат
> 3. Немає Retake Photo та Export Data
> 4. Loading/Empty/Error стани не проробл ені (немає shimmer, ілюстрацій, retry)
> 5. Профіль неможливо редагувати після створення
