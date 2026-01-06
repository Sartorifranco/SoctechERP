import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  List<dynamic> orders = [];
  List<dynamic> providers = [];
  List<dynamic> products = [];
  bool isLoading = true;
  
  // Formato de moneda para Argentina
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  // URL Base (Asegurada al puerto 5064)
  final String baseUrl = 'http://localhost:5064/api';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final resOrd = await http.get(Uri.parse('$baseUrl/PurchaseOrders'));
      final resProv = await http.get(Uri.parse('$baseUrl/Providers'));
      final resProd = await http.get(Uri.parse('$baseUrl/Products'));

      if (resOrd.statusCode == 200) {
        setState(() {
          orders = json.decode(resOrd.body);
          // Validamos que providers y products no sean nulos
          providers = resProv.statusCode == 200 ? json.decode(resProv.body) : [];
          products = resProd.statusCode == 200 ? json.decode(resProd.body) : [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      setState(() => isLoading = false);
    }
  }

  // --- RECIBIR PEDIDO (MEJORADO) ---
  Future<void> receiveOrder(String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Confirmar Recepción?"),
        content: const Text("Esto ingresará automáticamente los productos al Stock del pañol."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("RECIBIR MERCADERÍA")
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        final response = await http.put(Uri.parse('$baseUrl/PurchaseOrders/$id/receive'));
        
        if (response.statusCode == 200) {
          await fetchData(); // Recargar lista
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Stock Actualizado Correctamente!"), backgroundColor: Colors.green)
            );
          }
        } else {
          // Si el backend dice "Ya fue recibida" u otro error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${response.body}"), backgroundColor: Colors.red)
            );
          }
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error de conexión: $e"), backgroundColor: Colors.red)
            );
         }
      }
    }
  }

  // --- NUEVA ORDEN DE COMPRA (MANTENEMOS TU LÓGICA) ---
  void showCreateOrderDialog() {
    String? selectedProvider;
    List<Map<String, dynamic>> cartItems = [];
    
    String? tempProduct;
    TextEditingController qtyCtrl = TextEditingController();
    TextEditingController priceCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            double calculateTotal() {
              return cartItems.fold(0, (sum, item) => sum + (item['quantity'] * item['unitPrice']));
            }

            return AlertDialog(
              title: const Text("Nueva Orden de Compra"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. ELEGIR PROVEEDOR
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Proveedor", icon: Icon(Icons.local_shipping)),
                      items: providers.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                      onChanged: (v) => setDialogState(() => selectedProvider = v),
                    ),
                    const Divider(),
                    
                    // 2. AGREGAR PRODUCTOS
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "Producto", isDense: true),
                            items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                            onChanged: (v) => tempProduct = v,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cant.", isDense: true))),
                        const SizedBox(width: 5),
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "\$", isDense: true))),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () {
                            if (tempProduct != null && qtyCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                              // Buscar nombre producto de forma segura
                              final prodObj = products.firstWhere((p) => p['id'] == tempProduct, orElse: () => {'name': 'Unknown'});
                              
                              setDialogState(() {
                                cartItems.add({
                                  "productId": tempProduct,
                                  "productName": prodObj['name'],
                                  "quantity": double.tryParse(qtyCtrl.text) ?? 1,
                                  "unitPrice": double.tryParse(priceCtrl.text) ?? 0
                                });
                                // Limpiar inputs
                                qtyCtrl.clear();
                                priceCtrl.clear();
                              });
                            }
                          },
                        )
                      ],
                    ),

                    // 3. LISTA DE ITEMS (CARRITO)
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (ctx, i) {
                          final item = cartItems[i];
                          return ListTile(
                            dense: true,
                            title: Text(item['productName']),
                            subtitle: Text("${item['quantity']} x \$${item['unitPrice']}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                              onPressed: () => setDialogState(() => cartItems.removeAt(i)),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text("Total Orden: ${currencyFormat.format(calculateTotal())}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedProvider == null || cartItems.isEmpty) return;
                    
                    // Armamos el objeto tal cual lo espera el Backend (PostOrder)
                    final newOrder = {
                      "providerId": selectedProvider,
                      "totalAmount": calculateTotal(),
                      "items": cartItems
                    };

                    try {
                      await http.post(
                        Uri.parse('$baseUrl/PurchaseOrders'),
                        headers: {"Content-Type": "application/json"}, 
                        body: json.encode(newOrder)
                      );
                      
                      if (context.mounted) Navigator.pop(context);
                      fetchData(); // Recargar la lista
                    } catch (e) {
                      print("Error creando orden: $e");
                    }
                  },
                  child: const Text("Emitir Orden"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Órdenes de Compra")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showCreateOrderDialog,
        label: const Text("Nueva Orden"),
        icon: const Icon(Icons.add_shopping_cart),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : orders.isEmpty 
          ? const Center(child: Text("No hay órdenes registradas"))
          : ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.only(bottom: 80), // Espacio para el botón flotante
            itemBuilder: (context, index) {
              final order = orders[index];
              
              // Buscamos nombre proveedor de forma segura
              final provObj = providers.firstWhere((p) => p['id'] == order['providerId'], orElse: () => {'name': 'Desconocido'});
              final provName = provObj['name'];
              
              final date = DateTime.tryParse(order['date']) ?? DateTime.now();
              final isReceived = order['status'] == "Received";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isReceived ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isReceived ? Colors.green[100] : Colors.orange[100],
                    child: Icon(isReceived ? Icons.check : Icons.hourglass_bottom, color: isReceived ? Colors.green : Colors.orange),
                  ),
                  title: Text("${order['orderNumber'] ?? '---'} - $provName"),
                  subtitle: Text("${DateFormat('dd/MM/yy').format(date)} - Total: ${currencyFormat.format(order['totalAmount'])}"),
                  children: [
                    // DETALLE DE ITEMS
                    if (order['items'] != null)
                      ...(order['items'] as List).map<Widget>((item) {
                        // Buscamos nombre del producto para mostrar (el backend manda ID y Nombre, pero por las dudas)
                        final pName = item['productName'] ?? products.firstWhere((p) => p['id'] == item['productId'], orElse: () => {'name': 'Producto'})['name'];
                        
                        return ListTile(
                          dense: true,
                          title: Text(pName),
                          trailing: Text("${item['quantity']} x ${currencyFormat.format(item['unitPrice'])}"),
                        );
                      }).toList(),
                    
                    // BOTÓN DE ACCIÓN (SOLO SI ESTÁ PENDIENTE)
                    if (!isReceived)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent, 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                            onPressed: () => receiveOrder(order['id']),
                            icon: const Icon(Icons.inventory_2),
                            label: const Text("RECIBIR MERCADERÍA (INGRESAR STOCK)"),
                          ),
                        ),
                      )
                  ],
                ),
              );
            },
          ),
    );
  }
}