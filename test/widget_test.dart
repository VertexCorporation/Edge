import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edge/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeProvider loads and persists accent/darkMode changes', () async {
    final provider = ThemeProvider(accentTheme: 'default', darkMode: false);
    expect(provider.accentTheme, 'default');
    expect(provider.darkMode, false);

    provider.changeAccent('love');
    await Future<void>.delayed(Duration.zero);
    expect(provider.accentTheme, 'love');

    provider.setDarkMode(true);
    await Future<void>.delayed(Duration.zero);
    expect(provider.darkMode, true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('accentTheme'), 'love');
    expect(prefs.getBool('darkMode'), true);
  });
}
