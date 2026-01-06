import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  String projectName = "Cargando nombre de obra...";

  @override
  void initState() {
    super.initState();
    _fetchProjectName();
  }

  // --- BUSCAR NOMBRE DE OBRA ---
  Future<void> _fetchProjectName() async {
    final projectId = widget.invoice['projectId'];
    
    if (projectId == null) {
      if (mounted) setState(() => projectName = "Sin Imputación (General)");
      return;
    }

    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Projects/$projectId'));
      
      if (response.statusCode == 200) {
        final project = json.decode(response.body);
        if (mounted) {
          setState(() => projectName = project['name']); // ¡Nombre encontrado!
        }
      } else {
        if (mounted) setState(() => projectName = "Obra no encontrada (ID Inválido)");
      }
    } catch (e) {
      if (mounted) setState(() => projectName = "Error de conexión");
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Flagged': return Colors.orange;
      case 'Paid': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String translateStatus(String status) {
    switch (status) {
      case 'Approved': return "APROBADA";
      case 'Flagged': return "OBSERVADA (Diferencia de Precio)";
      case 'Paid': return "PAGADA";
      default: return "BORRADOR";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    final invoice = widget.invoice;
    
    final date = DateTime.parse(invoice['invoiceDate']);
    final dueDate = DateTime.parse(invoice['dueDate']);
    
    final net = (invoice['netAmount'] ?? 0).toDouble();
    final vat = (invoice['vatAmount'] ?? 0).toDouble();
    final taxes = (invoice['otherTaxes'] ?? 0).toDouble();
    final total = (invoice['totalAmount'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text("Factura #${invoice['invoiceNumber']}"),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENCABEZADO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                children: [
                  const Icon(Icons.store, size: 40, color: Colors.indigo),
                  const SizedBox(height: 10),
                  Text(
                    invoice['providerName'] ?? "Proveedor Desconocido",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(invoice['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: getStatusColor(invoice['status']))
                    ),
                    child: Text(
                      translateStatus(invoice['status']),
                      style: TextStyle(color: getStatusColor(invoice['status']), fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // --- DATOS GENERALES ---
            const Text("Detalles del Comprobante", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow("Fecha Emisión:", DateFormat('dd/MM/yyyy').format(date)),
                    const Divider(),
                    _buildRow("Fecha Vencimiento:", DateFormat('dd/MM/yyyy').format(dueDate), isWarning: true),
                    const Divider(),
                    // Muestra el nombre de la obra recuperado
                    _buildRow("Imputación (Obra):", projectName), 
                    const Divider(),
                    _buildRow("Orden de Compra:", invoice['relatedPurchaseOrderId'] != null ? "VINCULADA (3-Way Match)" : "SIN ORDEN PREVIA"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- IMPORTES ---
            const Text("Desglose Financiero", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow("Neto Gravado:", currencyFormat.format(net)),
                    _buildRow("IVA Total:", currencyFormat.format(vat)),
                    _buildRow("Percepciones / Otros:", currencyFormat.format(taxes)),
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL A PAGAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(currencyFormat.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green)),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- BOTONES DE ACCIÓN ---
            if (invoice['status'] == 'Flagged')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15)
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Funcionalidad: El gerente aprueba la diferencia y libera el pago.")));
                  }, 
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("AUTORIZAR PAGO (Forzar)"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, color: isWarning ? Colors.red : Colors.black87)
            ),
          ),
        ],
      ),
    );
  }
}