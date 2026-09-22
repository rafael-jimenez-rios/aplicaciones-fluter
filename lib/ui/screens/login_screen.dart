import 'package:flutter/material.dart';

import '../../data/daos/auth_dao.dart';
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
  // Permite validar los campos del formulario.
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos de texto.
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  // Gestiona la autenticación del usuario.
  final AuthDao _authDao = AuthDao();

  // Indica si se está procesando el inicio de sesión.
  bool _isLoading = false;

  // Guarda el mensaje de error.
  String _errorMessage = '';

  /// Libera los controladores al cerrar la pantalla.
  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// Valida los datos e intenta iniciar sesión.
  Future<void> _handleLogin() async {
    // Comprueba que los campos sean válidos.
    if (!_formKey.currentState!.validate()) return;

    // Activa la carga y limpia errores anteriores.
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Envía las credenciales al DAO.
    final result = await _authDao.login(
      _userController.text.trim(),
      _passController.text.trim(),
    );

    // Comprueba que la pantalla siga activa.
    if (!mounted) return;

    // Desactiva la carga.
    setState(() {
      _isLoading = false;
    });

    // Comprueba si la autenticación fue correcta.
    if (result['success'] == true) {
      // Obtiene el rol devuelto por la autenticación.
      final role = result['role'] as String;

      // Abre la pantalla principal y elimina el historial anterior.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(role: role),
        ),
        (route) => false,
      );
    } else {
      // Muestra el mensaje de error.
      setState(() {
        _errorMessage =
            result['message'] ?? 'Error al iniciar sesión';
      });
    }
  }

  /// Construye la interfaz de inicio de sesión.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior.
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),

      // Contenido principal.
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de la aplicación.
              const Icon(
                Icons.store,
                size: 80,
                color: Colors.blue,
              ),

              const SizedBox(height: 24),

              // Campo del nombre de usuario.
              TextFormField(
                controller: _userController,
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
                controller: _passController,
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
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 16),

              // Muestra carga o el botón de inicio de sesión.
              _isLoading
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
    );
  }
}