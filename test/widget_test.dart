import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlookfor/main.dart';

void main() {
  testWidgets('LookFor app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LookForApp());
    await tester.pumpAndSettle();

    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('Look'), findsWidgets);
    expect(find.text('For'), findsWidgets);
  });
}
