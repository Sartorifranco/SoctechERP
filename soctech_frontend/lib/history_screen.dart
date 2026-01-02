import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> allMovements = []; // Lista completa
  List<dynamic> filteredMovements = []; // Lista visible
  
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Definimos 3 pestañas: TODOS - ENTRADAS - SALIDAS
    _tabController = TabController(length: 3, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        filterList(_tabController.index);
      }
    });

    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/StockMovements'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // Ordenamos por fecha (del más nuevo al más viejo)
        data.sort((a, b) => b['date'].compareTo(a['date']));

        if (mounted) {
          setState(() {
            allMovements = data;
            filteredMovements = data; // Al inicio mostramos todo
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Lógica de filtrado
  void filterList(int index) {
    setState(() {
      if (index == 0) {
        // Pestaña 0: TODOS
        filteredMovements = allMovements;
      } else if (index == 1) {
        // Pestaña 1: ENTRADAS (Compras)
        filteredMovements = allMovements.where((m) => m['movementType'] == 'PURCHASE').toList();
      } else {
        // Pestaña 2: SALIDAS (Consumo)
        filteredMovements = allMovements.where((m) => m['movementType'] == 'CONSUMPTION').toList();
      }
    });
  }

  // Formateador de fecha manual (para no obligarte a instalar 'intl')
  String formatDate(String isoDate) {
    try {
      final DateTime dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Auditoría de Movimientos"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "TODOS", icon: Icon(Icons.list)),
            Tab(text: "ENTRADAS", icon: Icon(Icons.arrow_downward, color: Colors.greenAccent)),
            Tab(text: "SALIDAS", icon: Icon(Icons.arrow_upward, color: Colors.redAccent)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredMovements.isEmpty
              ? const Center(child: Text("No hay movimientos en esta categoría"))
              : ListView.builder(
                  itemCount: filteredMovements.length,
                  itemBuilder: (context, index) {
                    final mov = filteredMovements[index];
                    
                    // Detectamos tipo
                    final bool isPurchase = mov['movementType'] == 'PURCHASE';
                    final double qty = (mov['quantity'] ?? 0).toDouble().abs(); // Siempre positivo para mostrar
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        // Icono Izquierdo
                        leading: CircleAvatar(
                          backgroundColor: isPurchase ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isPurchase ? Icons.add_shopping_cart : Icons.construction,
                            color: isPurchase ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        // Título
                        title: Text(
                          mov['reference'] ?? "Material",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Fecha
                        subtitle: Text(formatDate(mov['date'])),
                        
                        // Derecha: Cantidad y Tipo
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isPurchase ? '+' : '-'}${qty.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isPurchase ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              isPurchase ? "Compra" : "Obra",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}