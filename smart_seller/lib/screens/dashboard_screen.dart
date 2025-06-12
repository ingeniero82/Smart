import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA), // Fondo general gris claro
      body: Row(
        children: [
          // Sidebar lateral
          Container(
            width: 240,
            height: double.infinity,
            color: const Color(0xFF6C47FF), // Morado original del mockup
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Solo el texto, sin logo
                const Text(
                  'smart seller',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                // Menú lateral
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      _SidebarButton(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        selected: true,
                        onTap: () {},
                      ),
                      _SidebarButton(
                        icon: Icons.point_of_sale,
                        label: 'Punto de Venta',
                        onTap: () {},
                      ),
                      _SidebarButton(
                        icon: Icons.inventory_2,
                        label: 'Inventario',
                        onTap: () {},
                      ),
                      _SidebarButton(
                        icon: Icons.people,
                        label: 'Clientes',
                        onTap: () {},
                      ),
                      _SidebarButton(
                        icon: Icons.bar_chart,
                        label: 'Reportes',
                        onTap: () {},
                      ),
                      _SidebarButton(
                        icon: Icons.settings,
                        label: 'Configuración',
                        onTap: () {},
                      ),
                      _SidebarButton(
                        icon: Icons.person,
                        label: 'Usuarios',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                // Sección de usuario
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Cajero Principal',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Administrador',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              color: const Color(0xFFF6F8FA), // Fondo igual al general
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header azul
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3), // Azul principal
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'Panel de Control',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Bienvenido de vuelta, gestiona tu supermercado de manera eficiente',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Tarjetas de resumen adaptables
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'VENTAS HOY',
                          value: '2,450',
                          subtitle: '+15% vs ayer',
                          icon: Icons.monetization_on,
                          color: Color(0xFF4CAF50),
                          borderColor: Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: _SummaryCard(
                          title: 'PRODUCTOS VENDIDOS',
                          value: '156',
                          subtitle: '+8% vs ayer',
                          icon: Icons.inventory_2,
                          color: Color(0xFFFF9800),
                          borderColor: Color(0xFFFF9800),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: _SummaryCard(
                          title: 'CLIENTES ATENDIDOS',
                          value: '42',
                          subtitle: '+22% vs ayer',
                          icon: Icons.people,
                          color: Color(0xFFF44336),
                          borderColor: Color(0xFFF44336),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: _SummaryCard(
                          title: 'INGRESOS SEMANALES',
                          value: '12,850',
                          subtitle: '+5% vs sem. anterior',
                          icon: Icons.sticky_note_2,
                          color: Color(0xFF7C4DFF),
                          borderColor: Color(0xFF7C4DFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Acciones Rápidas
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22315B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        _QuickActionCard(
                          icon: Icons.point_of_sale,
                          color: Color(0xFF2979FF),
                          title: 'Nueva Venta',
                          description: 'Iniciar una nueva transacción de venta y procesar productos',
                        ),
                        _QuickActionCard(
                          icon: Icons.inventory,
                          color: Color(0xFF7C4DFF),
                          title: 'Gestionar Inventario',
                          description: 'Administrar stock, agregar productos y controlar existencias',
                        ),
                        _QuickActionCard(
                          icon: Icons.groups,
                          color: Color(0xFFFFA000),
                          title: 'Gestión de Clientes',
                          description: 'Registrar clientes, consultar historial y programas de fidelización',
                        ),
                        _QuickActionCard(
                          icon: Icons.bar_chart,
                          color: Color(0xFF00BFA5),
                          title: 'Ver Reportes',
                          description: 'Consultar reportes de ventas, estadísticas y análisis del negocio',
                        ),
                        _QuickActionCard(
                          icon: Icons.settings,
                          color: Color(0xFF616161),
                          title: 'Configuración',
                          description: 'Ajustar parámetros del sistema, impuestos y configuraciones generales',
                        ),
                        _QuickActionCard(
                          icon: Icons.person,
                          color: Color(0xFFD32F2F),
                          title: 'Gestión de Usuarios',
                          description: 'Administrar usuarios del sistema, permisos y roles de acceso',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para los botones del sidebar
class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Material(
        color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
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

// Widget para las tarjetas de resumen
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color borderColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.borderColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7B809A),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF22315B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para las tarjetas de acción rápida
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22315B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7B809A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 