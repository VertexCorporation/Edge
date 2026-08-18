import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension ColorExtension on Color {
  Color get inverted => Color.fromARGB(
        (a * 255.0).round().clamp(0, 255),
        255 - (r * 255.0).round().clamp(0, 255),
        255 - (g * 255.0).round().clamp(0, 255),
        255 - (b * 255.0).round().clamp(0, 255),
      );
}

class ThemeProvider extends ChangeNotifier {
  String _currentTheme;

  ThemeProvider(this._currentTheme) {
    AppColors.currentTheme = _currentTheme;
    updateSystemUIOverlayStyle();
  }

  String get currentTheme => _currentTheme;

  void changeTheme(String theme) async {
    if (_currentTheme == theme) return; // Prevent unnecessary notifications

    _currentTheme = theme;
    AppColors.currentTheme = theme;
    updateSystemUIOverlayStyle();
    notifyListeners(); // This is the ONLY place that should notify.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
  }

  // It's a side effect, not a state change that affects the UI tree.
  void updateSystemUIOverlayStyle() {
    final themeColors = AppColors.getThemeColors(_currentTheme);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        // Enforce transparent for Edge-to-Edge
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            themeColors.navigationBarIconBrightness,
        statusBarIconBrightness: themeColors.statusBarIconBrightness,
      ),
    );
  }
}

class ThemeColors {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color quaternaryColor;
  final Color quinaryColor;
  final Color senaryColor;
  final Color septenaryColor;
  final Color background;
  final Color border;
  final Color premium;
  final Color navigationBarColor;
  final Color statusBarColor;
  final Brightness navigationBarIconBrightness;
  final Brightness statusBarIconBrightness;

  const ThemeColors({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.quaternaryColor,
    required this.quinaryColor,
    required this.senaryColor,
    required this.septenaryColor,
    required this.background,
    required this.border,
    required this.premium,
    required this.navigationBarColor,
    required this.statusBarColor,
    required this.navigationBarIconBrightness,
    required this.statusBarIconBrightness,
  });
}

class AppColors {
  static String _currentTheme = 'light';

  static String get currentTheme => _currentTheme;

  static set currentTheme(String value) {
    _currentTheme = value;
    _cachedColors = _themeDefinitions[value] ?? _themeDefinitions['light']!;
  }

  static final Map<String, ThemeColors> _themeDefinitions = {
    'light': ThemeColors(
      primaryColor: Colors.white,
      secondaryColor: const Color(0xFFF4F6F8),
      tertiaryColor: const Color(0xFF5C6370),
      quaternaryColor: const Color(0xFFE8ECF1),
      quinaryColor: const Color(0xA8000000),
      senaryColor: const Color(0xFF2563EB),
      septenaryColor: const Color(0xFFDC2626),
      background: const Color(0xFFFFFFFF),
      border: const Color(0xFFD0D7E2),
      premium: const Color(0xFF7C3AED),
      navigationBarColor: Colors.white,
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    'dark': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF1C1C1F),
      tertiaryColor: const Color(0xFFA1A1AA),
      quaternaryColor: const Color(0xFF141416),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFF60A5FA),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF0B0B0C),
      border: const Color(0xFF2E2E33),
      premium: const Color(0xFFC4B5FD),
      navigationBarColor: const Color(0xFF0B0B0C),
      statusBarColor: const Color(0xFF0B0B0C),
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'love': ThemeColors(
      primaryColor: Colors.white,
      secondaryColor: const Color(0xFFFFFFFF),
      tertiaryColor: const Color(0xFF9F1239),
      quaternaryColor: const Color(0xFFFFE4EC),
      quinaryColor: const Color(0xA8000000),
      senaryColor: const Color(0xFFE11D48),
      septenaryColor: const Color(0xFFBE123C),
      background: const Color(0xFFFFF1F5),
      border: const Color(0xFFFECDD3),
      premium: const Color(0xFFDB2777),
      navigationBarColor: const Color(0xFFFFF1F5),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    'nature': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF163324),
      tertiaryColor: const Color(0xFFC5E1D2),
      quaternaryColor: const Color(0xFF10261B),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFF4ADE80),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF0B1A12),
      border: const Color(0xFF2D5A40),
      premium: const Color(0xFF86EFAC),
      navigationBarColor: const Color(0xFF0B1A12),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'behindTheSlaughter': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF2A0A4A),
      tertiaryColor: const Color(0xFFE9D5FF),
      quaternaryColor: const Color(0xFF1A0533),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFFC084FC),
      septenaryColor: const Color(0xFFF0ABFC),
      background: const Color(0xFF140022),
      border: const Color(0xFF6B21A8),
      premium: const Color(0xFFF5D0FE),
      navigationBarColor: const Color(0xFF140022),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'grayscale': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF1E2228),
      tertiaryColor: const Color(0xFFC4C8CE),
      quaternaryColor: const Color(0xFF16191D),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFFE8EAED),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF121417),
      border: const Color(0xFF3A3F46),
      premium: const Color(0xFFF5F5F5),
      navigationBarColor: const Color(0xFF121417),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'ocean': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF0C2D4A),
      tertiaryColor: const Color(0xFFB8D4F0),
      quaternaryColor: const Color(0xFF082038),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFF38BDF8),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF061525),
      border: const Color(0xFF1A4F7A),
      premium: const Color(0xFF7DD3FC),
      navigationBarColor: const Color(0xFF061525),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'scarletSnow': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF3B0D16),
      tertiaryColor: const Color(0xFFFECACA),
      quaternaryColor: const Color(0xFF2A0910),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFFFB7185),
      septenaryColor: const Color(0xFFF43F5E),
      background: const Color(0xFF1A0508),
      border: const Color(0xFF7F1D1D),
      premium: const Color(0xFFFDA4AF),
      navigationBarColor: const Color(0xFF1A0508),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'cyberpunk': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF16162A),
      tertiaryColor: const Color(0xFFF0ABFC),
      quaternaryColor: const Color(0xFF10101C),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFF22D3EE),
      septenaryColor: const Color(0xFFFF2D6A),
      background: const Color(0xFF05050A),
      border: const Color(0xFF3F3F6B),
      premium: const Color(0xFF00FFCC),
      navigationBarColor: const Color(0xFF05050A),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'sunset': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF4A1C0C),
      tertiaryColor: const Color(0xFFFED7AA),
      quaternaryColor: const Color(0xFF351408),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFFFB923C),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF1C0A05),
      border: const Color(0xFF9A3412),
      premium: const Color(0xFFFBBF24),
      navigationBarColor: const Color(0xFF1C0A05),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'coffee': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF3D2B22),
      tertiaryColor: const Color(0xFFE8D5C4),
      quaternaryColor: const Color(0xFF2C1E18),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFFD4A574),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF1C1410),
      border: const Color(0xFF6F4E37),
      premium: const Color(0xFFFAEDCD),
      navigationBarColor: const Color(0xFF1C1410),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'deepSpace': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF16162E),
      tertiaryColor: const Color(0xFFC7D2FE),
      quaternaryColor: const Color(0xFF101024),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFF818CF8),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF070712),
      border: const Color(0xFF312E81),
      premium: const Color(0xFFA5B4FC),
      navigationBarColor: const Color(0xFF070712),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'mint': ThemeColors(
      primaryColor: Colors.white,
      secondaryColor: const Color(0xFFFFFFFF),
      tertiaryColor: const Color(0xFF3F6F62),
      quaternaryColor: const Color(0xFFDDF3EB),
      quinaryColor: const Color(0xA8000000),
      senaryColor: const Color(0xFF0D9488),
      septenaryColor: const Color(0xFFDC2626),
      background: const Color(0xFFF3FAF7),
      border: const Color(0xFFB7E4D4),
      premium: const Color(0xFF0F766E),
      navigationBarColor: const Color(0xFFF3FAF7),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    'aurora': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF134E4A),
      tertiaryColor: const Color(0xFF99F6E4),
      quaternaryColor: const Color(0xFF0B3B38),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFF2DD4BF),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF042F2E),
      border: const Color(0xFF0F766E),
      premium: const Color(0xFF5EEAD4),
      navigationBarColor: const Color(0xFF042F2E),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'nord': ThemeColors(
      primaryColor: Colors.white,
      secondaryColor: const Color(0xFFFFFFFF),
      tertiaryColor: const Color(0xFF4C566A),
      quaternaryColor: const Color(0xFFE5E9F0),
      quinaryColor: const Color(0xA8000000),
      senaryColor: const Color(0xFF5E81AC),
      septenaryColor: const Color(0xFFBF616A),
      background: const Color(0xFFECEFF4),
      border: const Color(0xFFD8DEE9),
      premium: const Color(0xFFB48EAD),
      navigationBarColor: const Color(0xFFECEFF4),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    'ember': ThemeColors(
      primaryColor: Colors.black,
      secondaryColor: const Color(0xFF2A1D10),
      tertiaryColor: const Color(0xFFFDE68A),
      quaternaryColor: const Color(0xFF1F160C),
      quinaryColor: Colors.white70,
      senaryColor: const Color(0xFFF59E0B),
      septenaryColor: const Color(0xFFF87171),
      background: const Color(0xFF1A1208),
      border: const Color(0xFF78350F),
      premium: const Color(0xFFFBBF24),
      navigationBarColor: const Color(0xFF1A1208),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    'porcelain': ThemeColors(
      primaryColor: Colors.white,
      secondaryColor: const Color(0xFFFFFFFF),
      tertiaryColor: const Color(0xFF6B5E52),
      quaternaryColor: const Color(0xFFF0E8DC),
      quinaryColor: const Color(0xA8000000),
      senaryColor: const Color(0xFFB45309),
      septenaryColor: const Color(0xFFB91C1C),
      background: const Color(0xFFFAF7F2),
      border: const Color(0xFFE7DFD6),
      premium: const Color(0xFFA16207),
      navigationBarColor: const Color(0xFFFAF7F2),
      statusBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  };

  static Map<String, ThemeColors> get themeDefinitions => _themeDefinitions;

  static const Map<String, String> themeDisplayNames = {
    'light': 'Açık',
    'dark': 'Koyu',
    'love': 'Aşk',
    'nature': 'Doğa',
    'behindTheSlaughter': 'Mor',
    'grayscale': 'Gri',
    'ocean': 'Okyanus',
    'scarletSnow': 'Scarlet',
    'cyberpunk': 'Cyberpunk',
    'sunset': 'Gün Batımı',
    'coffee': 'Kahve',
    'deepSpace': 'Uzay',
    'mint': 'Adaçayı',
    'aurora': 'Aurora',
    'nord': 'Nord',
    'ember': 'Kor',
    'porcelain': 'Porselen',
  };

  static String themeDisplayName(String theme) =>
      themeDisplayNames[theme] ?? theme;

  static bool get isDarkUi => background.computeLuminance() < 0.5;

  /// True only for the built-in black "Koyu" theme key.
  static bool get isBlackTheme => _currentTheme == 'dark';

  /// Uzay and Aşk show pixel sky decorations behind transparent surfaces.
  static bool get hasThemedSky =>
      _currentTheme == 'deepSpace' || _currentTheme == 'love';

  /// Scroll/list backdrop — transparent when sky decorations are active.
  static Color get fogColor => hasThemedSky ? Colors.transparent : background;

  static Color get edgeTitleColor =>
      isDarkUi ? Colors.white : const Color(0xFF111827);

  static const LinearGradient edgeTitleGradient = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeColors _cachedColors = _themeDefinitions['light']!;

  static ThemeColors getThemeColors(String theme) {
    return _themeDefinitions[theme] ?? _themeDefinitions['light']!;
  }

  static Map<String, dynamic> getSystemUIOverlayStyleForTheme(String theme) {
    final themeColors = getThemeColors(theme);
    return {
      'navigationBarColor': themeColors.navigationBarColor,
      'statusBarColor': themeColors.statusBarColor,
      'navigationBarIconBrightness': themeColors.navigationBarIconBrightness,
      'statusBarIconBrightness': themeColors.statusBarIconBrightness,
    };
  }

  static Color get primaryColor => _cachedColors.primaryColor;

  static Color get secondaryColor => _cachedColors.secondaryColor;

  static Color get tertiaryColor => _cachedColors.tertiaryColor;

  static Color get quaternaryColor => _cachedColors.quaternaryColor;

  static Color get quinaryColor => _cachedColors.quinaryColor;

  static Color get senaryColor => _cachedColors.senaryColor;

  static Color get septenaryColor => _cachedColors.septenaryColor;

  static Color get background => _cachedColors.background;

  static Color get border => _cachedColors.border;

  // Accent color reserved for premium/subscription highlights.
  static Color get premium => _cachedColors.premium;

  static Map<String, Map<String, dynamic>> get overlayStyles {
    return _themeDefinitions.map((key, value) => MapEntry(
          key,
          {
            'navigationBarColor': value.navigationBarColor,
            'statusBarColor': value.statusBarColor,
            'navigationBarIconBrightness': value.navigationBarIconBrightness,
            'statusBarIconBrightness': value.statusBarIconBrightness,
          },
        ));
  }

  static List<Color> get animatedBorderGradientColors => [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
        Colors.red,
      ];

  static Color darken(Color color, double amount) {
    final luminance = color.computeLuminance();
    final t = (luminance - 0.5) * 1000;
    final blendFactor = (t.sign + 1) / 2;
    final targetColor = Color.lerp(Colors.white, Colors.black, blendFactor)!;
    return Color.lerp(color, targetColor, amount)!;
  }

  static Color get shimmerBase => darken(background, 0.1);

  static Color get shimmerHighlight => darken(background, 0.02);
}
