import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import 'home_screen.dart';

/// Pantalla de inicio de sesión.
class LoginScreen extends StatefulWidget {
  /// Constructor de la pantalla.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Estado de la pantalla de inicio de sesión.
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoginController _controller = LoginController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final role = await _controller.login();

    if (!mounted) return;

    if (role != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(role: role)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        // Barra superior.
        appBar: AppBar(title: const Text('Iniciar sesión')),

        // Contenido principal.
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de la aplicación.
                const Icon(Icons.store, size: 80, color: Colors.blue),

                const SizedBox(height: 24),

                // Campo del nombre de usuario.
                TextFormField(
                  controller: _controller.usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu usuario';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo de la contraseña.
                TextFormField(
                  controller: _controller.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Muestra el error si existe.
                if (_controller.errorMessage.isNotEmpty)
                  Text(
                    _controller.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 16),

                // Muestra carga o el botón de inicio de sesión.
                _controller.isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text('Iniciar sesión'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
