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
  
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  final String baseUrl = 'http://localhost:5064/api'; // Ajustar si es necesario

  @override
  void initState() {
    super.initState();
    calculateCosts();
  }

  Future<List<dynamic>> fetchSafe(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error en $endpoint: $e");
    }
    return [];
  }

  Future<void> calculateCosts() async {
    try {
      final responses = await Future.wait([
        fetchSafe('Projects'),         
        fetchSafe('StockMovements'),   
        fetchSafe('WorkLogs'),         
        fetchSafe('Contractors/jobs')  
      ]);

      List<dynamic> projects = responses[0];
      List<dynamic> stockMovs = responses[1];
      List<dynamic> workLogs = responses[2];
      List<dynamic> contractorJobs = responses[3];

      List<Map<String, dynamic>> calculatedList = [];

      for (var proj in projects) {
        // Filtramos obras terminadas/inactivas si quieres
        if (proj['isActive'] == false) continue;

        String projId = proj['id'];
        String projName = proj['name'];

        // --- A. CORRECCIÓN CRÍTICA AQUÍ ---
        // Ahora filtramos por 'ProjectConsumption' que es lo que manda el Backend nuevo
        double materialCost = 0;
        var projMaterials = stockMovs.where((m) => 
            m['projectId'] == projId && 
            (m['movementType'] == 'ProjectConsumption' || m['movementType'] == 'ProjectConsumption') 
        );

        for (var mov in projMaterials) {
          double qty = (mov['quantity'] ?? 0).toDouble().abs(); 
          double cost = (mov['unitCost'] ?? 0).toDouble(); 
          materialCost += (qty * cost);
        }
        // ----------------------------------

        // B. MANO DE OBRA
        double laborCost = 0;
        var projLabor = workLogs.where((w) => w['projectId'] == projId); 
        for (var log in projLabor) {
          double hours = (log['hoursWorked'] ?? 0).toDouble();
          double rate = (log['totalCost'] ?? log['registeredRateSnapshot'] ?? 0).toDouble();
          
          // Si el costo ya viene calculado en el backend (TotalCost), usamos ese.
          // Si no, calculamos horas * precio.
          if (rate > 0) {
             laborCost += (rate); 
          }
        }

        // C. SUBCONTRATISTAS
        double contractorCost = 0;
        var projContractors = contractorJobs.where((j) => j['projectId'] == projId);
        for (var job in projContractors) {
           contractorCost += (job['agreedAmount'] ?? 0).toDouble();
        }

        double totalProject = materialCost + laborCost + contractorCost;

        calculatedList.add({
          "name": projName,
          "materials": materialCost,
          "labor": laborCost,
          "contractors": contractorCost,
          "total": totalProject
        });
      }

      calculatedList.sort((a, b) => b['total'].compareTo(a['total']));

      if (mounted) {
        setState(() {
          projectCosts = calculatedList;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error calculando costos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Costos"),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : projectCosts.isEmpty
          ? const Center(child: Text("Sin datos de costos registrados."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projectCosts.length,
              itemBuilder: (context, index) {
                final item = projectCosts[index];
                return _buildProjectCard(item);
              },
            ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> item) {
    double total = item['total'];
    double mat = item['materials'];
    double lab = item['labor'];
    double cont = item['contractors'];

    // Evitar división por cero
    double matPct = total > 0 ? mat / total : 0;
    double labPct = total > 0 ? lab / total : 0;
    double contPct = total > 0 ? cont / total : 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900], fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            
            // Barra de progreso visual
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (mat > 0) Expanded(flex: (matPct * 100).toInt(), child: Container(color: Colors.orange)),
                    if (lab > 0) Expanded(flex: (labPct * 100).toInt(), child: Container(color: Colors.blue)),
                    if (cont > 0) Expanded(flex: (contPct * 100).toInt(), child: Container(color: Colors.purple)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Leyenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem("Mat.", mat, Colors.orange),
                _legendItem("MO", lab, Colors.blue),
                _legendItem("Sub.", cont, Colors.purple),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, double amount, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}