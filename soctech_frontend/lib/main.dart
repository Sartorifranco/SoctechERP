import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_project_screen.dart'; 
import 'consume_stock_screen.dart';
import 'purchase_stock_screen.dart';
import 'dashboard_screen.dart';
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
  int _selectedIndex = 0; // 0=Dashboard, 1=Inventario, 2=Obras

  // Lista de pantallas
  final List<Widget> _screens = [
    const DashboardScreen(), // Nueva pantalla de inicio
    const ProductsScreen(),
    const ProjectsScreen(),
  ];

  final List<String> _titles = ["Tablero de Control", "Inventario", "Obras Activas"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
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
            
            // --- OPCIÓN INICIO ---
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Inicio'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),

            // --- OPCIÓN INVENTARIO ---
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Inventario'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),

            // --- OPCIÓN OBRAS ---
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Obras'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}

// --- PANTALLA 1: INVENTARIO (CON STOCK VISIBLE) ---
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      
      // USAMOS UNA COLUMNA PARA TENER DOS BOTONES FLOTANTES
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // BOTÓN VERDE (COMPRAR)
          FloatingActionButton(
            heroTag: "btnBuy", // Necesario cuando hay 2 botones
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_shopping_cart, color: Colors.white),
            tooltip: "Comprar Stock",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseStockScreen()),
              );
              if (result == true) {
                fetchProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Compra registrada!")),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16), // Espacio entre botones
          
          // BOTÓN ROJO (CONSUMIR)
          FloatingActionButton(
            heroTag: "btnConsume",
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.remove_shopping_cart, color: Colors.white),
            tooltip: "Enviar a Obra",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConsumeStockScreen()),
              );
              if (result == true) {
                fetchProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Salida registrada!")),
                  );
                }
              }
            },
          ),
        ],
      ),

      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              // Lógica para saber si hay stock (para colores)
              final double stock = (product['stock'] ?? 0).toDouble();
              final bool hasStock = stock > 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  // ICONO: Azul si hay stock, Rojo si no
                  leading: CircleAvatar(
                    backgroundColor: hasStock ? Colors.blue.shade100 : Colors.red.shade100,
                    child: Icon(
                      Icons.inventory_2, 
                      color: hasStock ? Colors.blue : Colors.red
                    ),
                  ),
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  // SUBTITULO: Muestra SKU y la cantidad de STOCK
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SKU: ${product['sku']}'),
                      Text(
                        'Stock: ${stock.toStringAsFixed(0)} un.',
                        style: TextStyle(
                          color: hasStock ? Colors.black87 : Colors.red,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  trailing: Text('\$${product['costPrice']}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                ),
              );
            },
          ),
    );
  }
}

// --- PANTALLA 2: OBRAS (CON BOTÓN FLOTANTE) ---
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Projects'));
      if (response.statusCode == 200) {
        setState(() {
          projects = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Función para consultar costos al Backend
  Future<void> showProjectCost(BuildContext context, String projectId, String projectName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Projects/$projectId/costs'));
      
      // Si el widget ya no existe, no hacemos nada
      if (!mounted) return;
      Navigator.pop(context); // Cierra carga

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final total = data['totalSpent'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Costos: $projectName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 60, color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  '\$$total', 
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const Text("Total gastado en materiales"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Cerrar")
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un Scaffold anidado para poder tener el Botón Flotante solo en esta pestaña
    return Scaffold(
      backgroundColor: Colors.transparent, // Para que se integre bien
      
      // EL BOTÓN MÁGICO (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // Navegar a la pantalla de crear y esperar respuesta
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
          );

          // Si volvimos y el resultado es "true", recargamos la lista
          if (result == true) {
            fetchProjects();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("¡Lista actualizada!")),
              );
            }
          }
        },
      ),

      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(child: Text("No hay obras registradas. ¡Crea una!"))
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.business, color: Colors.indigo, size: 40),
                            title: Text(project['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text("Estado: ${project['status']}"),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.attach_money),
                                  label: const Text("Ver Costos"),
                                  onPressed: () => showProjectCost(context, project['id'], project['name']),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}