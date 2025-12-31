import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Importamos las pantallas de acción
import 'consume_stock_screen.dart';
import 'add_stock_screen.dart';

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

  // Función para obtener los productos del Backend
  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cargando inventario: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ya no necesitamos AppBar aquí porque MainLayout lo pone, 
      // pero si usas esta pantalla sola, descomenta la siguiente línea:
      // appBar: AppBar(title: const Text("Inventario")),
      
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No hay productos registrados."))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final double stock = (product['stock'] ?? 0).toDouble();
                    final double cost = (product['costPrice'] ?? 0).toDouble();
                    
                    // Alerta visual de stock bajo
                    final bool isLowStock = stock < 10;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock ? Colors.red.shade100 : Colors.blue.shade100,
                          child: Icon(
                            Icons.inventory_2, 
                            color: isLowStock ? Colors.red : Colors.blue
                          ),
                        ),
                        title: Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Costo unitario: \$${cost.toStringAsFixed(2)}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "$stock un.",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? Colors.red : Colors.green[700],
                              ),
                            ),
                            if (isLowStock)
                              const Text("¡Stock Bajo!", style: TextStyle(fontSize: 10, color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

      // --- BOTONES FLOTANTES DE ACCIÓN ---
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón ROJO: Salida / Consumo
          FloatingActionButton.extended(
            heroTag: "btnSalida",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConsumeStockScreen()),
              );
              // Si volvemos y hubo cambios (result == true), recargamos la lista
              if (result == true) fetchProducts();
            },
            label: const Text("Salida"),
            icon: const Icon(Icons.output),
            backgroundColor: Colors.redAccent,
          ),
          
          const SizedBox(width: 10), // Espacio

          // Botón VERDE: Ingreso / Compra
          FloatingActionButton.extended(
            heroTag: "btnIngreso",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStockScreen()),
              );
              if (result == true) fetchProducts();
            },
            label: const Text("Ingreso"),
            icon: const Icon(Icons.add_shopping_cart),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }
}