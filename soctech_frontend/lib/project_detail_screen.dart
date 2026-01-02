import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; 
import 'project_phases_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  // Datos crudos
  List<dynamic> movements = [];
  List<dynamic> workLogs = []; // <--- NUEVO: Lista de horas trabajadas
  
  bool isLoading = true;
  double totalSpent = 0;
  
  // Para el Gráfico
  int touchedIndex = -1;
  Map<String, double> expensesByCategory = {};

  @override
  void initState() {
    super.initState();
    fetchAllProjectData();
  }

  Future<void> fetchAllProjectData() async {
    try {
      final projectId = widget.project['id'];
      
      // 1. Traer Movimientos de Stock
      final resStock = await http.get(Uri.parse('http://localhost:5064/api/StockMovements'));
      // 2. Traer Partes Diarios (Mano de Obra)
      final resLabor = await http.get(Uri.parse('http://localhost:5064/api/WorkLogs?projectId=$projectId'));

      if (resStock.statusCode == 200 && resLabor.statusCode == 200) {
        
        // A. PROCESAR MATERIALES
        List<dynamic> allMovements = json.decode(resStock.body);
        final projectMovements = allMovements.where((m) => 
          m['projectId'] == projectId && m['movementType'] == 'CONSUMPTION'
        ).toList();

        // B. PROCESAR MANO DE OBRA
        List<dynamic> projectLabor = json.decode(resLabor.body);

        // C. CÁLCULO UNIFICADO
        double calculatedTotal = 0;
        Map<String, double> tempMap = {};

        // Sumar Materiales
        for (var mov in projectMovements) {
          double cost = (mov['quantity'] * mov['unitCost']).abs();
          calculatedTotal += cost;
          
          String key = mov['reference'] ?? "Materiales Varios";
          tempMap[key] = (tempMap[key] ?? 0) + cost;
        }

        // Sumar Mano de Obra (NUEVO)
        double totalLaborCost = 0;
        for (var log in projectLabor) {
          // Calculamos costo histórico: Horas * PrecioSnapshot
          double cost = (log['hoursWorked'] * (log['registeredRateSnapshot'] ?? 0)).toDouble();
          totalLaborCost += cost;
          calculatedTotal += cost;
        }

        // Agregar "Mano de Obra" como una categoría grande en el gráfico
        if (totalLaborCost > 0) {
          tempMap["Mano de Obra"] = totalLaborCost;
        }

        setState(() {
          movements = projectMovements;
          workLogs = projectLabor;
          totalSpent = calculatedTotal;
          expensesByCategory = tempMap;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Genera los datos visuales para el gráfico
  List<PieChartSectionData> showingSections() {
    List<Color> colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal, Colors.indigo
    ];

    int index = 0;
    return expensesByCategory.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final color = entry.key == "Mano de Obra" ? Colors.redAccent : colors[index % colors.length]; // Mano de obra rojo destacado
      
      final percent = (entry.value / totalSpent * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? "\$${entry.value.toStringAsFixed(0)}" : "$percent%",
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double budget = (widget.project['budget'] ?? 0).toDouble();
    final double progress = budget > 0 ? (totalSpent / budget) : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers), 
            tooltip: "Gestionar Fases",
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectPhasesScreen(
                    project: widget.project, 
                    projectMovements: movements,
                    projectWorkLogs: workLogs, // <--- PASAMOS TAMBIÉN LA MANO DE OBRA
                  )
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. RESUMEN EJECUTIVO (Total Real) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.indigo,
              child: Column(
                children: [
                  const Text("Costo Real Total (Mat + MO)", style: TextStyle(color: Colors.white70)),
                  Text(
                    "\$${totalSpent.toStringAsFixed(0)}", // Sin decimales para limpieza
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (budget > 0)
                    LinearProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                      backgroundColor: Colors.indigo.shade800,
                      color: progress > 1 ? Colors.redAccent : Colors.greenAccent,
                    ),
                  if (budget > 0)
                     Padding(
                       padding: const EdgeInsets.only(top: 5),
                       child: Text("${(progress * 100).toStringAsFixed(1)}% del Presupuesto", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                     )
                ],
              ),
            ),

            // --- 2. GRÁFICO DE DISTRIBUCIÓN ---
            if (!isLoading && expensesByCategory.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text("Distribución de Gastos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: showingSections(),
                  ),
                ),
              ),
              // Referencias
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: expensesByCategory.keys.toList().asMap().entries.map((e) {
                    List<Color> colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal, Colors.indigo];
                     final color = e.value == "Mano de Obra" ? Colors.redAccent : colors[e.key % colors.length];
                    return Chip(
                      avatar: CircleAvatar(backgroundColor: color, radius: 5),
                      label: Text(e.value),
                      backgroundColor: Colors.grey.shade100,
                    );
                  }).toList(),
                ),
              ),
              const Divider(thickness: 1, height: 40),
            ],

            // --- 3. ÚLTIMOS GASTOS (Mixto) ---
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Últimos Movimientos", style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ),
            
            // Unimos listas para mostrar historial cronológico (opcional, aquí solo muestro materiales por simplicidad
            // o podrías hacer un ListView combinado). Por ahora dejamos materiales para no saturar.
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: movements.length > 5 ? 5 : movements.length,
              itemBuilder: (context, index) {
                final mov = movements[index];
                return ListTile(
                  leading: const Icon(Icons.outbound, color: Colors.blueGrey),
                  title: Text(mov['reference'] ?? "Material"),
                  subtitle: Text(mov['date'].toString().split('T')[0]),
                  trailing: Text(
                    "\$${(mov['quantity'] * mov['unitCost']).abs().toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}