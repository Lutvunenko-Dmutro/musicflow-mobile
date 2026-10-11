# 🚀 Архітектура та UML-специфікація системи оновлень MusicFlow Mobile

Цей документ містить повний технічний опис підсистеми оновлень, діаграми взаємодії компонентів (UML), логіку перемикання каналів (Release / Debug) та покроковий інженерний план для координації релізів.

---

## 1. Загальна компонентна архітектура (UML Component Diagram)

Система оновлень складається з трьох ключових середовищ:
1. **Developer Environment (Робоча станція):** локальний менеджер релізів, Flutter SDK, Java 17 LTS, Gradle.
2. **Distribution Hub (GitHub Releases):** хмарне сховище бінарників APK (`app-release.apk`, `app-debug.apk`), тегів і контрольних сум SHA-256.
3. **Mobile Client (Мобільний додаток):** Flutter-шар перевірки/завантаження + Kotlin Native шар взаємодії з Android OS.

```mermaid
graph TD
    subgraph DevPC ["💻 Робоча станція (Developer PC)"]
        Bat["publish_to_github_local.bat"] --> Py["publish_manager.py"]
        Py --> Test["flutter analyze & test"]
        Py --> BuildRel["flutter build apk --release"]
        Py --> BuildDbg["flutter build apk --debug"]
        Py --> Hash["hashlib SHA-256 Calc"]
        Py --> GitGH["gh release create / git push"]
    end

    subgraph GitHub ["☁️ GitHub Cloud Hub"]
        GH_Repo["Git Repository (main branch)"]
        GH_Rel["GitHub Releases (vX.Y.Z)"]
        GH_Assets["Assets:\n• app-release.apk\n• app-debug.apk\n• release_notes (SHA-256)"]
        GH_Rel --> GH_Assets
    end

    subgraph MobileApp ["📱 MusicFlow Mobile App"]
        subgraph UI ["Шар інтерфейсу (Flutter UI)"]
            SettingsCard["UpdateSettingsCard\n(Вибір частоти та каналу)"]
            Dialog["UpdateDialog\n(Прогрес, SHA-256, розмір)"]
            Changelog["UpdateChangelogView\n(Очищення markdown)"]
        end

        subgraph CoreService ["Сервісний шар (Dart)"]
            Prefs["UpdatePreferences\n(Канал, частота, таймінги)"]
            Svc["UpdateService\n(Координатор оновлень)"]
            GHClient["GithubUpdateClient\n(API парсер GitHub)"]
            Downloader["UpdateDownloader\n(Стрімінг завантаження)"]
        end

        subgraph NativeLayer ["Нативний шар Android (Kotlin)"]
            Channel["MethodChannel:\ncom.example.music_flow_mobile/installer"]
            Installer["ApkInstallerHandler.kt"]
            Prov["FileProvider"]
            PkgMgr["Android PackageInstaller"]
        end
    end

    GitGH -->|git push| GH_Repo
    GitGH -->|gh release create| GH_Rel

    GHClient -->|GET /repos/.../releases| GH_Rel
    Downloader -->|Download Stream| GH_Assets
    Installer --> Prov --> PkgMgr
    Svc --> Channel --> Installer
```

---

## 2. Діаграма послідовності випуску релізу (UML Sequence: Release Pipeline)

Ця діаграма показує, як скрипт `publish_manager.py` автономно верифікує та публікує версію на GitHub.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Розробник
    participant Script as publish_manager.py
    participant Flutter as Flutter & Gradle
    participant Git as Git CLI
    participant GH as GitHub CLI (gh)
    participant Cloud as GitHub API & CDN

    Dev->>Script: Запуск через publish_to_github_local.bat
    Script->>Script: Налаштування Java 17 LTS (Adoptium)
    Script->>Script: Читання pubspec.yaml та розрахунок vX.Y.Z+Build
    Script->>Git: git log (генерація автоматичного опису змін)
    
    rect rgb(20, 35, 20)
        note over Script,Flutter: Фаза перевірки якості коду
        Script->>Flutter: flutter analyze
        Flutter-->>Script: 0 помилок (0 issues)
        Script->>Flutter: flutter test
        Flutter-->>Script: 63/63 тестів успішно
    end

    rect rgb(35, 30, 20)
        note over Script,Flutter: Фаза бінарної збірки
        Script->>Flutter: flutter build apk --release
        Flutter-->>Script: build/.../app-release.apk
        Script->>Flutter: flutter build apk --debug
        Flutter-->>Script: build/.../app-debug.apk
    end

    Script->>Script: Розрахунок хешів SHA-256 для обох APK

    rect rgb(20, 30, 45)
        note over Script,Cloud: Фаза публікації та гітінгу
        Script->>Git: git add pubspec.yaml && git commit
        Script->>Git: git push origin main
        alt Мережева помилка (Could not resolve host)
            Git-->>Script: fatal: unable to access github.com
            Script-->>Dev: [ПОМИЛКА МЕРЕЖІ] Збірка збережена локально, потрібен retry!
        else Успішний зв'язок
            Git-->>Script: 200 OK pushed
            Script->>GH: gh release create vX.Y.Z app-release.apk app-debug.apk -F notes.txt
            GH->>Cloud: Upload assets & Publish
            Cloud-->>GH: Реліз опубліковано
            GH-->>Script: Успіх
            Script-->>Dev: Реліз vX.Y.Z доступний для оновлення!
        end
    end
```

---

## 3. Діаграма послідовності перевірки та перемикання каналів у додатку (UML Sequence: Client In-App Updater)

Діаграма демонструє логіку, коли на телефоні встановлено **Release**, а користувач обирає **Debug** (або навпаки).

```mermaid
sequenceDiagram
    autonumber
    actor User as Користувач
    participant UI as UpdateSettingsCard
    participant Svc as UpdateService
    participant Prefs as UpdatePreferences
    participant GHClient as GithubUpdateClient
    participant Dialog as UpdateDialog
    participant Downloader as UpdateDownloader
    participant Native as ApkInstallerHandler.kt

    User->>UI: Обирає канал "Debug" у списку
    UI->>Prefs: setChannel(UpdateChannel.debug)
    User->>UI: Натискає «Перевірити оновлення зараз»
    
    UI->>Svc: checkForUpdate(allowChannelSwitch: true)
    Svc->>Prefs: getChannel() -> debug
    Svc->>Prefs: currentRunningChannel -> release (kDebugMode=false)
    
    Svc->>GHClient: checkLatestRelease(targetChannel="debug", allowChannelSwitch=true)
    GHClient->>GHClient: Отримання останнього тегу з GitHub API
    GHClient->>GHClient: targetApkName = "debug.apk"
    GHClient->>GHClient: isChannelSwitch = ("debug" != "release") -> TRUE!
    
    note over GHClient: Умова: isNewer || force || (allowChannelSwitch && isChannelSwitch)<br/>Спрацьовує перемикання каналу!
    
    GHClient-->>Svc: UpdateInfo(channel="debug", isChannelSwitch=true, sha256=...)
    Svc-->>UI: UpdateInfo
    
    UI->>Dialog: UpdateDialog.show(context, info)
    note over Dialog: Заголовок: "Зміна каналу (DEBUG)"<br/>Чейнджлог очищено від ### та **<br/>Відображено SHA-256
    
    User->>Dialog: Натискає «Завантажити та перейти»
    Dialog->>Downloader: downloadApk(info)
    Downloader-->>Dialog: Стрімінг байтів (прогрес-бар 0%..100%)
    Downloader-->>Dialog: Файл app-debug.apk збережено
    
    Dialog->>Svc: installApk(file, info)
    note over Svc: info.isChannelSwitch == true,<br/>тому anti-downgrade не блокує установку!
    Svc->>Native: MethodChannel.invoke("installApk", filePath)
    Native->>Native: FileProvider.getUriForFile()
    Native->>User: Відкриття стандартного інсталятора Android OS
```

---

## 4. Діаграма станів клієнта оновлень (UML State Machine)

```mermaid
stateDiagram-v2
    [*] --> Idle: Додаток запущено

    Idle --> Checking: Ручний клік або автоперевірка за таймером
    
    state Checking {
        [*] --> FetchingGithub: Запит до GitHub API
        FetchingGithub --> Evaluating: Отримано метадані релізу
        
        state Evaluating <<choice>>
        Evaluating --> SameVersionSameChannel: remoteBuild == localBuild && targetChannel == runningChannel
        Evaluating --> NewerBuildAvailable: remoteBuild > localBuild
        Evaluating --> ChannelSwitchNeeded: targetChannel != runningChannel
    }

    SameVersionSameChannel --> Idle: Показ SnackBar "Встановлена найновіша версія"
    
    NewerBuildAvailable --> UpdateModalReady: isChannelSwitch = false
    ChannelSwitchNeeded --> UpdateModalReady: isChannelSwitch = true

    state UpdateModalReady {
        [*] --> DisplayDialog: Показ форми (версія, розмір, бейдж каналу)
        DisplayDialog --> CleanChangelog: Парсинг чейнджлогу (вирізання #, **, sha)
    }

    UpdateModalReady --> Downloading: Клік "Завантажити"
    UpdateModalReady --> Idle: Клік "Пізніше" / Dismiss

    state Downloading {
        [*] --> StreamBytes: Завантаження по чанках
        StreamBytes --> StreamBytes: Оновлення прогресу (MB / %)
        StreamBytes --> FileReady: Завантаження завершено
    }

    Downloading --> ErrorState: Обрив мережі / Таймаут
    ErrorState --> UpdateModalReady: Кнопка "Спробувати знову"

    FileReady --> Verifying: Перевірка цілісності
    Verifying --> Installing: Виклик MethodChannel installApk
    Installing --> [*]: Перехід в інсталятор Android OS
```

---

## 5. Матриця рішень: Поведінка Update Engine

Ця таблиця визначає точну логіку, яку виконує клієнт за будь-яких умов:

| Поточний встановлений додаток | Обраний канал у налаштуваннях | Версія на GitHub | Результат перевірки | UI повідомлення |
|---|---|---|---|---|
| **Release** (v0.1.2) | **Release** | v0.1.2 | `info = null` | "У вас встановлена найновіша версія! 🎉" |
| **Release** (v0.1.2) | **Release** | v0.1.3 | `info != null` (`isChannelSwitch: false`) | Діалог: "Нове оновлення! v0.1.3 (RELEASE)" |
| **Release** (v0.1.2) | **Debug** | v0.1.2 | `info != null` (`isChannelSwitch: true`) | Діалог: **"Зміна каналу (DEBUG)"** (217 MB) |
| **Debug** (v0.1.2) | **Release** | v0.1.2 | `info != null` (`isChannelSwitch: true`) | Діалог: **"Зміна каналу (RELEASE)"** (66 MB) |
| **Debug** (v0.1.2) | **Debug** | v0.1.2 | `info = null` | "У вас встановлена найновіша версія! 🎉" |
| Будь-який | Будь-який | Немає мережі / DNS помилка | `info = null` (із записом у лог) | Тихий fallback без падіння додатку |

---

## 6. Інженерний протокол дій (Operational Playbook для координатора)

### Випадок: Помилка мережі при релізі (`Could not resolve host: github.com`)
У лозі розробника видно:
```
fatal: unable to access 'https://github.com/...': Could not resolve host: github.com
error connecting to api.github.com
```
**Чому це сталося:**
Скрипт успішно виконав `flutter analyze`, всі тести, збірку `app-release.apk` і `app-debug.apk`, і створив локальний коміт версії. Але в момент звернення до серверів GitHub зник інтернет або підвів DNS-сервер Windows.

**Як завершити публікацію за 1 хвилину без перезбірки:**
Коли інтернет активний:
1. Запустити пуш накопиченого коміту:
   ```powershell
   git push origin main
   ```
2. Опублікувати вже готові зібрані APK однією командою через GitHub CLI:
   ```powershell
   gh release create v0.1.2 build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\app-debug.apk --title "MusicFlow v0.1.2 (build 3)" --notes "### 📦 Оновлення MusicFlow Mobile v0.1.2`n`n* Покращення системи оновлень та очищення чейнджлогу"
   ```
3. Або просто повторно запустити `publish_to_github_local.bat` при відновленні з'єднання.
