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
      // 1. Traemos TODOS los datos necesarios (Ahora incluimos Contratistas)
      final responses = await Future.wait([
        http.get(Uri.parse('http://localhost:5064/api/Projects')),        // [0]
        http.get(Uri.parse('http://localhost:5064/api/StockMovements')),  // [1]
        http.get(Uri.parse('http://localhost:5064/api/WorkLogs')),        // [2]
        http.get(Uri.parse('http://localhost:5064/api/Contractors/jobs')) // [3] <--- NUEVO
      ]);

      if (responses[0].statusCode == 200) {
        
        List<dynamic> projects = json.decode(responses[0].body);
        List<dynamic> stockMovs = json.decode(responses[1].body);
        List<dynamic> workLogs = json.decode(responses[2].body);
        List<dynamic> contractorJobs = json.decode(responses[3].body); // <--- NUEVO

        List<Map<String, dynamic>> calculatedList = [];

        // 2. Iteramos por cada Proyecto para calcular sus costos
        for (var proj in projects) {
          String projId = proj['id'];
          String projName = proj['name'];

          // A. COSTO DE MATERIALES (Stock)
          double materialCost = 0;
          var projMaterials = stockMovs.where((m) => m['projectId'] == projId && m['movementType'] == 'CONSUMPTION');
          for (var mov in projMaterials) {
            double qty = (mov['quantity'] ?? 0).toDouble().abs(); 
            double cost = (mov['unitCost'] ?? 0).toDouble(); 
            materialCost += (qty * cost);
          }

          // B. COSTO DE MANO DE OBRA PROPIA (Empleados)
          double laborCost = 0;
          double totalHours = 0;
          
          // Filtramos logs que tengan este projectId asignado
          var projLabor = workLogs.where((w) => w['projectId'] == projId); 

          for (var log in projLabor) {
            double hours = (log['hoursWorked'] ?? 0).toDouble();
            double rate = (log['registeredRateSnapshot'] ?? 0).toDouble();
            
            // Si es UOCRA (por hora) multiplicamos directo.
            // Si es Mensual (FDC/UECARA), el rate es el sueldo mensual.
            // Para simplificar el BI, asumimos costo hora = rate / 200 si el valor es muy alto (> 100.000)
            // O usamos la lógica que definimos antes. Por ahora sumamos costo directo estimado.
            
            double costoLog = 0;
            if (rate > 200000) { // Es sueldo mensual
               costoLog = hours * (rate / 200);
            } else { // Es valor hora
               costoLog = hours * rate;
            }

            laborCost += costoLog;
            totalHours += hours;
          }

          // C. COSTO DE SUBCONTRATISTAS (Terceros) <--- NUEVO CÁLCULO
          double contractorCost = 0;
          var projContractors = contractorJobs.where((j) => j['projectId'] == projId);
          
          for (var job in projContractors) {
             contractorCost += (job['agreedAmount'] ?? 0).toDouble();
          }

          double totalProject = materialCost + laborCost + contractorCost;

          // Solo mostramos si hay gastos
          if (totalProject > 0) {
            calculatedList.add({
              "name": projName,
              "materials": materialCost,
              "labor": laborCost,
              "contractors": contractorCost, // Guardamos el valor
              "hours": totalHours,
              "total": totalProject
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
                double cont = item['contractors']; // Terceros
                double total = item['total'];
                
                // Porcentajes de incidencia (evitando división por 0)
                double matPct = total > 0 ? (mat / total) : 0;
                double labPct = total > 0 ? (lab / total) : 0;
                double contPct = total > 0 ? (cont / total) : 0;

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
                        
                        // Barra de Progreso Visual (TRICOLOR)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            height: 12, // Un poco más gruesa
                            child: Row(
                              children: [
                                Expanded(flex: (matPct * 100).toInt(), child: Container(color: Colors.orange, child: const Tooltip(message: "Materiales"))),
                                Expanded(flex: (labPct * 100).toInt(), child: Container(color: Colors.blue, child: const Tooltip(message: "RRHH Propio"))),
                                Expanded(flex: (contPct * 100).toInt(), child: Container(color: Colors.purple, child: const Tooltip(message: "Subcontratos"))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Detalles Numéricos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 1. Materiales
                            _buildDetailItem("Materiales", mat, matPct, Colors.orange),
                            // 2. Propios
                            _buildDetailItem("Propios", lab, labPct, Colors.blue),
                            // 3. Terceros
                            _buildDetailItem("Terceros", cont, contPct, Colors.purple),
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

  Widget _buildDetailItem(String label, double amount, double pct, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 4),
            Text("$label (${(pct*100).toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}