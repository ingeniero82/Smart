import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/import_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  ProductCategory? _selectedCategory;
  bool _isLoading = true;

  final NumberFormat copFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await DatabaseService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Error al cargar productos: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()) ||
            product.code.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == null || 
            product.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(),
    ).then((_) => _loadProducts());
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    ).then((_) => _loadProducts());
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.deleteProduct(product.id);
        Get.snackbar(
          'Éxito',
          'Producto eliminado correctamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadProducts();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Error al eliminar producto: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _importProductsFromExcel() async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importando productos...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final products = await ImportService.importProductsFromFile();
      Get.back(); // Cerrar diálogo de carga

      if (products.isEmpty) {
        Get.snackbar(
          'Advertencia',
          'No se encontraron productos válidos en el archivo',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Detectar productos repetidos
      final existingProducts = await DatabaseService.getAllProducts();
      final existingCodes = existingProducts.map((p) => p.code).toSet();
      final repeated = products.where((p) => existingCodes.contains(p.code)).toList();
      final newProducts = products.where((p) => !existingCodes.contains(p.code)).toList();

      // Mostrar resumen y opciones
      final action = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Resumen de importación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Productos nuevos: ${newProducts.length}'),
              Text('Productos repetidos: ${repeated.length}'),
              if (repeated.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('¿Qué deseas hacer con los productos repetidos?'),
              ],
            ],
          ),
          actions: [
            if (repeated.isNotEmpty)
              TextButton(
                onPressed: () => Get.back(result: 'omit'),
                child: const Text('Omitir repetidos'),
              ),
            if (repeated.isNotEmpty)
              TextButton(
                onPressed: () => Get.back(result: 'overwrite'),
                child: const Text('Sobrescribir repetidos'),
              ),
            TextButton(
              onPressed: () => Get.back(result: 'cancel'),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (action == 'cancel' || action == null) return;

      List<Product> toImport = [];
      if (action == 'omit') {
        toImport = newProducts;
      } else if (action == 'overwrite') {
        // Sobrescribir: mantener los nuevos y los repetidos (se actualizarán)
        toImport = products;
      }

      if (toImport.isEmpty) {
        Get.snackbar(
          'Sin cambios',
          'No hay productos nuevos para importar.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      await ImportService.saveImportedProducts(toImport);
      Get.snackbar(
        'Éxito',
        '${toImport.length} productos importados correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _loadProducts();
    } catch (e) {
      Get.back(); // Cerrar diálogo de carga si hay error
      Get.snackbar(
        'Error',
        'Error al importar productos: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _exportProductsToCsv() async {
    try {
      final products = await DatabaseService.getAllProducts();
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar productos como...',
        fileName: 'productos_exportados.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputPath == null) return; // Usuario canceló
      await ImportService.exportProductsToCsv(products, outputPath);
      Get.snackbar(
        'Éxito',
        'Archivo exportado en: $outputPath',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo exportar: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showExcelTemplate() {
    Get.dialog(
      AlertDialog(
        title: const Text('Plantilla Excel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para importar productos, usa esta estructura en tu archivo Excel:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                ImportService.getExcelTemplate(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• CÓDIGO y NOMBRE son obligatorios'),
            const Text('• PRECIO y STOCK se establecen en 0 si no se especifican'),
            const Text('• CATEGORÍA debe ser una de las categorías disponibles'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.blue[700], size: 32),
                const SizedBox(width: 16),
                const Text(
                  'Gestión de Inventario',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22315B),
                  ),
                ),
                const Spacer(),
                // Botón Plantilla Excel
                OutlinedButton.icon(
                  onPressed: _showExcelTemplate,
                  icon: Icon(Icons.description, color: Colors.blue[700]),
                  label: Text('Plantilla Excel', style: TextStyle(color: Colors.blue[700])),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Importar Excel
                ElevatedButton.icon(
                  onPressed: _importProductsFromExcel,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text('Importar Excel/CSV', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _exportProductsToCsv,
                  icon: Icon(Icons.download, color: Colors.blue[700]),
                  label: Text('Exportar productos', style: TextStyle(color: Colors.blue[700])),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Nuevo Producto
                ElevatedButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtros y búsqueda
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                // Búsqueda
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterProducts(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFFF6F8FA),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Filtro por categoría
                Expanded(
                  child: DropdownButtonFormField<ProductCategory?>(
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _filterProducts();
                    },
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      filled: true,
                      fillColor: const Color(0xFFF6F8FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<ProductCategory?>(
                        value: null,
                        child: Text('Todas las categorías'),
                      ),
                      ...ProductCategory.values.map((category) => 
                        DropdownMenuItem<ProductCategory?>(
                          value: category,
                          child: Text(_getCategoryName(category)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Botón refrescar
                IconButton(
                  onPressed: _loadProducts,
                  icon: Icon(Icons.refresh, color: Colors.blue[700]),
                  tooltip: 'Refrescar',
                ),
              ],
            ),
          ),

          // Tabla de productos
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron productos',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xFFF6F8FA),
                            ),
                            columns: const [
                              DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Código corto', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Costo', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _filteredProducts.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(product.code)),
                                  DataCell(Text(product.shortCode)),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          product.unit,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(_getCategoryName(product.category))),
                                  DataCell(Text(copFormat.format(product.price))),
                                  DataCell(Text(copFormat.format(product.cost))),
                                  DataCell(
                                    Row(
                                      children: [
                                        Text(product.stock.toString()),
                                        if (product.isLowStock) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: product.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        product.isActive ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                          color: product.isActive ? Colors.green[700] : Colors.red[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showEditProductDialog(product),
                                          icon: Icon(Icons.edit, color: Colors.blue[600], size: 20),
                                          tooltip: 'Editar',
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteProduct(product),
                                          icon: Icon(Icons.delete, color: Colors.red[600], size: 20),
                                          tooltip: 'Eliminar',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(ProductCategory category) {
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
      case ProductCategory.otros:
        return 'Otros';
    }
  }
}

// Diálogo para agregar/editar productos
class _ProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _unitController = TextEditingController();
  
  ProductCategory _selectedCategory = ProductCategory.otros;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _codeController.text = widget.product!.code;
      _shortCodeController.text = widget.product!.shortCode;
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _costController.text = widget.product!.cost.toString();
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock.toString();
      _unitController.text = widget.product!.unit;
      _selectedCategory = widget.product!.category;
      _isActive = widget.product!.isActive;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();
      final shortCode = _shortCodeController.text.trim();
      final excludeId = widget.product?.id;

      // Validar código de barras único
      final exists = await DatabaseService.existsProductCode(code, excludeId: excludeId);
      if (exists) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Error',
          'Ya existe un producto con ese código de barras.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return;
      }

      // Validar código corto único
      final existsShort = await DatabaseService.getAllProducts();
      if (existsShort.any((p) => p.shortCode == shortCode && p.id != excludeId)) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Error',
          'Ya existe un producto con ese código corto.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return;
      }

      final product = Product()
        ..code = code
        ..shortCode = shortCode
        ..name = _nameController.text.trim()
        ..description = _descriptionController.text.trim()
        ..price = double.parse(_priceController.text)
        ..cost = double.parse(_costController.text)
        ..stock = int.parse(_stockController.text)
        ..minStock = int.parse(_minStockController.text)
        ..unit = _unitController.text.trim()
        ..category = _selectedCategory
        ..isActive = _isActive
        ..updatedAt = DateTime.now();

      if (widget.product == null) {
        // Nuevo producto
        product.createdAt = DateTime.now();
        await DatabaseService.createProduct(product);
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Éxito',
          'Producto creado correctamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        // Preguntar si desea ingresar otro producto
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.defaultDialog(
            title: '¿Ingresar otro producto?',
            middleText: '¿Deseas registrar otro producto nuevo?',
            textCancel: 'No',
            textConfirm: 'Sí',
            onCancel: () {
              Get.back(); // Cierra el diálogo de confirmación
              Get.back(); // Cierra el formulario
            },
            onConfirm: () {
              Get.back(); // Cierra el diálogo de confirmación
              _formKey.currentState?.reset();
              _codeController.clear();
              _shortCodeController.clear();
              _nameController.clear();
              _descriptionController.clear();
              _priceController.clear();
              _costController.clear();
              _stockController.clear();
              _minStockController.clear();
              _unitController.clear();
              setState(() {
                _selectedCategory = ProductCategory.otros;
                _isActive = true;
              });
            },
            barrierDismissible: false,
          );
        });
      } else {
        // Editar producto existente
        product.id = widget.product!.id;
        product.createdAt = widget.product!.createdAt;
        await DatabaseService.updateProduct(product);
        setState(() {
          _isLoading = false;
        });
        Get.back();
        Get.snackbar(
          'Éxito',
          'Producto actualizado correctamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Error al guardar producto: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22315B),
                ),
              ),
              const SizedBox(height: 24),
              
              // Primera fila: Código de barras y Código corto
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Código de barras',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El código es requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _shortCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Código corto',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El código corto es requerido';
                        }
                        if (value.trim().length < 2) {
                          return 'Debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Segunda fila: Nombre del producto
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Segunda fila: Precio, Costo, Unidad
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio de venta',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio es requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Precio inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Costo',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El costo es requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Costo inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La unidad es requerida';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tercera fila: Stock y Stock mínimo
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock actual',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El stock es requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Stock inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El stock mínimo es requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Stock mínimo inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Fila aparte para Categoría
              DropdownButtonFormField<ProductCategory>(
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: ProductCategory.values.map((category) => 
                  DropdownMenuItem<ProductCategory>(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 16),
              
              // Estado activo/inactivo
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value!;
                      });
                    },
                  ),
                  const Text('Producto activo'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.product == null ? 'Crear' : 'Actualizar',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(ProductCategory category) {
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
      case ProductCategory.otros:
        return 'Otros';
    }
  }
} 