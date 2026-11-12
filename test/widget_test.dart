import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/main.dart';

void main() {
  testWidgets('SuaraSiswaApp launches smoke test', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SuaraSiswaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app renders with branding
    expect(find.byType(SuaraSiswaApp), findsOneWidget);
  });
}
