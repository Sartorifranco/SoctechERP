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
                    
                    // Formateo simple de fecha
                    final DateTime dt = DateTime.parse(mov['date']);
                    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dt);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        // --- CORRECCIÓN AQUÍ: Icons en vez de Colors ---
                        leading: CircleAvatar(
                          backgroundColor: isInput ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isInput ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isInput ? Colors.green : Colors.red,
                          ),
                        ),
                        // -----------------------------------------------
                        title: Text(
                          mov['reference'] ?? "Sin referencia",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(formattedDate),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}