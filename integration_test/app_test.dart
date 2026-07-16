import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Wichtig: Verwende deinen echten Projektnamen
import 'package:flutter_application_1/main.dart'; 


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End (E2E) Spiel-Fluss Test', () {
    testWidgets(
      'Sollte Charakter erstellen erlauben',
      (WidgetTester tester) async {
        // App starten
        await tester.pumpWidget(const ChatBotApp());
        await tester.pumpAndSettle();

        // Auf "Spiel Erstellen" klicken
        final spielErstellenBtn = find.text('Spiel Erstellen');
        expect(spielErstellenBtn, findsOneWidget);

        await tester.tap(spielErstellenBtn);
        await tester.pumpAndSettle();

        // Prüfen ob SetupScreen geladen wurde
        expect(find.text('CHARAKTER-SCHMIEDE'), findsOneWidget);

        // API-Key Feld finden
        final apiKeyField = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'AQ. ...',
        );

        // Namensfeld finden
        final nameField = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Euer Name...',
        );

        expect(apiKeyField, findsOneWidget);
        expect(nameField, findsOneWidget);

        // Testdaten eingeben
        await tester.enterText(apiKeyField, 'TEST_API_KEY');
        await tester.enterText(nameField, 'TestHeld');

        await tester.pumpAndSettle();

        // Überprüfen ob Text eingetragen wurde
        expect(find.text('TestHeld'), findsOneWidget);
      },
    );
  });
}