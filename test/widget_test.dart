import 'package:flutter_test/flutter_test.dart';
import 'package:ontrack/main.dart';

void main() {
  testWidgets('OnTrack app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OnTrackApp());
    expect(find.byType(OnTrackApp), findsOneWidget);
  });
}
