import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SalesInvoiceListScreen extends StatefulWidget {
  const SalesInvoiceListScreen({super.key});

  @override
  State<SalesInvoiceListScreen> createState() => _SalesInvoiceListScreenState();
}

class _SalesInvoiceListScreenState extends State<SalesInvoiceListScreen> {
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
      final response = await http.get(Uri.parse('http://localhost:5064/api/SalesInvoices'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Facturación"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoices.isEmpty
              ? const Center(child: Text("No has emitido facturas aún."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final date = DateTime.parse(inv['invoiceDate']);
                    final total = (inv['grossTotal'] ?? 0).toDouble();
                    final collectible = (inv['collectibleAmount'] ?? 0).toDouble();
                    final retainage = (inv['retainageAmount'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: const Icon(Icons.receipt, color: Colors.indigo),
                        ),
                        title: Text(inv['clientName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Fecha: ${DateFormat('dd/MM/yyyy').format(date)}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Facturado", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            color: Colors.grey.shade50,
                            child: Column(
                              children: [
                                _rowDetail("Concepto", inv['concept']),
                                const Divider(),
                                _rowDetail("Obra", inv['projectName'] ?? "General"),
                                _rowDetail("Neto Gravado", currencyFormat.format(inv['netAmount'])),
                                _rowDetail("IVA (${inv['vatPercentage']}%)", currencyFormat.format(inv['vatAmount'])),
                                const Divider(),
                                if (retainage > 0) ...[
                                  _rowDetail("Fondo de Reparo (Retenido)", "- ${currencyFormat.format(retainage)}", color: Colors.red),
                                  const SizedBox(height: 5),
                                  _rowDetail("A COBRAR (CASH)", currencyFormat.format(collectible), isBold: true, color: Colors.green),
                                ] else 
                                  _rowDetail("TOTAL A COBRAR", currencyFormat.format(total), isBold: true, color: Colors.green),
                                  
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                         // Aquí iría la función para generar PDF
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Imprimiendo PDF...")));
                                      }, 
                                      icon: const Icon(Icons.print), 
                                      label: const Text("Reimprimir")
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _rowDetail(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}