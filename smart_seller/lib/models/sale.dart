import 'package:isar/isar.dart';

part 'sale.g.dart';

@collection
class Sale {
  @Index(type: IndexType.value)
  int id = 0;
  
  @Index()
  late DateTime date;
  
  @Index()
  late double total;
  
  late String user;
  
  @Index()
  late List<SaleItem> items;
}

@embedded
class SaleItem {
  late String name;
  late double price;
  late int quantity;
  late String unit;
} 