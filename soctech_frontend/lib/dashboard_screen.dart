import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variables para guardar los datos
  double totalValue = 0;
  int activeProjects = 0;
  int lowStockCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Dashboard/stats'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Usamos 'toDouble' para evitar errores int/double
          totalValue = (data['totalInventoryValue'] ?? 0).toDouble();
          activeProjects = data['activeProjects'] ?? 0;
          lowStockCount = data['lowStockCount'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando dashboard: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo gris clarito para resaltar las tarjetas
      backgroundColor: Colors.grey[100], 
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumen General",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- TARJETA 1: VALOR DEL INVENTARIO ---
                  _buildStatCard(
                    title: "Valor en Depósito",
                    value: "\$${totalValue.toStringAsFixed(2)}",
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      // --- TARJETA 2: OBRAS ACTIVAS ---
                      Expanded(
                        child: _buildStatCard(
                          title: "Obras Activas",
                          value: activeProjects.toString(),
                          icon: Icons.apartment,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // --- TARJETA 3: ALERTA STOCK ---
                      Expanded(
                        child: _buildStatCard(
                          title: "Stock Bajo",
                          value: lowStockCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Accesos Rápidos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  
                  // Aquí puedes poner accesos directos si quieres en el futuro
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Selecciona una opción del menú lateral para comenzar a gestionar.")),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  // Widget auxiliar para dibujar las tarjetas bonitas
  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 30),
              // Un puntito decorativo
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 15),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}