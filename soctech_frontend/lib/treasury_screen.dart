import 'dart:convert';
import 'dart:ui'; // Necesario para el ScrollBehavior
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({super.key});

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  // Datos
  List<dynamic> wallets = [];
  Map<String, List<dynamic>> groupedTransactions = {};
  
  bool isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  final PageController _cardController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final resWallets = await http.get(Uri.parse('http://localhost:5064/api/Treasury/wallets'));
      final resTrx = await http.get(Uri.parse('http://localhost:5064/api/Treasury/transactions'));

      if (resWallets.statusCode == 200) {
        final List<dynamic> rawTrx = json.decode(resTrx.body);
        setState(() {
          wallets = json.decode(resWallets.body);
          groupedTransactions = _groupTransactionsByDate(rawTrx);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LÓGICA DE AGRUPAMIENTO ---
  Map<String, List<dynamic>> _groupTransactionsByDate(List<dynamic> list) {
    Map<String, List<dynamic>> groups = {};
    for (var t in list) {
      final date = DateTime.parse(t['date']).toLocal();
      final now = DateTime.now();
      String key;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = "Hoy";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        key = "Ayer";
      } else {
        key = DateFormat('dd/MM/yyyy').format(date);
      }

      if (!groups.containsKey(key)) groups[key] = [];
      groups[key]!.add(t);
    }
    return groups;
  }

  // --- DIALOGO DE TRANSACCIÓN ---
  void showTransactionDialog({required bool isIncome}) {
    String? selectedWalletId;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    if (wallets.isNotEmpty) selectedWalletId = wallets[0]['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isIncome ? "Registrar Ingreso" : "Registrar Gasto", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.redAccent)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
            const Divider(),
            const SizedBox(height: 20),
            
            const Text("Seleccionar Cuenta", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50
              ),
              value: selectedWalletId,
              items: wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: w['id'], child: Text(w['name']))).toList(),
              onChanged: (v) => selectedWalletId = v,
            ),
            
            const SizedBox(height: 20),
            
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
              decoration: const InputDecoration(
                hintText: "\$ 0",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey)
              ),
            ),
            Center(child: Text("Ingrese el monto", style: TextStyle(color: Colors.grey.shade400))),

            const SizedBox(height: 30),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: "Concepto / Descripción",
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),

            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIncome ? Colors.green : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5
                ),
                onPressed: () async {
                  if(selectedWalletId == null || amountCtrl.text.isEmpty) return;
                  
                  final trx = {
                    "walletId": selectedWalletId,
                    "type": isIncome ? "INCOME" : "EXPENSE",
                    "amount": double.parse(amountCtrl.text),
                    "description": descCtrl.text
                  };

                  final res = await http.post(
                    Uri.parse('http://localhost:5064/api/Treasury/transactions'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(trx)
                  );

                  if(res.statusCode == 200) {
                    Navigator.pop(ctx);
                    fetchData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Movimiento registrado"), backgroundColor: Colors.black87));
                  }
                }, 
                child: const Text("CONFIRMAR OPERACIÓN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      )
    );
  }

  void showAddWalletDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nueva Billetera"),
        content: TextField(
          controller: nameCtrl, 
          decoration: InputDecoration(
            labelText: "Nombre (Ej: Banco Galicia)", 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
          )
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await http.post(
                Uri.parse('http://localhost:5064/api/Treasury/wallets'),
                headers: {"Content-Type": "application/json"},
                body: json.encode({"name": nameCtrl.text, "type": "CASH", "balance": 0})
              );
              Navigator.pop(ctx);
              fetchData();
            }, 
            child: const Text("Crear")
          )
        ],
      )
    );
  }

  // --- FUNCIONES DE NAVEGACIÓN DEL CARRUSEL ---
  void _prevCard() {
    _cardController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _nextCard() {
    _cardController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    double totalFunds = wallets.fold(0, (sum, w) => sum + (w['balance'] ?? 0));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.indigo.shade900,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.indigo.shade900, Colors.blue.shade900],
                      )
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 80), 
                        Text("Balance Total Consolidado", style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        Text(currencyFormat.format(totalFunds), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        
                        // --- CARRUSEL CON BOTONES LATERALES ---
                        SizedBox(
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. EL CARRUSEL
                              PageView.builder(
                                controller: _cardController,
                                // ESTA LÍNEA HABILITA ARRASTRAR CON EL MOUSE EN WINDOWS:
                                scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus}),
                                itemCount: wallets.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == wallets.length) return _buildAddCard();
                                  return _buildCreditCard(wallets[index], index);
                                },
                              ),

                              // 2. BOTÓN IZQUIERDA (ANTERIOR)
                              Positioned(
                                left: 10,
                                child: IconButton(
                                  onPressed: _prevCard,
                                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black26, 
                                    hoverColor: Colors.black45
                                  ),
                                ),
                              ),

                              // 3. BOTÓN DERECHA (SIGUIENTE)
                              Positioned(
                                right: 10,
                                child: IconButton(
                                  onPressed: _nextCard,
                                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black26,
                                    hoverColor: Colors.black45
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                title: const Text("Tesorería"),
                centerTitle: true,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(Icons.arrow_downward, "Ingresar", Colors.green, () => showTransactionDialog(isIncome: true)),
                      _buildQuickAction(Icons.arrow_upward, "Gastar", Colors.redAccent, () => showTransactionDialog(isIncome: false)),
                      _buildQuickAction(Icons.swap_horiz, "Transferir", Colors.blue, () {}), 
                      _buildQuickAction(Icons.qr_code, "QR", Colors.black, () {}), 
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Movimientos Recientes", style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),

              if (groupedTransactions.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
                        const Text("No hay movimientos aún"),
                      ],
                    ),
                  )),
                ),

              ...groupedTransactions.entries.map((entry) {
                return SliverStickyHeader( 
                  title: entry.key,
                  items: entry.value
                );
              }).toList(),
              
              const SliverToBoxAdapter(child: SizedBox(height: 80)), 
            ],
          ),
    );
  }

  Widget _buildCreditCard(dynamic wallet, int index) {
    final List<List<Color>> gradients = [
      [Colors.indigo.shade500, Colors.purple.shade500],
      [Colors.teal.shade400, Colors.green.shade600],
      [Colors.orange.shade400, Colors.deepOrange.shade600],
      [Colors.blueGrey.shade700, Colors.black87],
    ];
    final gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(wallet['type'] == 'BANK' ? "Banco" : "Caja Efectivo", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              const Icon(Icons.nfc, color: Colors.white54),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(wallet['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
               const SizedBox(height: 5),
               Text(currencyFormat.format(wallet['balance']), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: showAddWalletDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30, width: 2, style: BorderStyle.solid)
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 40),
              SizedBox(height: 10),
              Text("Nueva Cuenta", style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2))]
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12))
        ],
      ),
    );
  }
}

class SliverStickyHeader extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  SliverStickyHeader({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.grey.shade100,
              child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            );
          }
          final t = items[index - 1];
          bool isIncome = t['type'] == "INCOME";
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15)
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined, 
                  color: isIncome ? Colors.green : Colors.redAccent
                ),
              ),
              title: Text(t['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t['walletName'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              trailing: Text(
                "${isIncome ? '+' : '-'}${currencyFormat.format(t['amount'])}",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: isIncome ? Colors.green : Colors.black87
                ),
              ),
            ),
          );
        },
        childCount: items.length + 1, 
      ),
    );
  }
}