import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_printer/app_shell.dart';

void main() {
  testWidgets('Home screen shows Smart Printer actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump();

    expect(find.text('Smart Printer'), findsOneWidget);
    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Scan Document'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Labels'), findsOneWidget);
    expect(find.text('Printables'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Webpages'), findsOneWidget);
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
