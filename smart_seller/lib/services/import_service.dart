import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import 'database_service.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

class ImportService {
  static Future<List<Product>> importProductsFromFile() async {
    try {
      // Seleccionar archivo Excel o CSV
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
      );

      if (result == null) {
        throw Exception('No se seleccionó ningún archivo');
      }

      File file = File(result.files.single.path!);
      String extension = file.path.split('.').last.toLowerCase();
      List<Product> products = [];

      if (extension == 'csv') {
        final csvString = await file.readAsString();
        // Detección automática de separador
        String separator = ',';
        if (csvString.contains(';') && csvString.split(';').length > csvString.split(',').length) {
          separator = ';';
        }
        final csvRows = const CsvToListConverter(fieldDelimiter: ',', eol: '\n', shouldParseNumbers: false)
          .convert(csvString.replaceAll(separator, ','));
        if (csvRows.isEmpty) return [];
        // Buscar encabezados
        final headers = csvRows[0].map((e) => e.toString().toLowerCase().trim()).toList();
        for (int i = 1; i < csvRows.length; i++) {
          final row = csvRows[i];
          if (row.length < 2) continue;
          final product = _createProductFromCsvRow(row, headers);
          if (product != null) products.add(product);
        }
      } else {
        // Excel
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          int headerRow = -1;
          for (int row = 0; row < sheet.maxRows; row++) {
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
            if (cell.value != null && cell.value.toString().toLowerCase().contains('código')) {
              headerRow = row;
              break;
            }
          }
          if (headerRow == -1) continue;
          Map<String, int> columnMap = {};
          for (int col = 0; col < sheet.maxCols; col++) {
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
            if (cell.value != null) {
              String header = cell.value.toString().toLowerCase().trim();
              columnMap[header] = col;
            }
          }
          for (int row = headerRow + 1; row < sheet.maxRows; row++) {
            try {
              Product? product = _createProductFromRow(sheet, row, columnMap);
              if (product != null) {
                products.add(product);
              }
            } catch (e) {
              print('Error procesando fila $row: $e');
            }
          }
        }
      }
      return products;
    } catch (e) {
      throw Exception('Error al importar archivo: $e');
    }
  }

  static Product? _createProductFromCsvRow(List row, List<String> headers) {
    String? get(String name) {
      int idx = headers.indexWhere((h) => h == name.toLowerCase());
      if (idx == -1 || idx >= row.length) return null;
      return row[idx]?.toString().trim();
    }
    String? code = get('código') ?? get('code') ?? get('codigo');
    String? name = get('nombre') ?? get('name') ?? get('producto');
    String? priceStr = get('precio') ?? get('price');
    String? stockStr = get('stock') ?? get('cantidad') ?? get('inventario');
    if (code == null || code.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    Product product = Product()
      ..code = code
      ..shortCode = code.length > 8 ? code.substring(0, 8) : code
      ..name = name
      ..description = get('descripción') ?? get('descripcion') ?? get('description') ?? ''
      ..price = _parseDouble(priceStr) ?? 0.0
      ..cost = _parseDouble(get('costo') ?? get('cost')) ?? 0.0
      ..stock = _parseInt(stockStr) ?? 0
      ..minStock = _parseInt(get('stock mínimo') ?? get('stock_minimo') ?? get('min_stock')) ?? 5
      ..category = _parseCategory(get('categoría') ?? get('categoria') ?? get('category'))
      ..unit = get('unidad') ?? get('unit') ?? 'unidad'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isActive = true;
    return product;
  }

  static Product? _createProductFromRow(Sheet sheet, int row, Map<String, int> columnMap) {
    // Obtener valores de las celdas
    String? getCellValue(String columnName) {
      int? colIndex = columnMap[columnName];
      if (colIndex == null) return null;
      
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: row));
      return cell.value?.toString().trim();
    }
    
    // Obtener valores requeridos
    String? code = getCellValue('código') ?? getCellValue('code') ?? getCellValue('codigo');
    String? name = getCellValue('nombre') ?? getCellValue('name') ?? getCellValue('producto');
    String? priceStr = getCellValue('precio') ?? getCellValue('price');
    String? stockStr = getCellValue('stock') ?? getCellValue('cantidad') ?? getCellValue('inventario');
    
    // Validar campos requeridos
    if (code == null || code.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    
    // Crear producto
    Product product = Product()
      ..code = code
      ..shortCode = code.length > 8 ? code.substring(0, 8) : code
      ..name = name
      ..description = getCellValue('descripción') ?? getCellValue('descripcion') ?? getCellValue('description') ?? ''
      ..price = _parseDouble(priceStr) ?? 0.0
      ..cost = _parseDouble(getCellValue('costo') ?? getCellValue('cost')) ?? 0.0
      ..stock = _parseInt(stockStr) ?? 0
      ..minStock = _parseInt(getCellValue('stock mínimo') ?? getCellValue('stock_minimo') ?? getCellValue('min_stock')) ?? 5
      ..category = _parseCategory(getCellValue('categoría') ?? getCellValue('categoria') ?? getCellValue('category'))
      ..unit = getCellValue('unidad') ?? getCellValue('unit') ?? 'unidad'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isActive = true;
    
    return product;
  }
  
  static double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return double.parse(value.replaceAll(',', '.'));
    } catch (e) {
      return null;
    }
  }
  
  static int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }
  
  static ProductCategory _parseCategory(String? category) {
    if (category == null) return ProductCategory.otros;
    
    String cat = category.toLowerCase().trim();
    
    switch (cat) {
      case 'frutas':
      case 'verduras':
      case 'frutas y verduras':
        return ProductCategory.frutasVerduras;
      case 'lácteos':
      case 'lacteos':
      case 'leche':
        return ProductCategory.lacteos;
      case 'panadería':
      case 'panaderia':
      case 'pan':
        return ProductCategory.panaderia;
      case 'carnes':
      case 'carne':
        return ProductCategory.carnes;
      case 'bebidas':
      case 'bebida':
        return ProductCategory.bebidas;
      case 'abarrotes':
      case 'abarrote':
        return ProductCategory.abarrotes;
      case 'limpieza':
      case 'productos de limpieza':
        return ProductCategory.limpieza;
      case 'cuidado personal':
      case 'higiene':
        return ProductCategory.cuidadoPersonal;
      default:
        return ProductCategory.otros;
    }
  }
  
  static Future<void> saveImportedProducts(List<Product> products) async {
    try {
      await DatabaseService.isar.writeTxn(() async {
        for (Product product in products) {
          // Buscar si ya existe un producto con el mismo código usando getByCode
          final existing = await DatabaseService.isar.products.getByCode(product.code);
          if (existing != null) {
            product.id = existing.id; // Actualizar el existente
          }
          await DatabaseService.isar.products.put(product);
        }
      });
    } catch (e) {
      throw Exception('Error al guardar productos: $e');
    }
  }
  
  static String getExcelTemplate() {
    return '''
CÓDIGO	NOMBRE	DESCRIPCIÓN	PRECIO	COSTO	STOCK	STOCK MÍNIMO	CATEGORÍA	UNIDAD
PROD001	Manzana Roja	Manzana roja fresca	1.50	1.00	100	10	Frutas y Verduras	kg
PROD002	Leche Entera	Leche entera 1L	2.50	2.00	50	5	Lácteos	litro
PROD003	Pan Integral	Pan integral fresco	0.80	0.60	200	20	Panadería	unidad
PROD004	Coca Cola	Coca Cola 500ml	1.20	0.90	150	15	Bebidas	unidad
PROD005	Arroz	Arroz blanco 1kg	3.00	2.50	80	8	Abarrotes	kg
PROD006	Detergente	Detergente líquido	4.50	3.50	30	3	Limpieza	unidad
PROD007	Jabón	Jabón de baño	1.80	1.40	60	6	Cuidado Personal	unidad
PROD008	Pollo	Pollo entero	8.00	6.50	25	3	Carnes	kg
PROD009	Queso	Queso fresco	5.00	4.00	40	4	Lácteos	kg
PROD010	Tomate	Tomate fresco	2.00	1.60	70	7	Frutas y Verduras	kg
''';
  }

  static Future<void> exportProductsToCsv(List<Product> products, String filePath) async {
    List<List<dynamic>> rows = [];
    rows.add([
      'CÓDIGO', 'NOMBRE', 'DESCRIPCIÓN', 'PRECIO', 'COSTO', 'STOCK', 'STOCK MÍNIMO', 'CATEGORÍA', 'UNIDAD'
    ]);
    for (final p in products) {
      rows.add([
        p.code,
        p.name,
        p.description,
        p.price,
        p.cost,
        p.stock,
        p.minStock,
        _categoryToString(p.category),
        p.unit
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    final file = File(filePath);
    await file.writeAsString(csv, encoding: utf8);
  }

  static String _categoryToString(ProductCategory category) {
    switch (category) {
      case ProductCategory.frutasVerduras:
        return 'Frutas y Verduras';
      case ProductCategory.lacteos:
        return 'Lácteos';
      case ProductCategory.panaderia:
        return 'Panadería';
      case ProductCategory.carnes:
        return 'Carnes';
      case ProductCategory.bebidas:
        return 'Bebidas';
      case ProductCategory.abarrotes:
        return 'Abarrotes';
      case ProductCategory.limpieza:
        return 'Limpieza';
      case ProductCategory.cuidadoPersonal:
        return 'Cuidado Personal';
      default:
        return 'Otros';
    }
  }
} 