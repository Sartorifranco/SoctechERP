import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InvoiceEntryScreen extends StatefulWidget {
  const InvoiceEntryScreen({super.key});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  // Datos Maestros
  List<dynamic> providers = [];
  List<dynamic> purchaseOrders = [];
  List<dynamic> projects = []; // Para imputar costos
  
  bool isLoading = true;
  bool isSaving = false;

  // Selecciones
  String? selectedProviderId;
  String? selectedOrderId; // La clave del 3-Way Match
  String? selectedProjectId;

  // Controladores
  final _invoiceNumCtrl = TextEditingController();
  final _netAmountCtrl = TextEditingController(text: "0.00");
  final _vatAmountCtrl = TextEditingController(text: "0.00");
  final _taxesAmountCtrl = TextEditingController(text: "0.00");
  
  // Variables calculadas
  double totalCalculated = 0;
  DateTime selectedDate = DateTime.now();
  DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    loadMasterData();
    
    // Listeners para recalcular total en tiempo real
    _netAmountCtrl.addListener(_calculateTotal);
    _vatAmountCtrl.addListener(_calculateTotal);
    _taxesAmountCtrl.addListener(_calculateTotal);
  }

  Future<void> loadMasterData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('http://localhost:5064/api/Providers')),       // [0]
        http.get(Uri.parse('http://localhost:5064/api/PurchaseOrders')),  // [1]
        http.get(Uri.parse('http://localhost:5064/api/Projects')),        // [2]
      ]);

      if (responses[0].statusCode == 200) {
        setState(() {
          providers = json.decode(responses[0].body);
          purchaseOrders = json.decode(responses[1].body);
          
          // Filtramos solo obras activas
          projects = json.decode(responses[2].body)
              .where((p) => p['isActive'] == true)
              .toList();
              
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      setState(() => isLoading = false);
    }
  }

  // --- LÓGICA INTELLIGENT MATCH ---
  // Al elegir una Orden de Compra, autocompletamos los valores
  void onOrderSelected(String? orderId) {
    setState(() {
      selectedOrderId = orderId;
    });

    if (orderId != null) {
      final order = purchaseOrders.firstWhere((o) => o['id'] == orderId);
      
      // La "Magia" de Oracle: Traemos los datos para evitar tipear
      double totalOrden = (order['totalAmount'] ?? 0).toDouble();
      
      // Estimación simple de IVA (Generalmente 21% en construcción)
      double netoEstimado = totalOrden / 1.21;
      double ivaEstimado = totalOrden - netoEstimado;

      _netAmountCtrl.text = netoEstimado.toStringAsFixed(2);
      _vatAmountCtrl.text = ivaEstimado.toStringAsFixed(2);
      _taxesAmountCtrl.text = "0.00";
      
      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Datos importados de la Orden #${order['orderNumber']}"),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(milliseconds: 1500),
        )
      );
    }
  }

  void _calculateTotal() {
    double net = double.tryParse(_netAmountCtrl.text) ?? 0;
    double vat = double.tryParse(_vatAmountCtrl.text) ?? 0;
    double tax = double.tryParse(_taxesAmountCtrl.text) ?? 0;
    
    setState(() {
      totalCalculated = net + vat + tax;
    });
  }

  Future<void> saveInvoice() async {
    if (selectedProviderId == null || _invoiceNumCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos obligatorios (Proveedor o Nro Factura)")));
      return;
    }

    setState(() => isSaving = true);

    final invoiceData = {
      "invoiceNumber": _invoiceNumCtrl.text,
      "invoiceDate": selectedDate.toIso8601String(),
      "dueDate": selectedDueDate.toIso8601String(),
      "providerId": selectedProviderId,
      "providerName": providers.firstWhere((p) => p['id'] == selectedProviderId)['name'],
      "relatedPurchaseOrderId": selectedOrderId, // El vínculo clave
      "projectId": selectedProjectId, // Imputación de costo
      "netAmount": double.parse(_netAmountCtrl.text),
      "vatAmount": double.parse(_vatAmountCtrl.text),
      "otherTaxes": double.parse(_taxesAmountCtrl.text),
      "totalAmount": totalCalculated,
      "status": "Draft" // Nace como borrador para revisión
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/SupplierInvoices'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(invoiceData),
      );

      if (response.statusCode == 201) {
        // Éxito: Volvemos atrás o limpiamos
        if (mounted) {
           final created = json.decode(response.body);
           String statusMsg = created['status'] == "Flagged" 
              ? "Guardada, pero con diferencias de precio (Observada)" 
              : "Factura procesada y validada correctamente";
           
           Color color = created['status'] == "Flagged" ? Colors.orange : Colors.green;

           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(statusMsg), backgroundColor: color));
           Navigator.pop(context);
        }
      } else {
        throw Exception("Error ${response.body}");
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Helper para filtrar OCs por proveedor
  List<dynamic> getProviderOrders() {
    if (selectedProviderId == null) return [];
    return purchaseOrders.where((o) => o['providerId'] == selectedProviderId && o['status'] != 'Finished').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carga de Comprobantes"),
        backgroundColor: Colors.indigo.shade900, // Color "Corporate"
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                // --- SECCIÓN 1: ENCABEZADO (PROVEEDOR & MATCH) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.indigo.shade50,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Seleccionar Proveedor",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                          filled: true,
                          fillColor: Colors.white
                        ),
                        value: selectedProviderId,
                        items: providers.map<DropdownMenuItem<String>>((p) {
                          return DropdownMenuItem(value: p['id'], child: Text(p['name']));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedProviderId = val;
                            selectedOrderId = null; // Reset orden
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      // SELECTOR INTELIGENTE DE ORDEN DE COMPRA
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Vincular Orden de Compra (3-Way Match)",
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.receipt_long),
                                filled: true,
                                fillColor: Colors.white,
                                helperText: selectedProviderId == null ? "Seleccione proveedor primero" : null
                              ),
                              value: selectedOrderId,
                              // Solo mostramos las OCs del proveedor seleccionado
                              items: getProviderOrders().map<DropdownMenuItem<String>>((o) {
                                return DropdownMenuItem(value: o['id'], child: Text("OC #${o['orderNumber']} - ${currencyFormat.format(o['totalAmount'])}"));
                              }).toList(),
                              onChanged: onOrderSelected, // <--- AQUÍ OCURRE LA MAGIA
                              disabledHint: const Text("Sin Órdenes Pendientes"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- SECCIÓN 2: DATOS DEL COMPROBANTE ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Datos Fiscales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invoiceNumCtrl,
                              decoration: const InputDecoration(labelText: "Nro. Factura (Ej: 0001-1234)", border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Imputación (Obra)", border: OutlineInputBorder()),
                              value: selectedProjectId,
                              items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                              onChanged: (v) => selectedProjectId = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                             child: _datePickerField("Fecha Emisión", selectedDate, (d) => setState(() => selectedDate = d)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                             child: _datePickerField("Vencimiento Pago", selectedDueDate, (d) => setState(() => selectedDueDate = d)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- SECCIÓN 3: IMPORTES (CON DISEÑO DE TARJETA) ---
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            children: [
                              _moneyInput("Neto Gravado", _netAmountCtrl),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _moneyInput("IVA Total", _vatAmountCtrl)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _moneyInput("Perc. / Otros", _taxesAmountCtrl)),
                                ],
                              ),
                              const Divider(height: 30, thickness: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("TOTAL A PAGAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    currencyFormat.format(totalCalculated),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: isSaving ? null : saveInvoice,
                          icon: const Icon(Icons.check_circle),
                          label: const Text("PROCESAR FACTURA", style: TextStyle(fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Widgets Auxiliares para limpiar código
  Widget _datePickerField(String label, DateTime current, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onSelect(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
        child: Text(DateFormat('dd/MM/yyyy').format(current)),
      ),
    );
  }

  Widget _moneyInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: "\$ ",
        border: const OutlineInputBorder(),
        isDense: true
      ),
    );
  }
}