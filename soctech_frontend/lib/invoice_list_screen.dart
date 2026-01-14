import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
      print(e);
      setState(() => isLoading = false);
    }
  }

  // --- LÓGICA DE BORRADO Y APROBACIÓN ---
  Future<void> deleteInvoice(String id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text("⛔ ¿Rechazar Factura?"),
        content: const Text("Esta factura se eliminará del sistema. El stock NO se verá afectado."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("RECHAZAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await http.delete(Uri.parse('http://localhost:5064/api/SupplierInvoices/$id'));
      if (response.statusCode == 200) {
        _showSnack("Factura eliminada", Colors.red);
        fetchInvoices();
      } else {
        _showSnack("Error: ${response.body}", Colors.black);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> forceApproveInvoice(String id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text("✅ ¿Forzar Aprobación?"),
        content: const Text("Se aprobará la factura aunque tenga diferencia de precio. \n\n⚠️ ESTO SUMARÁ EL STOCK AUTOMÁTICAMENTE."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true), 
            child: const Text("APROBAR")
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await http.put(Uri.parse('http://localhost:5064/api/SupplierInvoices/$id/approve'));
      if (response.statusCode == 200) {
        _showSnack("Factura aprobada y Stock actualizado ✅", Colors.green);
        fetchInvoices();
      } else {
        _showSnack("Error: ${response.body}", Colors.red);
      }
    } catch (e) {
      print(e);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // --- DETALLE DE FACTURA (CON COMPARATIVA) ---
  void _showDetailDialog(dynamic inv) {
    // 1. Cálculos matemáticos
    double totalInvoice = (inv['totalAmount'] ?? 0).toDouble();
    double totalPO = (inv['purchaseOrderTotal'] ?? 0).toDouble();
    double difference = totalInvoice - totalPO;
    
    // Verificamos si hay Orden de Compra para comparar
    bool hasPO = totalPO > 0;

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Factura #${inv['invoiceNumber']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.all(20),
          children: [
            _detailRow("Proveedor:", inv['providerName']),
            _detailRow("Fecha:", DateFormat('dd/MM/yyyy').format(DateTime.parse(inv['invoiceDate']))),
            const Divider(height: 25),
            
            // --- SECCIÓN DE COMPARATIVA ---
            if (hasPO) ...[
               const Text("COMPARATIVA (3-Way Match)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
               const SizedBox(height: 5),
               _detailRow("Pactado (OC #${inv['purchaseOrderNumber']}):", currencyFormat.format(totalPO)),
               _detailRow("Recibido (Factura):", currencyFormat.format(totalInvoice)),
               const SizedBox(height: 10),
               
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: difference > 1000 ? Colors.red.shade50 : Colors.green.shade50,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: difference > 1000 ? Colors.red.shade200 : Colors.green.shade200)
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text("DIFERENCIA:", style: TextStyle(fontWeight: FontWeight.bold, color: difference > 1000 ? Colors.red : Colors.green[800])),
                     Text(
                       "${difference > 0 ? '+' : ''}${currencyFormat.format(difference)}", 
                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: difference > 1000 ? Colors.red : Colors.green[800])
                     ),
                   ],
                 ),
               ),
               const Divider(height: 25),
            ],

            // --- TOTALES ---
            _detailRow("Neto:", currencyFormat.format(inv['netAmount'])),
            _detailRow("IVA:", currencyFormat.format(inv['vatAmount'])),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL A PAGAR:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(totalInvoice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
            
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))
            )
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Comprobantes"), 
        backgroundColor: Colors.indigo.shade900, 
        foregroundColor: Colors.white
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              final isFlagged = inv['status'] == 'Flagged';
              final color = isFlagged ? Colors.orange.shade50 : Colors.white;
              final borderColor = isFlagged ? Colors.orange : Colors.grey.shade300;
              final statusText = isFlagged ? "⚠️ OBSERVADA (Precio)" : "✅ APROBADA";

              return Card(
                elevation: isFlagged ? 4 : 1,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: borderColor, width: isFlagged ? 2 : 1),
                  borderRadius: BorderRadius.circular(10)
                ),
                color: color,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showDetailDialog(inv), // CLICK PARA VER DETALLE
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv['providerName'] ?? 'Sin Proveedor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Nro: ${inv['invoiceNumber']}", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(inv['totalAmount']),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo.shade900),
                            ),
                          ],
                        ),
                        
                        const Divider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(statusText, style: TextStyle(color: isFlagged ? Colors.deepOrange : Colors.green, fontWeight: FontWeight.bold)),
                            
                            if (isFlagged)
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: "Rechazar",
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deleteInvoice(inv['id']),
                                  ),
                                  const SizedBox(width: 5),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green, 
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text("ACEPTAR"),
                                    onPressed: () => forceApproveInvoice(inv['id']),
                                  ),
                                ],
                              )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: fetchInvoices,
      ),
    );
  }
}