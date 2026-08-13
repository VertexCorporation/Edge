import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edge/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeProvider loads and persists theme changes', () async {
    final provider = ThemeProvider('light');
    expect(provider.currentTheme, 'light');
    expect(AppColors.currentTheme, 'light');

    provider.changeTheme('dark');
    await Future<void>.delayed(Duration.zero);

    expect(provider.currentTheme, 'dark');
    expect(AppColors.currentTheme, 'dark');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selectedTheme'), 'dark');
  });
}
