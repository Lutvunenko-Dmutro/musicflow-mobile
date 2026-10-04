class FftTuning {
  // 1. Динамічний діапазон
  //    noiseFloor  = нижня межа (сигнали нижче цього = 0%)
  //    maxDbOffset = СТЕЛЯ для басів. Для інших кольорів стеля = maxDbOffset + 20*log10(weight)
  //    ВАЖЛИВО: чим МЕНШ НЕГАТИВНЕ maxDbOffset — тим ВИЩА стеля (менше кліпінгу)
  static const double noiseFloor  = -55.0; // Більший діапазон = більше деталей
  static const double maxDbOffset =   3.0; // +3 dB headroom: смужки не б'ють у стелю при максимальній гучності

  // 2. Множники для кожного кольору (відкалібровано без перевантаження)
  static const double weightRed    = 0.55; // 🟥 Баси
  static const double weightOrange = 1.8;  // 🟧 Нижня середина
  static const double weightYellow = 2.8;  // 🟨 Вокал / піаніно
  static const double weightBlue   = 4.2;  // 🟦 Тарілки
  
  // 3. Різкість (Punch) для КОЖНОГО кольору (чим вище, тим різкіше падає смужка)
  static const double punchRed    = 1.2; // трохи плавніший підйом для басів
  static const double punchOrange = 1.5;
  static const double punchYellow = 1.5;
  static const double punchBlue   = 1.5;

  // 4. Згладжування (Spatial Smoothing)
  static const double smoothSelf     = 0.70; // 70% від себе — більше незалежності
  static const double smoothNeighbor = 0.15; // 15% від сусідів — смужки більш розрізнимі

  
  static const List<double> barFrequencies = [
    // 🟥 Red (24 bars) - 30Hz to 800Hz (Захоплює Бочку, Бас-гітару, Томи і Робочий барабан!)
    30, 40, 50, 60, 70, 80, 95, 110, 125, 140, 160, 180, 205, 230, 260, 290, 325, 365, 410, 460, 520, 590, 670, 760,
    // 🟧 Orange (18 bars) - 860Hz to 3900Hz (Вокал, Гітари, Синтезатори)
    860, 960, 1070, 1190, 1320, 1460, 1610, 1770, 1940, 2120, 2310, 2510, 2720, 2940, 3170, 3410, 3660, 3920,
    // 🟨 Жовті (12 bars) - 4200Hz to 7300Hz (Скрипки, Тарілочки)
    4200, 4400, 4650, 4900, 5200, 5500, 5800, 6100, 6400, 6700, 7000, 7300,
    // 🟦 Сині (6 bars) - 7600Hz to 10000Hz (Свист, Хай-хети)
    7600, 8000, 8400, 8800, 9400, 10000,
  ];
}
