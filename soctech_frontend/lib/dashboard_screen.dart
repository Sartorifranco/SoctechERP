import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variables de Estado
  int activeProjects = 0;
  int activeEmployees = 0;
  double totalStockValue = 0;
  bool isLoading = true;

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      // Hacemos 3 llamados en paralelo para cargar rápido
      final responses = await Future.wait([
        http.get(Uri.parse('http://localhost:5064/api/Projects')),
        http.get(Uri.parse('http://localhost:5064/api/Employees')),
        http.get(Uri.parse('http://localhost:5064/api/Products')),
      ]);

      if (responses[0].statusCode == 200 && 
          responses[1].statusCode == 200 && 
          responses[2].statusCode == 200) {
        
        // 1. Obras Activas
        List<dynamic> projects = json.decode(responses[0].body);
        int projCount = projects.where((p) => p['isActive'] == true).length;

        // 2. Personal Activo
        List<dynamic> employees = json.decode(responses[1].body);
        int empCount = employees.where((e) => e['isActive'] == true).length;

        // 3. Valorización de Stock (Cantidad * Costo)
        List<dynamic> products = json.decode(responses[2].body);
        double stockVal = 0;
        for (var p in products) {
          double qty = (p['stock'] ?? 0).toDouble();
          double cost = (p['costPrice'] ?? 0).toDouble();
          stockVal += (qty * cost);
        }

        setState(() {
          activeProjects = projCount;
          activeEmployees = empCount;
          totalStockValue = stockVal;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando dashboard: $e");
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar ya viene del MainLayout, pero si lo usas solo:
      // appBar: AppBar(title: const Text("Tablero de Comando")),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumen Ejecutivo", 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)
                  ),
                  const SizedBox(height: 20),
                  
                  // --- TARJETAS DE KPIs ---
                  Row(
                    children: [
                      _buildKPICard("Obras Activas", activeProjects.toString(), Icons.apartment, Colors.orange),
                      const SizedBox(width: 16),
                      _buildKPICard("Personal", activeEmployees.toString(), Icons.groups, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildKPICard("Valor en Stock", currencyFormat.format(totalStockValue), Icons.attach_money, Colors.green, fullWidth: true),

                  const SizedBox(height: 30),
                  const Text(
                    "Accesos Rápidos", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
                  ),
                  const Divider(),
                  
                  // Aquí puedes poner accesos directos o gráficos simples
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.add, color: Colors.white)),
                    title: const Text("Nueva Compra de Materiales"),
                    subtitle: const Text("Registrar ingreso de stock"),
                    onTap: () {
                      // Navegación rápida (opcional)
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}