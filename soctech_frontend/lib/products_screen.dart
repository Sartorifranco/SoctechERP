import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_product_screen.dart'; // Importamos la pantalla de creación

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

  // Esta función refresca la lista cada vez que volvemos de crear uno nuevo
  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void navigateToAdd() async {
    // Navegamos a la pantalla de crear y esperamos a que vuelva para actualizar la lista
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateProductScreen()),
    );
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catálogo de Materiales")),
      // Botón flotante para CREAR NUEVO PRODUCTO
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAdd,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No hay materiales registrados."))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final double stock = (p['stock'] ?? 0).toDouble();
                    final bool isLowStock = stock < (p['reorderLevel'] ?? 5);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock ? Colors.red.shade100 : Colors.indigo.shade100,
                          child: Icon(Icons.inventory_2, color: isLowStock ? Colors.red : Colors.indigo),
                        ),
                        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("SKU: ${p['sku']}"),
                            Text("Stock: ${stock.toStringAsFixed(0)} un.", 
                              style: TextStyle(color: isLowStock ? Colors.red : Colors.black87, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("\$${p['costPrice']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            const Text("Costo", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}