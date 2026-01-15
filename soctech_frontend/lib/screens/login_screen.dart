import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Importamos main.dart para poder navegar al "MainLayout" (tu menú principal)
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
      // IP Segura para Windows/Android
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
        final token = data['token']; // El backend puede devolver 'Token' o 'token', ajustamos si falla

        // Guardar sesión en el celular
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('username', _userCtrl.text);

        if (mounted) {
          // Navegar a la App Principal (MainLayout) y borrar historial para no volver al login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario o contraseña incorrectos"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
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
                    const Icon(Icons.security, size: 60, color: Colors.indigo),
                    const SizedBox(height: 10),
                    const Text("SOCTECH ERP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Text("Acceso Seguro", style: TextStyle(color: Colors.grey)),
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
                          : const Text("INGRESAR AL SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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