import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<dynamic> movements = [];
  bool isLoading = true;
  double totalSpent = 0;

  @override
  void initState() {
    super.initState();
    fetchProjectMovements();
  }

  Future<void> fetchProjectMovements() async {
    try {
      // Pedimos TODOS los movimientos (Idealmente el backend debería filtrar, 
      // pero para avanzar rápido filtramos aquí en el celular)
      final response = await http.get(Uri.parse('http://localhost:5064/api/StockMovements'));

      if (response.statusCode == 200) {
        List<dynamic> allMovements = json.decode(response.body);
        
        // FILTRO: Solo los movimientos que coinciden con el ID de esta obra
        final projectMovements = allMovements.where((m) => 
          m['projectId'] == widget.project['id'] && 
          m['movementType'] == 'CONSUMPTION' // Solo lo que se gastó
        ).toList();

        // Calculamos el total gastado (Cantidad * Costo Unitario)
        double calculatedTotal = 0;
        for (var mov in projectMovements) {
          calculatedTotal += (mov['quantity'] * mov['unitCost']);
        }

        setState(() {
          movements = projectMovements;
          totalSpent = calculatedTotal.abs(); // Aseguramos positivo
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double budget = (widget.project['budget'] ?? 0).toDouble();
    final double progress = budget > 0 ? (totalSpent / budget) : 0;
    final bool isOverBudget = totalSpent > budget && budget > 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.project['name'])),
      body: Column(
        children: [
          // --- TARJETA DE RESUMEN FINANCIERO ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.indigo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dinero Ejecutado", style: TextStyle(color: Colors.white70)),
                Text(
                  "\$${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                // Barra de Progreso del Presupuesto
                if (budget > 0) ...[
                  LinearProgressIndicator(
                    value: progress > 1 ? 1 : progress,
                    backgroundColor: Colors.indigo.shade800,
                    color: isOverBudget ? Colors.redAccent : Colors.greenAccent,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(progress * 100).toStringAsFixed(1)}% del presupuesto",
                        style: TextStyle(color: isOverBudget ? Colors.redAccent : Colors.white70),
                      ),
                      Text(
                        "Presupuesto: \$${budget.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white30),
                      ),
                    ],
                  ),
                ] else 
                  const Text("Sin presupuesto asignado", style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          // --- LISTA DE MATERIALES USADOS ---
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : movements.isEmpty
                ? const Center(child: Text("Aún no se han enviado materiales a esta obra."))
                : ListView.builder(
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      final mov = movements[index];
                      // Fecha formateada simple
                      final date = mov['date'].toString().split('T')[0];

                      return ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.grey),
                        title: Text(mov['reference'] ?? "Material"),
                        subtitle: Text(date),
                        trailing: Text(
                          "${mov['quantity'].toString()} un.",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}