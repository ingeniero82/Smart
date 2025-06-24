import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/inventory_movements_screen.dart';
import 'screens/sales_history_screen.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'middleware/auth_middleware.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar la base de datos
  await DatabaseService.initialize();
  
  // Inicializar el servicio de autenticación
  Get.put(AuthService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Seller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login', 
          page: () => const LoginScreen(),
          middlewares: [GuestMiddleware()], // Solo usuarios no autenticados
        ),
        GetPage(
          name: '/dashboard', 
          page: () => const DashboardScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
        GetPage(
          name: '/pos', 
          page: () => const PosScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
        GetPage(
          name: '/movimientos', 
          page: () => const InventoryMovementsScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
        GetPage(
          name: '/ventas', 
          page: () => const SalesHistoryScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
      ],
    );
  }
}
