import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; 
import 'project_phases_screen.dart'; // <--- IMPORTANTE: Asegúrate de tener este archivo creado

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
  
  // Para el Gráfico
  int touchedIndex = -1; // Para saber qué sección toca el usuario
  Map<String, double> expensesByCategory = {};

  @override
  void initState() {
    super.initState();
    fetchProjectMovements();
  }

  Future<void> fetchProjectMovements() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/StockMovements'));

      if (response.statusCode == 200) {
        List<dynamic> allMovements = json.decode(response.body);
        
        // FILTRO: Solo consumo de esta obra
        final projectMovements = allMovements.where((m) => 
          m['projectId'] == widget.project['id'] && 
          m['movementType'] == 'CONSUMPTION'
        ).toList();

        // CÁLCULO FINANCIERO Y AGRUPACIÓN
        double calculatedTotal = 0;
        Map<String, double> tempMap = {};

        for (var mov in projectMovements) {
          double cost = (mov['quantity'] * mov['unitCost']).abs();
          calculatedTotal += cost;

          // Agrupar por nombre del material (Reference)
          String key = mov['reference'] ?? "Varios";
          if (tempMap.containsKey(key)) {
            tempMap[key] = tempMap[key]! + cost;
          } else {
            tempMap[key] = cost;
          }
        }

        setState(() {
          movements = projectMovements;
          totalSpent = calculatedTotal;
          expensesByCategory = tempMap;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Genera los datos visuales para el gráfico
  List<PieChartSectionData> showingSections() {
    List<Color> colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal
    ];

    int index = 0;
    return expensesByCategory.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final color = colors[index % colors.length];
      
      // Porcentaje
      final percent = (entry.value / totalSpent * 100).toStringAsFixed(1);

      final section = PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? "\$${entry.value}" : "$percent%",
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
      
      index++;
      return section;
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
          // BOTÓN PARA GESTIONAR FASES (Nivel Oracle)
          IconButton(
            icon: const Icon(Icons.layers), 
            tooltip: "Gestionar Fases",
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProjectPhasesScreen(project: widget.project)),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. RESUMEN EJECUTIVO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.indigo,
              child: Column(
                children: [
                  const Text("Ejecutado Total", style: TextStyle(color: Colors.white70)),
                  Text(
                    "\$${totalSpent.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (budget > 0)
                    LinearProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                      backgroundColor: Colors.indigo.shade800,
                      color: progress > 1 ? Colors.redAccent : Colors.greenAccent,
                    ),
                ],
              ),
            ),

            // --- 2. GRÁFICO DE DISTRIBUCIÓN (BI) ---
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
                    centerSpaceRadius: 40, // Efecto Donut
                    sections: showingSections(),
                  ),
                ),
              ),
              // Referencias del gráfico
              Wrap(
                spacing: 8.0,
                children: expensesByCategory.keys.toList().asMap().entries.map((e) {
                  List<Color> colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal];
                  return Chip(
                    avatar: CircleAvatar(backgroundColor: colors[e.key % colors.length], radius: 5),
                    label: Text(e.value),
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
              const Divider(thickness: 1, height: 40),
            ],

            // --- 3. DETALLE DE MOVIMIENTOS ---
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Últimos Movimientos", style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ),
            
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(), // Scroll lo maneja la página entera
              shrinkWrap: true,
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final mov = movements[index];
                return ListTile(
                  leading: const Icon(Icons.outbound, color: Colors.redAccent),
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