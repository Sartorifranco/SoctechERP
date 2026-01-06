import 'package:flutter/material.dart';

// --- IMPORTS DE TUS PANTALLAS ---
import 'dashboard_screen.dart';
import 'projects_screen.dart';      // Obras y Certificaciones
import 'products_screen.dart';      // Catálogo de Materiales
import 'providers_screen.dart';     // Directorio de Proveedores
import 'employees_screen.dart';     // RRHH y Legajos
import 'work_logs_screen.dart';     // Carga de Horas Individual
import 'add_stock_screen.dart';     // Entrada de Mercadería
import 'consume_stock_screen.dart'; // Salida de Mercadería
import 'history_screen.dart';       // Auditoría de Stock
import 'mass_attendance_screen.dart'; // Parte Diario Masivo
import 'project_costs_screen.dart';   // Control de Costos (BI)
import 'contractors_screen.dart';     // <--- GESTIÓN DE SUBCONTRATISTAS
import 'purchase_orders_screen.dart';

void main() {
  runApp(const SoctechERP());
}

class SoctechERP extends StatelessWidget {
  const SoctechERP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soctech ERP',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}

// --- ESTRUCTURA PRINCIPAL (MENÚ + PANTALLAS) ---
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Por defecto iniciamos en el Dashboard
  Widget _currentScreen = const DashboardScreen();
  String _currentTitle = "Tablero de Control";

  // Función para cambiar de pantalla y cerrar el menú
  void _navigateTo(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
    Navigator.pop(context); // Cerrar el Drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Admin Soctech"),
              accountEmail: Text("admin@soctech.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text("S", style: TextStyle(fontSize: 40.0, color: Colors.indigo)),
              ),
              decoration: BoxDecoration(color: Colors.indigo),
            ),
            
            // --- SECCIÓN 1: OPERACIONES (Día a Día) ---
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
              child: Text("OPERACIONES", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tablero de Control'),
              onTap: () => _navigateTo(const DashboardScreen(), "Tablero de Control"),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: const Text('Entrada Mercadería'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStockScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.output, color: Colors.redAccent),
              title: const Text('Salida / Consumo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsumeStockScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_check_circle, color: Colors.indigo), 
              title: const Text('Parte Diario Masivo'), 
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MassAttendanceScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu, color: Colors.blueGrey),
              title: const Text('Auditoría de Stock'), 
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Carga de Horas (Individual)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkLogsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.blue),
              title: const Text('Órdenes de Compra'),
              subtitle: const Text("Solicitar y recibir stock"), // Opcional
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseOrdersScreen()));
              },
            ),

            const Divider(),

            // --- SECCIÓN 2: GESTIÓN Y MAESTROS (Listados) ---
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
              child: Text("GESTIÓN / MAESTROS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),

            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Obras y Proyectos'),
              onTap: () => _navigateTo(const ProjectsScreen(), "Obras Activas"),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Catálogo de Materiales'),
              onTap: () => _navigateTo(const ProductsScreen(), "Catálogo de Materiales"),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Directorio Proveedores'),
              onTap: () => _navigateTo(const ProvidersScreen(), "Directorio de Proveedores"),
            ),
            // --- NUEVO MÓDULO: SUBCONTRATISTAS ---
            ListTile(
              leading: const Icon(Icons.engineering, color: Colors.orange),
              title: const Text('Subcontratistas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContractorsScreen()));
              },
            ),
            // -------------------------------------
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Personal / RRHH'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeesScreen()));
              },
            ),

            const Divider(),

            // --- SECCIÓN 3: REPORTES & BI ---
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
              child: Text("REPORTES & BI", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            
            ListTile(
              leading: const Icon(Icons.pie_chart, color: Colors.deepPurple),
              title: const Text('Costos por Obra'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectCostsScreen()));
              },
            ),
          ],
        ),
      ),
      body: _currentScreen,
    );
  }
}