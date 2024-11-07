import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metasampler/main.dart';
import 'package:metasampler/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(App(project: ValueNotifier(null)));
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
