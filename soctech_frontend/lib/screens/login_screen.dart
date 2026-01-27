import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool isLoading = false;
  bool isObscure = true;

  Future<void> login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingrese usuario y contraseña")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // Ajusta la IP si es necesario (127.0.0.1 para Windows, 10.0.2.2 para Emulador Android)
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5064/api/Auth/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": _userCtrl.text,
          "password": _passCtrl.text
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final token = data['token'] ?? data['Token']; 
        final role = data['role'] ?? data['Role'];
        
        // --- AQUÍ ESTÁ LA MAGIA NUEVA ---
        // Recibimos la lista de permisos del backend
        final List<dynamic> rawPerms = data['permissions'] ?? data['Permissions'] ?? [];
        final List<String> permissions = rawPerms.map((e) => e.toString()).toList();

        // Guardamos todo en la memoria del dispositivo
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('username', _userCtrl.text);
        await prefs.setString('role', role);
        await prefs.setStringList('user_permissions', permissions); // <--- Guardamos la lista

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Credenciales inválidas"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade900, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(30),
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, size: 60, color: Colors.indigo), // Icono de seguridad
                    const SizedBox(height: 10),
                    const Text("SOCTECH ERP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Text("Enterprise Access", style: TextStyle(color: Colors.grey, letterSpacing: 1.5)),
                    const SizedBox(height: 30),
                    
                    TextField(
                      controller: _userCtrl,
                      decoration: InputDecoration(
                        labelText: "Usuario",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _passCtrl,
                      obscureText: isObscure,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => isObscure = !isObscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isLoading ? null : login,
                        child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("INGRESAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}