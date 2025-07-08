import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/inventory_movements_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/products_screen.dart';
import 'screens/users_screen.dart';
import 'screens/debug_screen.dart';
import 'services/sqlite_database_service.dart';
import 'middleware/auth_middleware.dart';
import 'services/auth_service.dart';
import 'services/permissions_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar la base de datos SQLite
  await SQLiteDatabaseService.initialize();
  // Registrar AuthService en GetX
  Get.put(AuthService());
  Get.put(PermissionsService());
  
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es'),
      ],
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
        GetPage(
          name: '/productos', 
          page: () => const ProductsScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
        GetPage(
          name: '/usuarios', 
          page: () => const UsersScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
        GetPage(
          name: '/debug', 
          page: () => const DebugScreen(),
          middlewares: [AuthMiddleware()], // Solo usuarios autenticados
        ),
      ],
    );
  }
}
