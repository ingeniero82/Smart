import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class CartItem {
  final String name;
  final double price;
  final String unit;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.unit,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

class PosController extends GetxController {
  var cartItems = <CartItem>[].obs;
  
  // Agregar producto al carrito
  void addToCart(String name, double price, String unit) {
    // Buscar si el producto ya existe en el carrito
    final existingIndex = cartItems.indexWhere((item) => item.name == name);
    
    if (existingIndex >= 0) {
      // Si existe, aumentar la cantidad
      cartItems[existingIndex].quantity++;
      cartItems.refresh(); // Notificar cambios
    } else {
      // Si no existe, agregarlo
      cartItems.add(CartItem(
        name: name,
        price: price,
        unit: unit,
      ));
    }
  }
  
  // Remover producto del carrito
  void removeFromCart(int index) {
    if (index >= 0 && index < cartItems.length) {
      cartItems.removeAt(index);
    }
  }
  
  // Cambiar cantidad de un producto
  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < cartItems.length && newQuantity > 0) {
      cartItems[index].quantity = newQuantity;
      cartItems.refresh();
    }
  }
  
  // Limpiar carrito
  void clearCart() {
    cartItems.clear();
    Get.snackbar(
      'Carrito limpiado',
      'Todos los productos han sido removidos',
      duration: const Duration(seconds: 1),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  // Calcular subtotal
  double get subtotal {
    return cartItems.fold(0.0, (sum, item) => sum + item.total);
  }
  
  // Calcular impuestos (19%)
  double get taxes {
    return subtotal * 0.19;
  }
  
  // Calcular total
  double get total {
    return subtotal + taxes;
  }
  
  // Procesar pago
  void processPayment() async {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Carrito vacío',
        'Agrega productos antes de procesar el pago',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.dialog(
      Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Procesar Pago',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Total a pagar:',
                style: TextStyle(fontSize: 20, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Get.back(); // Cierra el diálogo primero
                      // Espera un breve momento para asegurar el cierre visual
                      await Future.delayed(const Duration(milliseconds: 200));
                      // Guardar la venta en la base de datos
                      final sale = Sale()
                        ..date = DateTime.now()
                        ..total = total
                        ..user = AuthService.to.currentUser?.username ?? 'usuario'
                        ..items = cartItems.map((item) => SaleItem()
                          ..name = item.name
                          ..price = item.price
                          ..quantity = item.quantity
                          ..unit = item.unit
                        ).toList();
                      await DatabaseService.saveSale(sale);
                      clearCart();
                      Get.snackbar(
                        'Pago procesado',
                        'Venta completada exitosamente',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Suspender venta
  void suspendSale() {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Carrito vacío',
        'No hay productos para suspender',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Aquí iría la lógica para guardar la venta suspendida
    Get.snackbar(
      'Venta suspendida',
      'La venta ha sido guardada temporalmente',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
} 