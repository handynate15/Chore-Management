import 'package:flutter_test/flutter_test.dart';
import 'package:ontrack/main.dart';

void main() {
  testWidgets('OnTrackFam app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OnTrackFamApp());
    expect(find.byType(OnTrackFamApp), findsOneWidget);
  });
}
