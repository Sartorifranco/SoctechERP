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
  // IP SEGURA
  final String baseUrl = 'http://127.0.0.1:5064/api';
  
  bool isLoading = true;
  List<dynamic> allMovements = [];
  List<dynamic> filteredMovements = [];
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
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/StockMovements')),
        http.get(Uri.parse('$baseUrl/Products')),
      ]);

      if (responses[0].statusCode == 200) {
        // CASTEO SEGURO
        final List<dynamic> movs = json.decode(responses[0].body) as List<dynamic>;
        
        setState(() {
          allMovements = movs;
          filteredMovements = movs;
          
          if (responses[1].statusCode == 200) {
            products = json.decode(responses[1].body) as List<dynamic>;
          }
          isLoading = false;
        });
      } else {
        throw Exception("Error ${responses[0].statusCode}");
      }
    } catch (e) {
      print("Error historial: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void filterResults(String query) {
    if (query.isEmpty) {
      setState(() => filteredMovements = allMovements);
      return;
    }
    setState(() {
      filteredMovements = allMovements.where((mov) {
        final desc = (mov['description'] ?? '').toString().toLowerCase();
        final ref = (mov['reference'] ?? '').toString().toLowerCase();
        final type = (mov['movementType'] ?? '').toString().toLowerCase();
        return desc.contains(query.toLowerCase()) || 
               ref.contains(query.toLowerCase()) || 
               type.contains(query.toLowerCase());
      }).toList();
    });
  }

  String getProductName(String? prodId) {
    if (prodId == null) return '-';
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
          // BUSCADOR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchCtrl,
              onChanged: filterResults,
              decoration: InputDecoration(
                hintText: "Buscar por referencia, tipo...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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

          // LISTA
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
                        
                        // Determinar si es Entrada (Purchase/Entry) o Salida
                        final String type = (mov['movementType'] ?? '').toString().toUpperCase();
                        final bool isEntry = type == 'PURCHASE' || type == 'ENTRY';
                        
                        final double qty = (mov['quantity'] ?? 0).toDouble();
                        final DateTime date = DateTime.tryParse(mov['date'] ?? '') ?? DateTime.now();
                        final String prodName = getProductName(mov['productId']);
                        final String reference = mov['reference'] ?? 'Sin referencia';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isEntry ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                isEntry ? Icons.download : Icons.upload, // Icono intuitivo
                                color: isEntry ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(prodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Ref: $reference", style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text(DateFormat('dd/MM/yyyy HH:mm').format(date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isEntry ? '+' : '-'}${qty.abs()}",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: isEntry ? Colors.green : Colors.red
                                  ),
                                ),
                                // Si es entrada, mostramos el costo
                                if (isEntry && mov['unitCost'] != null)
                                  Text("\$${mov['unitCost']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
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