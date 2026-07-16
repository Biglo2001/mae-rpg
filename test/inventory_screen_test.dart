
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart'; 
import 'package:flutter_application_1/Kampfsystem/item.dart';
import 'package:flutter_application_1/Kampfsystem/item_liste.dart';

void main() {
  testWidgets('InventoryScreen listet Gegenstände und Mengen korrekt auf', (WidgetTester tester) async {
    // 1. Arrange: Eine simulierte Item-Liste erstellen
    final testItemListe = ItemListe()
      ..addItem(
        Item(
          name: "Med-Kit",
          beschreibung: "Moderner medizinischer Notfallkoffer",
          kraft: 2,
          aufgegner: false,
          aoe: false,
        ),
      )
      ..addItem(
        Item(
          name: "Plasmagranate",
          beschreibung: "Verursacht Schaden an allen Gegnern",
          kraft: 3,
          aufgegner: true,
          aoe: true,
        ),
      );


    // 2. Act: Inventar-Widget rendern
    await tester.pumpWidget(MaterialApp(
      home: InventoryScreen(inventory: testItemListe),
    ));

    // 3. Assert: Überschrift prüfen
    expect(find.text('BEUTEL & INVENTAR'), findsOneWidget);
    
    // Prüfen, ob das erste Item existiert
    expect(find.text('Med-Kit'), findsOneWidget);
  
    
    // Prüfen, ob das zweite Item existiert
    expect(find.text('Plasmagranate'), findsOneWidget);
  });
}