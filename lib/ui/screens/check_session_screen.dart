// Importa los componentes visuales de Flutter.
import 'package:flutter/material.dart';

// Importa la clase encargada de gestionar la autenticación.
import '../controllers/check_session_controller.dart';

// Importa la pantalla principal de la aplicación.
import 'home_screen.dart';

// Importa la pantalla de inicio de sesión.
import 'login_screen.dart';

/// Pantalla que comprueba si existe una sesión activa.
class CheckSessionScreen extends StatefulWidget {
  /// Constructor de la pantalla.
  const CheckSessionScreen({super.key});

  /// Crea el estado asociado a esta pantalla.
  @override
  State<CheckSessionScreen> createState() => _CheckSessionScreenState();
}

/// Estado de la pantalla de comprobación de sesión.
class _CheckSessionScreenState extends State<CheckSessionScreen> {
  // Crea una instancia para consultar la sesión almacenada.
  final CheckSessionController _controller = CheckSessionController();

  /// Se ejecuta cuando la pantalla se crea por primera vez.
  @override
  void initState() {
    // Ejecuta la implementación original de initState.
    super.initState();

    // Comprueba si existe una sesión activa.
    _openActiveSession();
  }

  /// Comprueba los datos de sesión guardados localmente.
  Future<void> _openActiveSession() async {
    final role = await _controller.getActiveRole();
    if (!mounted) return;

    if (role != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(role: role)),
      );
    } else {
      // Dirige al usuario no autenticado al inicio de sesión.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  /// Construye la interfaz visual de la pantalla.
  @override
  Widget build(BuildContext context) {
    // Muestra un indicador mientras se comprueba la sesión.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
