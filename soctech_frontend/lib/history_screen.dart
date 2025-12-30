import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Necesitas agregar intl a pubspec.yaml si quieres formatear fechas bonitas, si no, usamos split

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> movements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/StockMovements'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // Ordenamos por fecha (del más nuevo al más viejo)
        data.sort((a, b) => b['date'].compareTo(a['date']));

        setState(() {
          movements = data;
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
      appBar: AppBar(title: const Text("Historial de Movimientos")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : movements.isEmpty
              ? const Center(child: Text("No hay movimientos registrados"))
              : ListView.builder(
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final mov = movements[index];
                    final bool isInput = mov['quantity'] > 0;
                    
                    // Formateo simple de fecha (YYYY-MM-DD)
                    final String date = mov['date'].toString().split('T')[0];
                    final String time = mov['date'].toString().split('T')[1].split('.')[0];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        // Icono: Flecha Arriba (Verde) o Abajo (Rojo)
                        leading: CircleAvatar(
                          backgroundColor: isInput ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isInput ? Colors.arrow_downward : Colors.arrow_upward,
                            color: isInput ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          mov['reference'] ?? "Sin referencia",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("$date $time"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${mov['quantity']} un.",
                              style: TextStyle(
                                color: isInput ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),
                            ),
                            // Mostrar costo total del movimiento si quieres (Opcional)
                            // Text("\$${(mov['quantity'] * mov['unitCost']).toStringAsFixed(2)}", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}