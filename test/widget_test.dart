import 'package:flutter_test/flutter_test.dart';
import 'package:vishnu_enterprises/app.dart';
import 'package:vishnu_enterprises/injection.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    getIt.init();
    await tester.pumpWidget(const EnterpriseApp());
    await tester.pumpAndSettle();
  });
}
