import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pos_controller.dart';
import '../models/product.dart';
import '../services/sqlite_database_service.dart';
import 'package:intl/intl.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  ProductCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await SQLiteDatabaseService.getAllProducts();
    setState(() {
      _products = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredProducts = _products.where((product) {
        // Filtro por texto
        final matchesText = product.name.toLowerCase().contains(query) ||
                           product.code.toLowerCase().contains(query) ||
                           product.shortCode.toLowerCase().contains(query);
        
        // Filtro por categoría
        final matchesCategory = _selectedCategory == null || product.category == _selectedCategory;
        
        return matchesText && matchesCategory;
      }).toList();
    });
  }
  
  void _selectCategory(ProductCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    final posController = Get.put(PosController());
    final NumberFormat copFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$ ', decimalDigits: 0, customPattern: '\u00A4#,##0');
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Botón de retorno al menú principal
            InkWell(
              onTap: () {
                Get.back();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                    Text(
                      'Volver al Menú Principal',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Columna de categorías y búsqueda
                  Container(
                    width: 260,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        // Búsqueda
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _filterProducts(),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, código o código corto...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              filled: true,
                              fillColor: const Color(0xFFF6F8FA),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botón escanear código
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                              label: const Text('Escanear Código'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C4DFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Categorías
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Categorías',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22315B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              _CategoryButton(
                                icon: Icons.grid_view,
                                label: 'Todos los productos',
                                selected: _selectedCategory == null,
                                color: Color(0xFF7C4DFF),
                                onTap: () => _selectCategory(null),
                              ),
                              _CategoryButton(
                                icon: Icons.apple,
                                label: 'Frutas y Verduras',
                                selected: _selectedCategory == ProductCategory.frutasVerduras,
                                color: Color(0xFFE53935),
                                onTap: () => _selectCategory(ProductCategory.frutasVerduras),
                              ),
                              _CategoryButton(
                                icon: Icons.local_drink,
                                label: 'Lácteos',
                                selected: _selectedCategory == ProductCategory.lacteos,
                                color: Color(0xFF29B6F6),
                                onTap: () => _selectCategory(ProductCategory.lacteos),
                              ),
                              _CategoryButton(
                                icon: Icons.bakery_dining,
                                label: 'Panadería',
                                selected: _selectedCategory == ProductCategory.panaderia,
                                color: Color(0xFFFFB300),
                                onTap: () => _selectCategory(ProductCategory.panaderia),
                              ),
                              _CategoryButton(
                                icon: Icons.set_meal,
                                label: 'Carnes',
                                selected: _selectedCategory == ProductCategory.carnes,
                                color: Color(0xFF8D6E63),
                                onTap: () => _selectCategory(ProductCategory.carnes),
                              ),
                              _CategoryButton(
                                icon: Icons.local_bar,
                                label: 'Bebidas',
                                selected: _selectedCategory == ProductCategory.bebidas,
                                color: Color(0xFF43A047),
                                onTap: () => _selectCategory(ProductCategory.bebidas),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Columna central de productos
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Header azul
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1EC6FF), Color(0xFF3B82F6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: const Column(
                            children: [
                              SizedBox(height: 8),
                              Text(
                                'Sistema POS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Haz clic en los productos para agregarlos al carrito',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Cuadrícula de productos
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _filteredProducts.isEmpty
                                  ? const Center(child: Text('No hay productos para mostrar.'))
                                  : Container(
                                      padding: const EdgeInsets.all(16),
                                      color: Colors.transparent,
                                      child: GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 0.8,
                                        ),
                                        itemCount: _filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product = _filteredProducts[index];
                                          return _ProductCard(
                                            name: product.name,
                                            price: copFormat.format(product.price),
                                            unit: product.unit,
                                            shortCode: product.shortCode,
                                            color: Colors.blue,
                                            icon: Icons.shopping_bag,
                                            stock: product.stock,
                                            onTap: () {
                                              final posController = Get.find<PosController>();
                                              posController.addToCart(
                                                product.name,
                                                product.price,
                                                product.unit,
                                                availableStock: product.stock,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                  // Columna del carrito
                  Container(
                    width: 320,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header del carrito
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Carrito de Compras',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Lista de productos en el carrito (dinámica)
                        Expanded(
                          child: Obx(() => ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: posController.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = posController.cartItems[index];
                              return _CartItem(
                                name: item.name,
                                price: copFormat.format(item.price),
                                quantity: item.quantity,
                                onRemove: () {
                                  posController.removeFromCart(index);
                                },
                                onQuantityChanged: (newQuantity) {
                                  posController.updateQuantity(index, newQuantity);
                                },
                              );
                            },
                          )),
                        ),
                        
                        // Resumen de totales (dinámico)
                        Obx(() => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8FA),
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                          ),
                          child: Column(
                            children: [
                              _TotalRow('Subtotal:', copFormat.format(posController.subtotal)),
                              _TotalRow('Impuestos (19%):', copFormat.format(posController.taxes)),
                              const Divider(thickness: 1),
                              _TotalRow('Total:', copFormat.format(posController.total), isTotal: true),
                            ],
                          ),
                        )),
                        
                        // Botones de acción
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Botón Procesar Pago
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    posController.processPayment();
                                  },
                                  icon: Icon(Icons.payment, color: Colors.white),
                                  label: Text('Procesar Pago'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Botones secundarios
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        posController.suspendSale();
                                      },
                                      icon: Icon(Icons.pause, size: 18),
                                      label: Text('Suspender'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFFF9800),
                                        side: BorderSide(color: const Color(0xFFFF9800)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        posController.clearCart();
                                      },
                                      icon: Icon(Icons.clear, size: 18),
                                      label: Text('Limpiar'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFF44336),
                                        side: BorderSide(color: const Color(0xFFF44336)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para las tarjetas de productos
class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String unit;
  final String shortCode;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final int stock;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.unit,
    required this.shortCode,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.stock,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                shortCode,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
              ),
              Text('por $unit', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stock > 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stock > 0 ? 'Stock: $stock' : 'Sin stock',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para las categorías
class _CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected ? color.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : const Color(0xFF22315B),
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para items del carrito
class _CartItem extends StatelessWidget {
  final String name;
  final String price;
  final int quantity;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const _CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.onRemove,
    required this.onQuantityChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22315B),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red[400], size: 18),
                onPressed: onRemove,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C4DFF),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 18),
                    onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () => onQuantityChanged(quantity + 1),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget para filas de totales
class _TotalRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _TotalRow(this.label, this.amount, {this.isTotal = false, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF22315B) : const Color(0xFF7B809A),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF4CAF50) : const Color(0xFF22315B),
            ),
          ),
        ],
      ),
    );
  }
} 