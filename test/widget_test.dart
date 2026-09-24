// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atlas_flutter/main.dart';
import 'package:atlas_flutter/providers/preferences_provider.dart';

void main() {
  testWidgets('AtlasApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PreferencesProvider(),
        child: const AtlasApp(),
      ),
    );

    expect(find.byType(AtlasApp), findsOneWidget);
  });
}

