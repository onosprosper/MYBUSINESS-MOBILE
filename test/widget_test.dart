import 'package:flutter_test/flutter_test.dart';
import 'package:mybusiness_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App opens the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyBusinessApp());
    await tester.pumpAndSettle();

    expect(find.text('MYBUSINESS'), findsWidgets);
  });
}
