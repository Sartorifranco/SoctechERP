import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<dynamic> invoices = [];
  bool isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/SupplierInvoices'));
      if (response.statusCode == 200) {
        setState(() {
          invoices = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Helper para el color del estado
  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Flagged': return Colors.orange; // La que te salió a vos
      case 'Paid': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String translateStatus(String status) {
    switch (status) {
      case 'Approved': return "APROBADA";
      case 'Flagged': return "OBSERVADA (Diferencia)";
      case 'Paid': return "PAGADA";
      default: return "BORRADOR";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Comprobantes"),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoices.isEmpty
              ? const Center(child: Text("No hay facturas cargadas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final date = DateTime.parse(inv['invoiceDate']);
                    final total = (inv['totalAmount'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      // Borde izquierdo de color según estado
                      shape: Border(left: BorderSide(color: getStatusColor(inv['status']), width: 5)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(inv['providerName'] ?? 'Proveedor Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Factura: ${inv['invoiceNumber']}"),
                            Text("Fecha: ${DateFormat('dd/MM/yyyy').format(date)}"),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: getStatusColor(inv['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(translateStatus(inv['status']), 
                                style: TextStyle(color: getStatusColor(inv['status']), fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                            )
                          ],
                        ),
                        trailing: Text(
                          currencyFormat.format(total),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        onTap: () {
                          // Navegamos al detalle pasando el objeto factura entero
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvoiceDetailScreen(invoice: inv),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}