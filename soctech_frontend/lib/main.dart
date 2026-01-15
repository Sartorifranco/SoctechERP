import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- NECESARIO PARA LOGIN

// --- IMPORTS DE TUS PANTALLAS ---
import 'dashboard_screen.dart';
import 'projects_screen.dart';      
import 'products_screen.dart';      
import 'providers_screen.dart';     
import 'employees_screen.dart';     
import 'work_logs_screen.dart';     
import 'add_stock_screen.dart';     
import 'history_screen.dart';       
import 'mass_attendance_screen.dart'; 
import 'project_costs_screen.dart';   
import 'contractors_screen.dart';     
import 'purchase_orders_screen.dart'; 
import 'invoice_entry_screen.dart';   
import 'invoice_list_screen.dart';    
import 'sales_invoice_screen.dart';      
import 'sales_invoice_list_screen.dart'; 
import 'treasury_screen.dart';           
import 'screens/dispatch_screen.dart'; 
import 'screens/login_screen.dart'; // <--- IMPORTANTE: Importamos el Login

void main() async {
  // Aseguramos que Flutter esté listo antes de cargar datos
  WidgetsFlutterBinding.ensureInitialized();

  // Verificamos si existe un Token guardado
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  // Si hay token, vamos directo a la App (MainLayout). Si no, al Login.
  runApp(SoctechERP(startScreen: token != null ? const MainLayout() : const LoginScreen()));
}

class SoctechERP extends StatelessWidget {
  final Widget startScreen;
  
  const SoctechERP({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soctech ERP',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Aquí definimos qué pantalla arranca
      home: startScreen,
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

  // Función para cerrar sesión
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borra el token
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _navigateTo(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
    if (MediaQuery.of(context).size.width < 800) {
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 800;

    return Scaffold(
      appBar: isDesktop 
          ? null 
          : AppBar(title: Text(_currentTitle), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      
      drawer: isDesktop ? null : Drawer(child: AppMenu(onNavigate: _navigateTo, onLogout: _logout)),
      
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 270, 
              child: Container(
                color: Colors.white, 
                child: Column(
                  children: [
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
                    Expanded(
                      child: AppMenu(onNavigate: _navigateTo, onLogout: _logout),
                    ),
                  ],
                ),
              ),
            ),
          
          if (isDesktop) const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),

          Expanded(
            child: Column(
              children: [
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
                        Row(
                          children: [
                            const Icon(Icons.notifications, color: Colors.grey),
                            const SizedBox(width: 15),
                            const CircleAvatar(radius: 15, backgroundColor: Colors.indigo, child: Text("A", style: TextStyle(color: Colors.white, fontSize: 12))),
                            const SizedBox(width: 15),
                            // Botón de salir rápido en Desktop
                            IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.redAccent), tooltip: "Cerrar Sesión"),
                          ],
                        )
                      ],
                    ),
                  ),
                if (isDesktop) const Divider(height: 1),
                
                Expanded(child: _currentScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppMenu extends StatelessWidget {
  final Function(Widget, String) onNavigate;
  final VoidCallback onLogout; // Callback para cerrar sesión

  const AppMenu({super.key, required this.onNavigate, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (MediaQuery.of(context).size.width < 800)
          const UserAccountsDrawerHeader(
            accountName: Text("Admin Soctech"),
            accountEmail: Text("admin@soctech.com"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Text("S", style: TextStyle(fontSize: 40.0, color: Colors.indigo))),
            decoration: BoxDecoration(color: Colors.indigo),
          ),

        _sectionTitle("OPERACIONES"),
        _menuItem(Icons.dashboard, 'Tablero de Control', () => onNavigate(const DashboardScreen(), "Tablero de Control")),
        _menuItem(Icons.add_shopping_cart, 'Entrada Mercadería', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddStockScreen())), color: Colors.green),
        _menuItem(Icons.output, 'Salida / Consumo', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DispatchScreen())), color: Colors.redAccent),
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

        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: onLogout, // Conectado al botón de salir
        ),
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
      dense: true,
      onTap: onTap,
    );
  }
}