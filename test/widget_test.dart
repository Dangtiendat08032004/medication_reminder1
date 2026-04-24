import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Text('Test placeholder'),
      ),
    ));

    expect(find.text('Test placeholder'), findsOneWidget);
  });
}
