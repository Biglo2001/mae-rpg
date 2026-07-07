import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ERSETZE 'dein_projekt_name' durch deinen tatsächlichen Projektnamen
import 'package:flutter_application_1/main.dart'; 

void main() {
  testWidgets('InventoryScreen listet Gegenstände und Mengen korrekt auf', (WidgetTester tester) async {
    // 1. Arrange: Eine simulierte Item-Liste erstellen
    final mockInventory = [
      InventoryItem(
        name: 'Heiltrank',
        description: 'Heilt 30 HP.',
        quantity: 3,
        icon: Icons.science,
        iconColor: Colors.red,
      ),
      InventoryItem(
        name: 'Eisenschwert',
        description: 'Scharfe Klinge.',
        quantity: 1,
        icon: Icons.gavel,
        iconColor: Colors.grey,
      ),
    ];

    // 2. Act: Inventar-Widget rendern
    await tester.pumpWidget(MaterialApp(
      home: InventoryScreen(inventory: mockInventory),
    ));

    // 3. Assert: Überschrift prüfen
    expect(find.text('BEUTEL & INVENTAR'), findsOneWidget);
    
    // Prüfen, ob das erste Item und seine Menge existiert
    expect(find.text('Heiltrank'), findsOneWidget);
    expect(find.text('x3'), findsOneWidget);
    
    // Prüfen, ob das zweite Item und seine Menge existiert
    expect(find.text('Eisenschwert'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });
}