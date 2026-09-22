// Importa los componentes visuales de Flutter.
import 'package:flutter/material.dart';

// Importa la clase encargada de gestionar la autenticación.
import '../../data/daos/auth_dao.dart';

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
  State<CheckSessionScreen> createState() =>
      _CheckSessionScreenState();
}

/// Estado de la pantalla de comprobación de sesión.
class _CheckSessionScreenState
    extends State<CheckSessionScreen> {
  // Crea una instancia para consultar la sesión almacenada.
  final AuthDao _authDao = AuthDao();

  /// Se ejecuta cuando la pantalla se crea por primera vez.
  @override
  void initState() {
    // Ejecuta la implementación original de initState.
    super.initState();

    // Comprueba si existe una sesión activa.
    _checkLoginState();
  }

  /// Comprueba los datos de sesión guardados localmente.
  Future<void> _checkLoginState() async {
    // Obtiene el token y el rol almacenados.
    final session = await _authDao.getActiveSession();

    // Recupera el token de la sesión.
    final token = session['token'];

    // Recupera el rol del usuario.
    final role = session['role'];

    // Detiene la ejecución si la pantalla ya no está activa.
    if (!mounted) return;

    // Comprueba si existen un token y un rol válidos.
    if (token != null && role != null) {
      // Dirige al usuario autenticado a la pantalla principal.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(role: role),
        ),
      );
    } else {
      // Dirige al usuario no autenticado al inicio de sesión.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  /// Construye la interfaz visual de la pantalla.
  @override
  Widget build(BuildContext context) {
    // Muestra un indicador mientras se comprueba la sesión.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}