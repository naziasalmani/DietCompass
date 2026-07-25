import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/features/splash/splash_screen.dart';
import 'package:diet_compass/main.dart';

void main() {
  testWidgets('DietCompass app launches splash screen', (tester) async {
    await tester.pumpWidget(const DietCompassApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Loading your healthy journey...'), findsOneWidget);
  });
}
