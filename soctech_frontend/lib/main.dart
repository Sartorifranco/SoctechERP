import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- IMPORTS DE TUS PANTALLAS ---
import 'create_project_screen.dart'; 
import 'consume_stock_screen.dart';
import 'purchase_stock_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'projects_screen.dart'; // <--- ¡AQUÍ ESTÁ LA SOLUCIÓN!
// import 'products_screen.dart'; // <--- Descomenta esto si ya tienes el archivo products_screen.dart

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
    const DashboardScreen(),
    const ProductsScreen(), // Esta clase está definida más abajo (o impórtala si la tienes aparte)
    const ProjectsScreen(), // <--- Ahora usará la del archivo projects_screen.dart
    const HistoryScreen(),
  ];

  final List<String> _titles = ["Tablero de Control", "Inventario", "Obras Activas", "Historial"];

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
            
            // MENU MOVIMIENTOS
             ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Movimientos'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),

            // MENU INVENTARIO
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Inventario'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),

            // MENU OBRAS
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

// ---------------------------------------------------------
// NOTA: Dejé ProductsScreen aquí porque no sé si tienes
// el archivo products_screen.dart funcionando. 
// SI LO TIENES: Borra todo desde aquí hacia abajo e impórtalo arriba.
// SI NO LO TIENES: Déjalo aquí.
// ---------------------------------------------------------

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
      
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnBuy", 
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_shopping_cart, color: Colors.white),
            tooltip: "Comprar Stock",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseStockScreen()),
              );
              if (result == true) fetchProducts();
            },
          ),
          const SizedBox(height: 16), 
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
              if (result == true) fetchProducts();
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
              final double stock = (product['stock'] ?? 0).toDouble();
              final bool hasStock = stock > 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasStock ? Colors.blue.shade100 : Colors.red.shade100,
                    child: Icon(
                      Icons.inventory_2, 
                      color: hasStock ? Colors.blue : Colors.red
                    ),
                  ),
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
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

// --- ¡¡¡AQUÍ TERMINA EL ARCHIVO!!! ---
// He borrado la clase ProjectsScreen vieja que estaba aquí abajo.