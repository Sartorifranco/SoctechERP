import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // Asegúrate de tener esta dependencia
import 'package:intl/intl.dart';

class DebtDashboardScreen extends StatefulWidget {
  const DebtDashboardScreen({super.key});

  @override
  State<DebtDashboardScreen> createState() => _DebtDashboardScreenState();
}

class _DebtDashboardScreenState extends State<DebtDashboardScreen> {
  // Estado
  List<dynamic> debtData = [];
  bool isLoading = true;
  double totalGlobalDebt = 0;
  int touchedIndex = -1; // Para la animación al tocar la torta

  // Paleta de colores profesional
  final List<Color> sectionColors = [
    const Color(0xFF0288D1), // Azul
    const Color(0xFFD32F2F), // Rojo
    const Color(0xFF388E3C), // Verde
    const Color(0xFFFBC02D), // Amarillo
    const Color(0xFF7B1FA2), // Violeta
    const Color(0xFFE64A19), // Naranja
  ];

  @override
  void initState() {
    super.initState();
    fetchDebtData();
  }

  // Llamada al Backend
  Future<void> fetchDebtData() async {
    try {
      // Ajusta la URL si usas emulador (10.0.2.2) o dispositivo físico
      final response = await http.get(Uri.parse('http://localhost:5064/api/SupplierInvoices/debt-summary'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        double total = 0;
        for (var item in data) {
          total += (item['totalDebt'] ?? 0).toDouble();
        }

        if (mounted) {
          setState(() {
            debtData = data;
            totalGlobalDebt = total;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estado Financiero"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : debtData.isEmpty 
            ? _buildEmptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // TARJETA DE TOTALES
                    Card(
                      elevation: 4,
                      color: Colors.indigo.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text("Deuda Total con Proveedores", style: TextStyle(fontSize: 16, color: Colors.indigo)),
                            const SizedBox(height: 5),
                            Text(
                              currencyFormat.format(totalGlobalDebt), 
                              style: TextStyle(fontSize: 32, color: Colors.indigo.shade900, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // GRÁFICO DE TORTA INTERACTIVO
                    SizedBox(
                      height: 300,
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
                          sections: List.generate(debtData.length, (i) {
                            final isTouched = i == touchedIndex;
                            final fontSize = isTouched ? 20.0 : 14.0;
                            final radius = isTouched ? 110.0 : 100.0;
                            
                            final item = debtData[i];
                            final double value = (item['totalDebt'] ?? 0).toDouble();
                            final color = sectionColors[i % sectionColors.length];
                            final percent = (value / totalGlobalDebt * 100);

                            return PieChartSectionData(
                              color: color,
                              value: value,
                              title: '${percent.toStringAsFixed(1)}%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // LISTA DE DETALLE (LEYENDA)
                    const Text("Detalle por Proveedor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...List.generate(debtData.length, (i) {
                       final item = debtData[i];
                       final double value = (item['totalDebt'] ?? 0).toDouble();
                       return Card(
                         margin: const EdgeInsets.symmetric(vertical: 5),
                         child: ListTile(
                           leading: CircleAvatar(
                             backgroundColor: sectionColors[i % sectionColors.length],
                             child: const Icon(Icons.store, color: Colors.white, size: 20),
                           ),
                           title: Text(item['provider'], style: const TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: Text("${item['count']} facturas pendientes"),
                           trailing: Text(currencyFormat.format(value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         ),
                       );
                    })
                  ],
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 100, color: Colors.green.shade300),
          const SizedBox(height: 20),
          const Text("¡Estás al día!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("No tienes deudas registradas.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}