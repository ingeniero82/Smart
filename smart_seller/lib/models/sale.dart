import 'package:isar/isar.dart';

part 'sale.g.dart';

@collection
class Sale {
  Id id = Isar.autoIncrement;
  late DateTime date;
  late double total;
  late String user;
  late List<SaleItem> items;
}

@embedded
class SaleItem {
  late String name;
  late double price;
  late int quantity;
  late String unit;
} 