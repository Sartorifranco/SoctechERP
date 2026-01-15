import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// IMPORT CRÍTICO: Usamos el nombre de tu paquete para encontrar el archivo sin importar dónde estés
import 'package:soctech_frontend/utils/invoice_generator.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  // Datos
  List<dynamic> projects = [];
  bool isLoading = true;
  bool isSaving = false;

  // Formulario
  final _clientNameCtrl = TextEditingController();
  final _cuitCtrl = TextEditingController();
  final _conceptCtrl = TextEditingController(text: "Certificado de Obra N° 1");
  final _netAmountCtrl = TextEditingController();
  
  // Configuración
  String? selectedProjectId;
  double vatPercentage = 21.0;
  double retainagePercentage = 5.0; // Típico 5% en construcción

  // Resultados Calculados (Preview)
  double calcVat = 0;
  double calcTotal = 0;
  double calcRetainage = 0;
  double calcCollectible = 0;

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      // IP Segura para Windows/Android
      final res = await http.get(Uri.parse('http://127.0.0.1:5064/api/Projects'));
      if (res.statusCode == 200) {
        setState(() {
          projects = json.decode(res.body).where((p) => p['isActive'] == true).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // --- EL CEREBRO FINANCIERO ---
  void calculate() {
    double net = double.tryParse(_netAmountCtrl.text) ?? 0;
    
    setState(() {
      calcVat = net * (vatPercentage / 100);
      calcTotal = net + calcVat;
      // Fondo de reparo sobre el neto (Estándar de industria)
      calcRetainage = net * (retainagePercentage / 100);
      calcCollectible = calcTotal - calcRetainage;
    });
  }

  Future<void> emitInvoice() async {
    if (selectedProjectId == null || _netAmountCtrl.text.isEmpty || _clientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete los campos obligatorios")));
      return;
    }
    
    setState(() => isSaving = true);

    // Creamos el mapa de datos que sirve tanto para el Backend como para el PDF
    final invoiceData = {
      "clientName": _clientNameCtrl.text,
      "clientCuit": _cuitCtrl.text,
      "projectId": selectedProjectId,
      "concept": _conceptCtrl.text,
      "netAmount": double.parse(_netAmountCtrl.text),
      "vatPercentage": vatPercentage,
      "retainagePercentage": retainagePercentage,
      // Los calculados para el PDF local (aunque el backend recalcula, los mandamos al PDF directo)
      "vatAmount": calcVat,
      "grossTotal": calcTotal,
      "retainageAmount": calcRetainage,
      "collectibleAmount": calcCollectible
    };

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5064/api/SalesInvoices'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(invoiceData)
      );

      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Factura Emitida y Registrada"), backgroundColor: Colors.green));
          
          // --- AQUÍ OCURRE LA MAGIA DEL PDF ---
          await InvoiceGenerator.generate(invoiceData);
          
          Navigator.pop(context); // Volver al dashboard
        }
      } else {
        throw Exception("Error del servidor: ${res.statusCode}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Factura de Venta"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CLIENTE Y OBRA
                const Text("DESTINATARIO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Obra / Proyecto", border: OutlineInputBorder()),
                  items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                  onChanged: (v) => setState(() => selectedProjectId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _clientNameCtrl, decoration: const InputDecoration(labelText: "Razón Social Cliente", border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _cuitCtrl, decoration: const InputDecoration(labelText: "CUIT", border: OutlineInputBorder()))),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // 2. DETALLES ECONÓMICOS
                const Text("DETALLES ECONÓMICOS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _conceptCtrl, 
                  decoration: const InputDecoration(labelText: "Concepto (Ej: Avance 20%)", border: OutlineInputBorder())
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _netAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Neto Gravado (\$)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                        onChanged: (_) => calculate(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        decoration: const InputDecoration(labelText: "IVA", border: OutlineInputBorder()),
                        value: vatPercentage,
                        items: const [
                          DropdownMenuItem(value: 21.0, child: Text("21%")),
                          DropdownMenuItem(value: 10.5, child: Text("10.5%")),
                          DropdownMenuItem(value: 0.0, child: Text("0%")),
                        ],
                        onChanged: (v) {
                          setState(() => vatPercentage = v!);
                          calculate();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. LA DIFERENCIACIÓN "PRO": FONDO DE REPARO
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Fondo de Reparo (Garantía)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          DropdownButton<double>(
                            value: retainagePercentage,
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text("0% (Sin Fondo)")),
                              DropdownMenuItem(value: 5.0, child: Text("5%")),
                              DropdownMenuItem(value: 10.0, child: Text("10%")),
                            ], 
                            onChanged: (v) {
                              setState(() => retainagePercentage = v!);
                              calculate();
                            }
                          )
                        ],
                      ),
                      const Text("Este monto se descontará del cobro inmediato pero quedará como deuda a favor.", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. PREVIEW DE RESULTADOS (FACTURA SIMULADA)
                Card(
                  elevation: 4,
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        _resultRow("Neto", calcVat, bold: false),
                        _resultRow("IVA ($vatPercentage%)", calcVat, bold: false),
                        const Divider(),
                        _resultRow("TOTAL FACTURA", calcTotal, bold: true, size: 16),
                        const SizedBox(height: 10),
                        _resultRow("(-) Fondo de Reparo", calcRetainage, color: Colors.red),
                        const Divider(thickness: 2),
                        _resultRow("A COBRAR (Neto Cash)", calcCollectible, bold: true, size: 20, color: Colors.green),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: isSaving ? null : emitInvoice,
                    icon: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.print),
                    label: const Text("EMITIR FACTURA Y PDF"),
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _resultRow(String label, double amount, {bool bold = false, double size = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: size, color: color)),
          Text(currencyFormat.format(amount), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: size, color: color)),
        ],
      ),
    );
  }
}