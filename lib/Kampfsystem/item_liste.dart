import 'item.dart';

// ✅ Klasse für die Item-Liste
class ItemListe {
  final List<Item> _items;
  //Konstruktor
  ItemListe() : _items = [];

  // ✅ Getter für alle Items
  List<Item> get alleItems => _items;

  // ✅ Einzelnes Item holen
  Item getItem(int index) {
    return _items[index];
  }

  // ✅ Neues Item hinzufügen
  void addItem(Item item) {
    _items.add(item);
  }

  void entferenItem(Item item) {
    _items.remove(item);
  }

  // ✅ toJson
  List<Map<String, dynamic>> toJson() {
    return _items.map((item) => item.toJson()).toList();
  }

  // ✅ fromJson
  factory ItemListe.fromJson(List<dynamic>? json) {
    ItemListe itemListe = ItemListe();

    if (json == null) {
      return itemListe;
    }

    for (var itemJson in json) {
      if (itemJson != null) {
        itemListe.addItem(
          Item.fromJson(Map<String, dynamic>.from(itemJson)),
        );
      }
    }

    return itemListe;
  }
}
