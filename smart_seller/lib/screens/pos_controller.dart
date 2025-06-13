import 'package:get/get.dart';
import 'package:flutter/material.dart';

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
    
    Get.snackbar(
      'Producto agregado',
      '$name agregado al carrito',
      duration: const Duration(seconds: 1),
      snackPosition: SnackPosition.BOTTOM,
    );
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
  void processPayment() {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Carrito vacío',
        'Agrega productos antes de procesar el pago',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Aquí iría la lógica de procesamiento de pago
    Get.dialog(
      AlertDialog(
        title: const Text('Procesar Pago'),
        content: Text('Total a pagar: \$${total.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              clearCart();
              Get.back();
              Get.snackbar(
                'Pago procesado',
                'Venta completada exitosamente',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
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