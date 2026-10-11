# Матриця сумісності, межі продукту та план відкату (COMPATIBILITY_AND_ROLLBACK.md)

Цей документ визначає технологічні кордони стабільності **MusicFlow Mobile**, матрицю сумісності пристроїв, розподіл підсистем за пріоритетом надійності та регламент аварійного відкату оновлень.

---

## 1. Розподіл компонентів за рівнями надійності (Scope Boundaries)

Щоб уникнути "роздування скоупу" та падіння стабільності на етапі підтримки, усі модулі проєкту чітко розмежовані на 4 рівні:

```mermaid
graph TD
    subgraph Tier1 [Tier 1: Core - 100% Zero-Crash Guarantee]
        T1_1[Локальне відтворення MP3/FLAC/M4A]
        T1_2[Foreground Service + Lockscreen Controls]
        T1_3[База даних SQLite v3 + Кеш метаданих]
        T1_4[Головний UI: Плеєр, Міні-бар, Списки]
    end

    subgraph Tier2 [Tier 2: Platform-Specific - Native Integration]
        T2_1[Kotlin VisualizerHandler - AudioEffect API]
        T2_2[MediaScannerHandler - Оновлення MediaStore]
        T2_3[ApkInstallerHandler - FileProvider Intent]
        T2_4[Керування фокусом аудіо - Audio Focus & Noisy Audio]
    end

    subgraph Tier3 [Tier 3: Connected - Мережева надійність]
        T3_1[YouTube Explode + 403 Exponential Backoff]
        T3_2[LRCLIB API + Караоке таймінги]
        T3_3[OTA Оновлення з SHA-256 Checksum валідацією]
        T3_4[Анонімна телеметрія збоїв]
    end

    subgraph Tier4 [Tier 4: Experimental / Visual Polish]
        T4_1[Hardware FFT інтерполяція бінів]
        T4_2[Світловий GPU шейдер Flowing Ambient Glow 28px]
        T4_3[Динамічні повзунки фізики візуалізатора]
    end
```

### Регламент стабільності:
* **Збій у Tier 4** (наприклад, апаратний візуалізатор не зміг ініціалізуватися) **НІКОЛИ не повинен зупиняти відтворення звуку** (Tier 1) — автоматичний фолбек на статичний режим або Software ядро.
* **Збій у Tier 3** (зникнення інтернету, помилка 403) повинен переводити додаток у стан "Очікування мережі / Відтворення з локального кешу" без зависання UI.

---

## 2. Матриця сумісності пристроїв (Compatibility Matrix)

| Параметр | Мінімальні вимоги | Рекомендовані вимоги |
|---|---|---|
| **Версія Android OS** | **Android 8.0 (API Level 26)** | **Android 11–15 (API Level 30–35)** |
| **Архітектура CPU** | `armeabi-v7a` (32-bit), `arm64-v8a` (64-bit), `x86_64` | `arm64-v8a` |
| **Графічний рушій** | OpenGLES 3.0 / Skia | Vulkan / Impeller |
| **Оперативна пам'ять (RAM)** | 2.0 ГБ (споживання додатком < 150 МБ) | 4.0 ГБ+ |
| **Роздільна здатність екрана** | HD (720x1280) | FHD+ (1080x2400) / QHD+ |
| **Підтримка AudioEffect** | Базова (доступна у 95% прошивок) | Повна підтримка апаратного Visualizer |

---

## 3. Регламент безпечних міграцій бази даних (SQLite Migrations)

База даних `music_flow_v3.db` використовує строге версіонування схеми:

1. **Правило збереження даних:** Жодна міграція не має права викликати `DROP TABLE` для таблиць користувацької медіатеки або історії.
2. **Транзакційність:** Усі зміни структури (`ALTER TABLE ADD COLUMN`) виконуються всередині `db.transaction(...)`.
3. **Хеш-перевірка схеми:** При додаванні нових колонок у моделі перевіряється існування поля перед запитом для усунення падінь на старіших версіях.

---

## 4. План аварійного відкату релізу (Emergency Rollback Plan)

Якщо у випущеному релізі виявлено блокуючий регрес (наприклад, краш на специфічній моделі смартфона):

```mermaid
sequenceDiagram
    participant Dev as Розробник
    participant Git as GitHub
    participant Server as Update Server
    participant User as Смартфон користувача

    Note over Dev,Server: 1. Виявлення критичного багу
    Dev->>Server: Запуск: python server/publish_release.py --rollback
    Server->>Server: Підміна app-release.apk на стабільний попередній білд
    Server->>Server: Інкремент buildNumber у version.json із позначкою [HOTFIX-ROLLBACK]
    User->>Server: Запит оновлень (/api/update/check)
    Server-->>User: Повернення стабільного білда з більшим buildNumber
    User->>User: Фонова верифікація SHA-256 + встановлення стабільної версії
```

### Кроки швидкого відкату:
1. **Збереження попереднього білда:** Пайплайн завжди зберігає попередній скомпільований білд як `server/data/updates/app-release-previous.apk`.
2. **Hotfix випуск:** Скрипт `publish_release.py` випускає версію з інкрементованим `buildNumber`, але вмістом стабільного коду. Оскільки Android Package Manager не дозволяє даунгрейд за `versionCode`, відкат завжди оформлюється як новий білд із перевіреною базою.
3. **Хмарний відкат:** На GitHub створюється реліз із позначкою `vX.Y.Z-hotfix`.
