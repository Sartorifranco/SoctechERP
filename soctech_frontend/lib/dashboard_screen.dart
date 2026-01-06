import 'dart:async'; // Necesario para el Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// --- IMPORTS PARA NAVEGACIÓN ---
import 'treasury_screen.dart';
import 'sales_invoice_screen.dart';
import 'invoice_entry_screen.dart';
import 'projects_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variables de Estado (KPIs)
  bool isLoading = true;
  double totalCash = 0;
  double salesMonth = 0;
  double debtPending = 0;
  int activeProjects = 0;

  Timer? _autoRefreshTimer; // El "Latido" del sistema

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    fetchKPIs(); // Carga inicial
    
    // AUTO-ACTUALIZACIÓN: Cada 5 segundos refresca los datos solo
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchKPIs(isBackground: true);
    });
  }

  @override
  void dispose() {
    // IMPORTANTE: Matar el timer cuando salimos de la pantalla para no consumir memoria
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // isBackground: Si es true, no mostramos el círculo de carga, solo actualizamos los números
  Future<void> fetchKPIs({bool isBackground = false}) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Dashboard/kpi'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            totalCash = (data['totalCash'] ?? 0).toDouble();
            salesMonth = (data['salesMonth'] ?? 0).toDouble();
            debtPending = (data['debtPending'] ?? 0).toDouble();
            activeProjects = data['activeProjects'] ?? 0;
            // Solo quitamos el loading si era la carga inicial
            if (!isBackground) isLoading = false;
          });
        }
      }
    } catch (e) {
      if(mounted && !isBackground) setState(() => isLoading = false);
      // En background fallamos silenciosamente para no molestar al usuario
    }
  }

  // Función auxiliar para navegar y actualizar al volver
  void _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    // Al volver (pop), forzamos una actualización inmediata
    fetchKPIs();
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos si es pantalla ancha (Desktop)
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            // physics: const AlwaysScrollableScrollPhysics(), // Ya no es necesario el pull-to-refresh
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER (SE ADAPTA AL ANCHO)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade900,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Resumen Financiero", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 5),
                      Text("Hola, Admin 👋", style: TextStyle(color: Colors.white, fontSize: isWide ? 32 : 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      
                      // TARJETA PRINCIPAL (Liquidez)
                      GestureDetector(
                        onTap: () => _navigateAndRefresh(const TreasuryScreen()),
                        child: Container(
                          width: isWide ? 500 : double.infinity, 
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0,5))]
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
                                child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 36),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Disponibilidad Total", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  // Animación implícita de cambio de número (opcional, por ahora texto plano)
                                  Text(currencyFormat.format(totalCash), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 2. GRILLA DE KPIs (RESPONSIVE)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Indicadores Clave", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          // Indicador visual discreto de "En vivo"
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.green),
                                SizedBox(width: 5),
                                Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // LAYOUT RESPONSIVO
                      isWide 
                      ? Row( 
                          children: [
                            _buildKpiCard("Ventas Mes", currencyFormat.format(salesMonth), Icons.trending_up, Colors.blue, 
                              () => _navigateAndRefresh(const SalesInvoiceScreen())),
                            const SizedBox(width: 20),
                            _buildKpiCard("Deuda Prov.", currencyFormat.format(debtPending), Icons.money_off, Colors.red, 
                              () => _navigateAndRefresh(const InvoiceEntryScreen())),
                            const SizedBox(width: 20),
                            _buildKpiCard("Obras Activas", activeProjects.toString(), Icons.apartment, Colors.orange, 
                              () => _navigateAndRefresh(const ProjectsScreen())),
                            const SizedBox(width: 20),
                            _buildKpiCard("Tesorería", "Gestionar", Icons.pie_chart, Colors.purple, 
                              () => _navigateAndRefresh(const TreasuryScreen())),
                          ],
                        )
                      : Column( 
                          children: [
                            Row(children: [
                              _buildKpiCard("Ventas Mes", currencyFormat.format(salesMonth), Icons.trending_up, Colors.blue, 
                                () => _navigateAndRefresh(const SalesInvoiceScreen())),
                              const SizedBox(width: 15),
                              _buildKpiCard("Deuda Prov.", currencyFormat.format(debtPending), Icons.money_off, Colors.red, 
                                () => _navigateAndRefresh(const InvoiceEntryScreen())),
                            ]),
                            const SizedBox(height: 15),
                            Row(children: [
                              _buildKpiCard("Obras Activas", activeProjects.toString(), Icons.apartment, Colors.orange, 
                                () => _navigateAndRefresh(const ProjectsScreen())),
                              const SizedBox(width: 15),
                              _buildKpiCard("Tesorería", "Gestionar", Icons.pie_chart, Colors.purple, 
                                () => _navigateAndRefresh(const TreasuryScreen())),
                            ]),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 3. BARRA DE ACCIONES RÁPIDAS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateAndRefresh(const InvoiceEntryScreen()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.red.shade100))
                          ),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text("REGISTRAR COMPRA"),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateAndRefresh(const SalesInvoiceScreen()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.green.shade100))
                          ),
                          icon: const Icon(Icons.attach_money),
                          label: const Text("REGISTRAR VENTA"),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0,2))],
            border: Border.all(color: Colors.grey.shade100)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}