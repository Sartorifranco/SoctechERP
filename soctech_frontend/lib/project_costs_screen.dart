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
  
  // URL Base correcta
  final String baseUrl = 'http://localhost:5064/api';

  @override
  void initState() {
    super.initState();
    calculateCosts();
  }

  // Helper para evitar que la app explote si un módulo no está listo en el Backend
  Future<List<dynamic>> fetchSafe(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Módulo $endpoint no disponible o error de conexión.");
    }
    return []; // Retorna lista vacía si falla, para que el resto siga funcionando
  }

  Future<void> calculateCosts() async {
    try {
      // 1. Traemos los datos de forma SEGURA
      final responses = await Future.wait([
        fetchSafe('Projects'),         // [0]
        fetchSafe('StockMovements'),   // [1]
        fetchSafe('WorkLogs'),         // [2] (Si no existe, devuelve [])
        fetchSafe('Contractors/jobs')  // [3] (Si no existe, devuelve [])
      ]);

      List<dynamic> projects = responses[0];
      List<dynamic> stockMovs = responses[1];
      List<dynamic> workLogs = responses[2];
      List<dynamic> contractorJobs = responses[3];

      List<Map<String, dynamic>> calculatedList = [];

      // 2. Iteramos por cada Proyecto
      for (var proj in projects) {
        // Solo procesamos obras activas
        if (proj['isActive'] == false && proj['status'] == 'Finished') continue;

        String projId = proj['id'];
        String projName = proj['name'];

        // A. COSTO DE MATERIALES (Stock)
        double materialCost = 0;
        var projMaterials = stockMovs.where((m) => m['projectId'] == projId && (m['movementType'] == 'CONSUMPTION' || m['movementType'] == 'DISPATCH'));
        for (var mov in projMaterials) {
          double qty = (mov['quantity'] ?? 0).toDouble().abs(); 
          // Si tienes unitCost guardado en el movimiento, úsalo. Si no, habría que buscar el producto.
          // Asumimos que tu backend de Salidas guardó el costo histórico o actual.
          // Si mov['unitCost'] viene nulo, temporalmente usamos un estimado o 0.
          double cost = (mov['unitCost'] ?? 0).toDouble(); 
          materialCost += (qty * cost);
        }

        // B. COSTO DE MANO DE OBRA (Empleados)
        double laborCost = 0;
        double totalHours = 0;
        var projLabor = workLogs.where((w) => w['projectId'] == projId); 

        for (var log in projLabor) {
          double hours = (log['hoursWorked'] ?? 0).toDouble();
          double rate = (log['registeredRateSnapshot'] ?? 0).toDouble();
          
          double costoLog = 0;
          if (rate > 200000) { // Lógica de sueldo mensual
             costoLog = hours * (rate / 200);
          } else { // Valor hora
             costoLog = hours * rate;
          }
          laborCost += costoLog;
          totalHours += hours;
        }

        // C. COSTO DE SUBCONTRATISTAS
        double contractorCost = 0;
        var projContractors = contractorJobs.where((j) => j['projectId'] == projId);
        for (var job in projContractors) {
           contractorCost += (job['agreedAmount'] ?? 0).toDouble();
        }

        double totalProject = materialCost + laborCost + contractorCost;

        // Agregamos a la lista (incluso si es 0, para ver que la obra existe)
        calculatedList.add({
          "name": projName,
          "materials": materialCost,
          "labor": laborCost,
          "contractors": contractorCost,
          "hours": totalHours,
          "total": totalProject
        });
      }

      // Ordenamos por gasto descendente
      calculatedList.sort((a, b) => b['total'].compareTo(a['total']));

      if (mounted) {
        setState(() {
          projectCosts = calculatedList;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error crítico calculando costos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard de Costos"),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : projectCosts.isEmpty
          ? const Center(child: Text("No hay obras activas o datos de costos."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projectCosts.length,
              itemBuilder: (context, index) {
                final item = projectCosts[index];
                double mat = item['materials'];
                double lab = item['labor'];
                double cont = item['contractors']; 
                double total = item['total'];
                
                // Porcentajes para la barra visual
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
                        // Header
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
                        
                        // Barra Tricolor (Visualización rápida)
                        if (total > 0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: SizedBox(
                              height: 12,
                              child: Row(
                                children: [
                                  if (matPct > 0) Expanded(flex: (matPct * 100).toInt(), child: Container(color: Colors.orange)),
                                  if (labPct > 0) Expanded(flex: (labPct * 100).toInt(), child: Container(color: Colors.blue)),
                                  if (contPct > 0) Expanded(flex: (contPct * 100).toInt(), child: Container(color: Colors.purple)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Detalles Numéricos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDetailItem("Materiales", mat, matPct, Colors.orange),
                            _buildDetailItem("RRHH", lab, labPct, Colors.blue),
                            _buildDetailItem("Subcontratos", cont, contPct, Colors.purple),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 4),
            Text("$label ${(pct*100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}