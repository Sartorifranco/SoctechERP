import 'package:flutter/material.dart';

// --- IMPORTS DE TUS PANTALLAS ---
import 'dashboard_screen.dart';
import 'projects_screen.dart';      
import 'products_screen.dart';      
import 'providers_screen.dart';     
import 'employees_screen.dart';     
import 'work_logs_screen.dart';     
import 'add_stock_screen.dart';     
import 'consume_stock_screen.dart'; 
import 'history_screen.dart';       
import 'mass_attendance_screen.dart'; 
import 'project_costs_screen.dart';   
import 'contractors_screen.dart';     
import 'purchase_orders_screen.dart'; 

// --- IMPORTS DE ADMINISTRACIÓN ---
import 'invoice_entry_screen.dart';   
import 'invoice_list_screen.dart';    

// --- IMPORTS DE VENTAS ---
import 'sales_invoice_screen.dart';      
import 'sales_invoice_list_screen.dart'; 

// --- IMPORTS DE TESORERÍA ---
import 'treasury_screen.dart';           

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
        // Ajustes para que se sienta más "Desktop"
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  Widget _currentScreen = const DashboardScreen();
  String _currentTitle = "Tablero de Control";

  // Esta función ahora solo actualiza el estado, no cierra el drawer manualmente
  // porque en Desktop el drawer no existe (es fijo).
  void _navigateTo(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
    // Solo cerramos el drawer si estamos en modo movil
    if (MediaQuery.of(context).size.width < 800) {
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos el ancho de la pantalla
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 800; // Punto de quiebre para considerar PC

    return Scaffold(
      // En Desktop, NO usamos AppBar arriba con menu hamburguesa
      appBar: isDesktop 
          ? null 
          : AppBar(title: Text(_currentTitle), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      
      // En Movil, usamos Drawer. En Desktop es null.
      drawer: isDesktop ? null : Drawer(child: AppMenu(onNavigate: _navigateTo)),
      
      body: Row(
        children: [
          // 1. SI ES DESKTOP: Mostramos el Sidebar Fijo a la izquierda
          if (isDesktop)
            SizedBox(
              width: 270, // Ancho del menú lateral
              child: Container(
                color: Colors.white, // Fondo del menú
                child: Column(
                  children: [
                    // Header del Sidebar
                    Container(
                      height: 150,
                      color: Colors.indigo.shade900,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(backgroundColor: Colors.white, child: Text("S", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                          SizedBox(height: 10),
                          Text("SOCTECH ERP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("Admin Console", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    // La lista de opciones
                    Expanded(
                      child: AppMenu(onNavigate: _navigateTo),
                    ),
                  ],
                ),
              ),
            ),
          
          if (isDesktop) const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),

          // 2. EL CONTENIDO PRINCIPAL
          Expanded(
            child: Column(
              children: [
                // En Desktop, agregamos una "TopBar" personalizada ya que quitamos el AppBar
                if (isDesktop)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_currentTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Row(
                          children: [
                            Icon(Icons.notifications, color: Colors.grey),
                            SizedBox(width: 15),
                            CircleAvatar(radius: 15, backgroundColor: Colors.indigo, child: Text("A", style: TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                        )
                      ],
                    ),
                  ),
                if (isDesktop) const Divider(height: 1),
                
                // La pantalla real
                Expanded(child: _currentScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DEL MENÚ (Extraído para reusar en Movil y Desktop) ---
class AppMenu extends StatelessWidget {
  final Function(Widget, String) onNavigate;

  const AppMenu({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (MediaQuery.of(context).size.width < 800) // Solo mostrar header en movil (en desktop ya lo pusimos fijo arriba)
          const UserAccountsDrawerHeader(
            accountName: Text("Admin Soctech"),
            accountEmail: Text("admin@soctech.com"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Text("S", style: TextStyle(fontSize: 40.0, color: Colors.indigo))),
            decoration: BoxDecoration(color: Colors.indigo),
          ),

        _sectionTitle("OPERACIONES"),
        _menuItem(Icons.dashboard, 'Tablero de Control', () => onNavigate(const DashboardScreen(), "Tablero de Control")),
        _menuItem(Icons.add_shopping_cart, 'Entrada Mercadería', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddStockScreen())), color: Colors.green),
        _menuItem(Icons.output, 'Salida / Consumo', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ConsumeStockScreen())), color: Colors.redAccent),
        _menuItem(Icons.playlist_add_check_circle, 'Parte Diario Masivo', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MassAttendanceScreen()))),
        _menuItem(Icons.history_edu, 'Auditoría de Stock', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryScreen()))),
        _menuItem(Icons.timer, 'Carga de Horas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const WorkLogsScreen()))),
        _menuItem(Icons.shopping_bag, 'Órdenes de Compra', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PurchaseOrdersScreen())), color: Colors.blue),

        const Divider(),
        _sectionTitle("ADMIN / TESORERÍA"),
        _menuItem(Icons.account_balance_wallet, 'Caja y Bancos', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TreasuryScreen())), color: Colors.teal),
        _menuItem(Icons.receipt_long, 'Cargar Factura Prov.', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InvoiceEntryScreen())), color: Colors.deepPurple),
        _menuItem(Icons.folder_shared, 'Bandeja de Facturas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InvoiceListScreen()))),

        const Divider(),
        _sectionTitle("VENTAS"),
        _menuItem(Icons.print, 'Emitir Factura Venta', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SalesInvoiceScreen())), color: Colors.green[700]),
        _menuItem(Icons.history, 'Historial Ventas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SalesInvoiceListScreen()))),

        const Divider(),
        _sectionTitle("GESTIÓN"),
        _menuItem(Icons.apartment, 'Obras y Proyectos', () => onNavigate(const ProjectsScreen(), "Obras Activas")),
        _menuItem(Icons.inventory, 'Catálogo Materiales', () => onNavigate(const ProductsScreen(), "Catálogo de Materiales")),
        _menuItem(Icons.local_shipping, 'Proveedores', () => onNavigate(const ProvidersScreen(), "Directorio de Proveedores")),
        _menuItem(Icons.engineering, 'Subcontratistas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ContractorsScreen())), color: Colors.orange),
        _menuItem(Icons.people, 'Personal / RRHH', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EmployeesScreen()))),
        
        const Divider(),
        _sectionTitle("REPORTES"),
        _menuItem(Icons.pie_chart, 'Costos por Obra', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProjectCostsScreen())), color: Colors.deepPurple),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 15, bottom: 5),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700], size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
      dense: true, // Hace los items más compactos, mejor para Desktop
      onTap: onTap,
    );
  }
}