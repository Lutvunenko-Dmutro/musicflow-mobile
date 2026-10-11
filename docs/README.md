# 📚 Технічна документація MusicFlow Mobile

Цей каталог містить структуровану документацію проекту, розбиту за основними інженерними напрямками.

---

## 🗂️ Структура каталогу

```
docs/
├── architecture/      # Системна архітектура, UML, аудіо-ядро, FFT-візуалізатор та сервіси
├── planning/          # Вимоги до продукту (PRD), дорожня карта (PLAN) та оркестрація
├── release/           # Пайплайн оновлень, чек-листи, безпека, відкат та локальний сервер
├── quality/           # Аудит кодової бази, метрики SLA та відомі проблеми/TODO
└── README.md          # Головний навігатор документації (цей файл)
```

---

## 🏗️ 1. Архітектура та Системні Модулі (`architecture/`)

| Документ | Опис | Ключові теми |
|---|---|---|
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | Загальна системна архітектура | Багаторівнева структура, модульні міксини, Impeller, SQLite |
| [UPDATE_SYSTEM_ARCHITECTURE.md](architecture/UPDATE_SYSTEM_ARCHITECTURE.md) | Архітектура оновлень з UML-діаграмами | Component/Sequence/State діаграми, перемикання Release/Debug, SHA-256 |
| [LOCAL_SERVER_AND_DEVICE_TELEMETRY.md](architecture/LOCAL_SERVER_AND_DEVICE_TELEMETRY.md) | Моніторинг пристроїв та Heartbeat | Прямий зв'язок додатку з сервером, життєвий цикл, State Machine, API |
| [architecture_audio_provider.md](architecture/architecture_audio_provider.md) | Ядро відтворення та стан аудіоплеєра | `AudioProvider`, модульні міксини, потік відтворення треків |
| [visualizer_system.md](architecture/visualizer_system.md) | FFT-візуалізатор спектру частот | Software (fftea) + Hardware (Android Visualizer), оптимізація 60 FPS |
| [services.md](architecture/services.md) | Каталог сервісів додатку | YouTube, SQLite база даних, Download, Lyrics, Native Handlers |

---

## 📋 2. Планування та Вимоги (`planning/`)

| Документ | Опис | Ключові теми |
|---|---|---|
| [PRD.md](planning/PRD.md) | Product Requirements Document | Продуктові вимоги, цільова аудиторія, сценарії використання |
| [PLAN.md](planning/PLAN.md) | Дорожня карта та план реалізації | Етапи розробки, спринти, завершені та заплановані задачі |
| [ORCHESTRATION.md](planning/ORCHESTRATION.md) | ШІ-Оркестрація та агенти | Ролі агентів, робочі процеси та протоколи автоматизації |

---

## 🚀 3. Релізи, CI/CD та Розгортання (`release/`)

| Документ | Опис | Ключові теми |
|---|---|---|
| [ONE_CLICK_RELEASE.md](release/ONE_CLICK_RELEASE.md) | Збірка та публікація в 1 клік | Автоматизований пайплайн publish.bat, валідація, версіонування |
| [RELEASE_CHECKLIST.md](release/RELEASE_CHECKLIST.md) | Інженерний чек-лист випуску релізу | Покроковий план перевірок перед публікацією білда |
| [SECURITY_UPDATE_FLOW.md](release/SECURITY_UPDATE_FLOW.md) | Безпека та верифікація оновлень | Перевірка підписів APK, валідація SHA-256, захист від підміни |
| [COMPATIBILITY_AND_ROLLBACK.md](release/COMPATIBILITY_AND_ROLLBACK.md) | Матриця сумісності та план відкату | Anti-downgrade правила, аварійний rollback, міграції БД SQLite |
| [SETUP_LOCAL_SERVER.md](release/SETUP_LOCAL_SERVER.md) | Автономний Python-сервер роздачі | Тестування оновлень по Wi-Fi та веб-дашборд телеметрії збоїв |

---

## 🎯 4. Якість, Аудит та Метрики (`quality/`)

| Документ | Опис | Ключові теми |
|---|---|---|
| [QUALITY_METRICS.md](quality/QUALITY_METRICS.md) | Ключові метрики якості та SLA | Вимоги до швидкодії, споживання пам'яті, покриття тестами |
| [audit.md](quality/audit.md) | Повний технічний аудит кодової бази | Аналіз вразливостей, сильні сторони, залишкові технічні борги |
| [known_issues_todo.md](quality/known_issues_todo.md) | Відомі проблеми та Roadmap виправлень | Список невирішених багів, де шукати при дебагу |

---

## 🚀 Порядок ознайомлення для нових інженерів (Onboarding)

1. **Загальний огляд:** [README.md](../README.md) у корені репозиторію.
2. **Вимоги та цілі:** [PRD.md](planning/PRD.md) та [PLAN.md](planning/PLAN.md).
3. **Архітектура коду:** [ARCHITECTURE.md](architecture/ARCHITECTURE.md) та [architecture_audio_provider.md](architecture/architecture_audio_provider.md).
4. **Система оновлень:** [UPDATE_SYSTEM_ARCHITECTURE.md](architecture/UPDATE_SYSTEM_ARCHITECTURE.md).
5. **Перед внесенням змін:** [known_issues_todo.md](quality/known_issues_todo.md) та [RELEASE_CHECKLIST.md](release/RELEASE_CHECKLIST.md).
