import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "bot", "text": "Hola, soy Jarvis. ¿En qué puedo ayudarte con la gestión hoy?"}
  ];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    if (_ctrl.text.trim().isEmpty) return;

    final question = _ctrl.text;
    setState(() {
      _messages.add({"role": "user", "text": question});
      _isTyping = true;
      _ctrl.clear();
    });
    _scrollToBottom();

    try {
      // ---------------------------------------------------------
      // ✅ CORRECCIÓN: Apuntamos a 'api/Ai/chat'
      // ---------------------------------------------------------
      final res = await http.post(
        Uri.parse('http://localhost:5064/api/Ai/chat'), 
        headers: {"Content-Type": "application/json"},
        body: json.encode({"question": question}),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _messages.add({"role": "bot", "text": data['answer']});
            _isTyping = false;
          });
          _scrollToBottom();
        }
      } else {
        // Si el backend devuelve error, lo mostramos en consola
        print("Error Backend: ${res.statusCode} - ${res.body}");
        throw Exception("Error ${res.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "text": "No pude conectar con el cerebro. Revisa que el Backend esté corriendo (dotnet watch run). Error: $e"});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Altura: 80% de la pantalla
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.indigo.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Asistente IA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white), 
                  onPressed: () => Navigator.pop(context)
                )
              ],
            ),
          ),

          // Lista de Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(15),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                      ),
                    ),
                    child: Text(msg['text']!, style: const TextStyle(fontSize: 15)),
                  ),
                );
              },
            ),
          ),

          // Indicador "Escribiendo..."
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Jarvis está pensando...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),

          // Input de texto
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: "Pregúntale algo a tu ERP...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.indigo,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}