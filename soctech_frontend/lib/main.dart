import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS DE PANTALLAS ---
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
import 'screens/login_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/warehouses_screen.dart'; 
import 'screens/transfer_stock_screen.dart'; // <--- 1. IMPORT AGREGADO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  runApp(SoctechERP(startScreen: token != null ? const MainLayout() : const LoginScreen()));
}

class SoctechERP extends StatelessWidget {
  final Widget startScreen;
  const SoctechERP({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soctech ERP Enterprise',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
              width: 280, 
              child: Container(
                color: Colors.white, 
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      color: Colors.indigo.shade900,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: const Row(
                        children: [
                          CircleAvatar(backgroundColor: Colors.white, child: Text("S", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                          SizedBox(width: 15),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SOCTECH ERP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text("Enterprise Edition", style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(child: AppMenu(onNavigate: _navigateTo, onLogout: _logout)),
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
                        IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.redAccent), tooltip: "Salir"),
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

class AppMenu extends StatefulWidget {
  final Function(Widget, String) onNavigate;
  final VoidCallback onLogout;

  const AppMenu({super.key, required this.onNavigate, required this.onLogout});

  @override
  State<AppMenu> createState() => _AppMenuState();
}

class _AppMenuState extends State<AppMenu> {
  List<String> _permissions = [];
  bool _isAdmin = false;
  String _userName = "...";

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _permissions = prefs.getStringList('user_permissions') ?? [];
      _isAdmin = prefs.getString('role') == 'SuperAdmin';
      _userName = prefs.getString('username') ?? "Usuario";
    });
  }

  // --- FUNCIÓN CLAVE: ¿PUEDE VER ESTE MÓDULO? ---
  bool _canView(String moduleCode) {
    if (_isAdmin) return true; // SuperAdmin ve todo
    return _permissions.contains(moduleCode);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (MediaQuery.of(context).size.width < 800)
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            accountEmail: Text(_isAdmin ? "Super Administrador" : "Usuario Estándar"),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.indigo)),
            decoration: const BoxDecoration(color: Colors.indigo),
          ),

        // SIEMPRE VISIBLE
        _menuItem(Icons.dashboard, 'Tablero de Control', () => widget.onNavigate(const DashboardScreen(), "Tablero de Control")),

        // 1. STOCK
        if (_canView("STOCK_IN") || _canView("STOCK_OUT")) ...[
          const Divider(),
          _sectionTitle("INVENTARIO"),
          if (_canView("STOCK_IN")) 
             _menuItem(Icons.add_shopping_cart, 'Entrada Mercadería', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddStockScreen())), color: Colors.green),
          
          // --- BOTÓN DE TRANSFERENCIA (NUEVO) ---
          if (_canView("STOCK_IN")) 
             _menuItem(Icons.swap_horiz, 'Transferencia Interna', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TransferStockScreen())), color: Colors.orange[800]),
          // --------------------------------------

          if (_canView("STOCK_OUT")) 
             _menuItem(Icons.output, 'Salida / Consumo', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DispatchScreen())), color: Colors.redAccent),
          
          _menuItem(Icons.history_edu, 'Auditoría de Stock', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryScreen()))),
        ],

        // 2. COMPRAS
        if (_canView("PURCHASE_ORDERS")) ...[
          const Divider(),
          _sectionTitle("COMPRAS"),
          _menuItem(Icons.shopping_bag, 'Órdenes de Compra', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PurchaseOrdersScreen())), color: Colors.blue),
          _menuItem(Icons.receipt_long, 'Cargar Factura Prov.', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InvoiceEntryScreen())), color: Colors.deepPurple),
          _menuItem(Icons.folder_shared, 'Bandeja de Facturas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InvoiceListScreen()))),
        ],

        // 3. TESORERÍA
        if (_canView("TREASURY")) ...[
          const Divider(),
          _sectionTitle("TESORERÍA"),
          _menuItem(Icons.account_balance_wallet, 'Caja y Bancos', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TreasuryScreen())), color: Colors.teal),
        ],

        // 4. VENTAS
        if (_canView("SALES")) ...[
          const Divider(),
          _sectionTitle("VENTAS"),
          _menuItem(Icons.print, 'Emitir Factura Venta', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SalesInvoiceScreen())), color: Colors.green[700]),
          _menuItem(Icons.history, 'Historial Ventas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SalesInvoiceListScreen()))),
        ],

        // 5. OBRAS Y RRHH
        if (_canView("PROJECTS") || _canView("HR")) ...[
          const Divider(),
          _sectionTitle("GESTIÓN"),
          if (_canView("PROJECTS")) _menuItem(Icons.apartment, 'Obras y Proyectos', () => widget.onNavigate(const ProjectsScreen(), "Obras Activas")),
          if (_canView("PROJECTS")) _menuItem(Icons.store, 'Depósitos y Pañoles', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const WarehousesScreen()))),
          if (_canView("PROJECTS")) _menuItem(Icons.engineering, 'Subcontratistas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ContractorsScreen())), color: Colors.orange),
          if (_canView("PROJECTS")) _menuItem(Icons.inventory, 'Catálogo Materiales', () => widget.onNavigate(const ProductsScreen(), "Catálogo de Materiales")),
          
          if (_canView("HR")) _menuItem(Icons.people, 'Personal / RRHH', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EmployeesScreen()))),
          if (_canView("HR")) _menuItem(Icons.playlist_add_check_circle, 'Parte Diario Masivo', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MassAttendanceScreen()))),
          if (_canView("HR")) _menuItem(Icons.timer, 'Carga de Horas', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const WorkLogsScreen()))),
        ],

        // 6. ADMIN
        if (_isAdmin || _canView("ADMIN_USERS")) ...[
           const Divider(),
           _sectionTitle("ADMINISTRACIÓN"),
           _menuItem(Icons.security, 'Usuarios y Permisos', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminUsersScreen())), color: Colors.red),
           _menuItem(Icons.pie_chart, 'Costos por Obra', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProjectCostsScreen())), color: Colors.deepPurple),
        ],

        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: widget.onLogout,
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