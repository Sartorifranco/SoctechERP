import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Configuración
  final String baseUrl = 'http://localhost:5064/api';
  bool isLoading = true;
  
  // Listas
  List<dynamic> allMovements = [];
  List<dynamic> filteredMovements = []; // Para el buscador
  
  // Productos para cruzar info (obtener nombres si faltan)
  List<dynamic> products = [];

  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => isLoading = true);
    try {
      // Traemos Movimientos y Productos (para tener los nombres a mano)
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/StockMovements')),
        http.get(Uri.parse('$baseUrl/Products')),
      ]);

      if (responses[0].statusCode == 200) {
        setState(() {
          allMovements = json.decode(responses[0].body);
          filteredMovements = allMovements; // Al inicio mostramos todo
          
          if (responses[1].statusCode == 200) {
            products = json.decode(responses[1].body);
          }
          isLoading = false;
        });
      } else {
        throw Exception("Error ${responses[0].statusCode}");
      }
    } catch (e) {
      print("Error cargando historial: $e");
      setState(() => isLoading = false);
    }
  }

  // Lógica del Buscador
  void filterResults(String query) {
    if (query.isEmpty) {
      setState(() => filteredMovements = allMovements);
      return;
    }

    setState(() {
      filteredMovements = allMovements.where((mov) {
        // Buscamos en descripción, nombre de producto (si lo tuviéramos) o tipo
        final desc = (mov['description'] ?? '').toString().toLowerCase();
        final type = (mov['movementType'] ?? '').toString().toLowerCase();
        // Si el backend no manda el nombre del producto, podrías buscarlo en la lista 'products' usando el ID
        // Por ahora buscamos en la descripción que suele tener mucha info
        return desc.contains(query.toLowerCase()) || type.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Helper para nombre de producto
  String getProductName(String prodId) {
    final prod = products.firstWhere((p) => p['id'] == prodId, orElse: () => null);
    return prod != null ? prod['name'] : 'Producto Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Auditoría de Stock"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchCtrl,
              onChanged: filterResults,
              decoration: InputDecoration(
                hintText: "Buscar por obra, producto o movimiento...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchCtrl.clear();
                    filterResults('');
                  },
                )
              ),
            ),
          ),

          // --- LISTA DE MOVIMIENTOS ---
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredMovements.isEmpty
                ? const Center(child: Text("No se encontraron movimientos."))
                : RefreshIndicator(
                    onRefresh: fetchHistory,
                    child: ListView.builder(
                      itemCount: filteredMovements.length,
                      itemBuilder: (context, index) {
                        final mov = filteredMovements[index];
                        
                        // Datos
                        final double qty = (mov['quantity'] ?? 0).toDouble();
                        final bool isEntry = qty > 0;
                        final DateTime date = DateTime.tryParse(mov['date']) ?? DateTime.now();
                        
                        // Si el backend no manda 'productName' directo en el movimiento, lo buscamos
                        // (Depende de cómo definimos StockMovementsController)
                        // Como tu Controller actual devuelve la entidad StockMovement pura, usamos el helper:
                        final String prodName = getProductName(mov['productId']);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isEntry ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                isEntry ? Icons.arrow_downward : Icons.arrow_upward, // Abajo es entrada (cae al deposito), Arriba es salida (se va)
                                color: isEntry ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(prodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mov['description'] ?? 'Sin descripción'),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(date),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: Text(
                              "${isEntry ? '+' : ''}$qty",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: isEntry ? Colors.green : Colors.red
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}