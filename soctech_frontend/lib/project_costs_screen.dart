import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProjectCostsScreen extends StatefulWidget {
  const ProjectCostsScreen({super.key});

  @override
  State<ProjectCostsScreen> createState() => _ProjectCostsScreenState();
}

class _ProjectCostsScreenState extends State<ProjectCostsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> projectCosts = [];
  
  // Formato moneda: $ 10.500.200,00
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    calculateCosts();
  }

  Future<void> calculateCosts() async {
    try {
      // 1. Traemos TODOS los datos necesarios
      final resProjects = await http.get(Uri.parse('http://localhost:5064/api/Projects'));
      final resStock = await http.get(Uri.parse('http://localhost:5064/api/StockMovements'));
      final resLabor = await http.get(Uri.parse('http://localhost:5064/api/WorkLogs'));

      if (resProjects.statusCode == 200 && resStock.statusCode == 200 && resLabor.statusCode == 200) {
        
        List<dynamic> projects = json.decode(resProjects.body);
        List<dynamic> stockMovs = json.decode(resStock.body);
        List<dynamic> workLogs = json.decode(resLabor.body);

        List<Map<String, dynamic>> calculatedList = [];

        // 2. Iteramos por cada Proyecto para calcular sus costos
        for (var proj in projects) {
          String projId = proj['id'];
          String projName = proj['name'];

          // A. COSTO DE MATERIALES (Solo salidas 'CONSUMPTION' asignadas a este proyecto)
          // La cantidad viene negativa en salidas, la pasamos a positivo para sumar costo.
          double materialCost = 0;
          var projMaterials = stockMovs.where((m) => m['projectId'] == projId && m['movementType'] == 'CONSUMPTION');
          
          for (var mov in projMaterials) {
            double qty = (mov['quantity'] ?? 0).toDouble().abs(); // Valor absoluto
            double cost = (mov['unitCost'] ?? 0).toDouble(); // Costo histórico del momento
            materialCost += (qty * cost);
          }

          // B. COSTO DE MANO DE OBRA (Horas asignadas a este proyecto)
          // Usamos el 'registeredRateSnapshot' que guardamos en el log, o estimamos un promedio si es 0
          double laborCost = 0;
          double totalHours = 0;
          // NOTA: Tu WorkLog actual no tiene 'projectId' explícito en el modelo que hicimos al principio (solo en Stock).
          // SI QUEREMOS ESTO EXACTO, DEBERÍAMOS AGREGAR 'projectId' AL WORKLOG.
          // Por ahora, asumiremos que si tu backend lo soporta, filtramos. 
          // Si no tienes projectId en WorkLogs, este valor dará 0 (Te explico abajo cómo agregarlo).
          
          // Suponiendo que agregamos la relación o filtramos por lógica de negocio:
          var projLabor = workLogs.where((w) => w['projectId'] == projId); 

          for (var log in projLabor) {
            double hours = (log['hoursWorked'] ?? 0).toDouble();
            double rate = (log['registeredRateSnapshot'] ?? 0).toDouble();
            laborCost += (hours * rate);
            totalHours += hours;
          }

          // Solo agregamos proyectos que tengan algún movimiento (para no ensuciar la lista)
          if (materialCost > 0 || laborCost > 0) {
            calculatedList.add({
              "name": projName,
              "materials": materialCost,
              "labor": laborCost,
              "hours": totalHours,
              "total": materialCost + laborCost
            });
          }
        }

        // Ordenamos por el que más gastó
        calculatedList.sort((a, b) => b['total'].compareTo(a['total']));

        setState(() {
          projectCosts = calculatedList;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error calculando costos: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Centro de Costos (BI)"),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : projectCosts.isEmpty
          ? const Center(child: Text("No hay costos registrados en las obras."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projectCosts.length,
              itemBuilder: (context, index) {
                final item = projectCosts[index];
                double mat = item['materials'];
                double lab = item['labor'];
                double total = item['total'];
                
                // Porcentaje de incidencia
                double matPct = (mat / total);
                double labPct = (lab / total);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con Nombre y Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900, fontSize: 16)),
                            )
                          ],
                        ),
                        const Divider(height: 25),
                        
                        // Barra de Progreso Visual (Materiales vs Mano de Obra)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            height: 10,
                            child: Row(
                              children: [
                                Expanded(flex: (matPct * 100).toInt(), child: Container(color: Colors.orange)),
                                Expanded(flex: (labPct * 100).toInt(), child: Container(color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Detalles Numéricos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Materiales
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [const Icon(Icons.circle, size: 10, color: Colors.orange), const SizedBox(width: 5), Text("Materiales (${(matPct*100).toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 12))]),
                                Text(currencyFormat.format(mat), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            // Mano de Obra
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(children: [Text("Mano de Obra (${(labPct*100).toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 12)), const SizedBox(width: 5), const Icon(Icons.circle, size: 10, color: Colors.blue)]),
                                Text(currencyFormat.format(lab), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("${item['hours'].toStringAsFixed(0)} hs", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}