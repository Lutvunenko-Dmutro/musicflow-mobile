# 📚 Документація MusicFlow Mobile

## Навігація

| Файл | Що всередині |
|---|---|
| [README.md](../README.md) | Огляд проекту, стек, запуск |
| [architecture_audio_provider.md](architecture_audio_provider.md) | Як влаштований AudioProvider + mixins + потік відтворення |
| [visualizer_system.md](visualizer_system.md) | Вся система візуалізатора: Android → Flutter → Canvas |
| [services.md](services.md) | Всі сервіси: YouTube, БД, Download, Lyrics, Native |
| [audit.md](audit.md) | 🔍 Повний аудит: сильні/слабкі сторони, вразливості, план фіксів |
| [known_issues_todo.md](known_issues_todo.md) | ⚠️ Баги, TODO, де шукати при дебагу |

---

## З чого почати якщо ти новий у проекті?

1. **Прочитай [README.md](../README.md)** — загальний огляд
2. **Прочитай [architecture_audio_provider.md](architecture_audio_provider.md)** — зрозумієш як влаштовано ядро
3. **Прочитай [visualizer_system.md](visualizer_system.md)** — якщо торкаєшся FFT або Android native
4. **Прочитай [known_issues_todo.md](known_issues_todo.md)** — щоб не фіксити вже відомі речі

## Хочу щось зробити — де дивитись?

| Задача | Файл для читання |
|---|---|
| Змінити логіку відтворення | [architecture_audio_provider.md](architecture_audio_provider.md) |
| Налаштувати FFT / кольори смужок | [visualizer_system.md](visualizer_system.md) → `fft_tuning.dart` |
| Підключити новий API | [services.md](services.md) |
| Подивитись що ще треба зробити | [known_issues_todo.md](known_issues_todo.md) |
