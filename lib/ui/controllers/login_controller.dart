import 'package:flutter/material.dart';

import '../../data/daos/auth_dao.dart';

/// Controlador encargado de gestionar la lógica de autenticación y el estado 
/// de la pantalla de inicio de sesión, extendiendo de ChangeNotifier para la reactividad.
class LoginController extends ChangeNotifier {
  /// Constructor que permite inyectar opcionalmente un AuthDao para facilitar pruebas unitarias.
  LoginController({AuthDao? authDao}) : _authDao = authDao ?? AuthDao();

  /// Objeto de acceso a datos para comunicarse con el servicio de autenticación.
  final AuthDao _authDao;
  
  /// Controlador para gestionar el campo de texto del nombre de usuario u correo.
  final usernameController = TextEditingController();
  
  /// Controlador para gestionar el campo de texto de la contraseña del usuario.
  final passwordController = TextEditingController();

  /// Bandera para indicar si el proceso de inicio de sesión está en curso.
  bool _isLoading = false;
  
  /// Bandera para verificar si el controlador ha sido destruido y evitar operaciones asíncronas.
  bool _disposed = false;
  
  /// Almacena el mensaje de error actual en caso de que falle la autenticación.
  String _errorMessage = '';

  /// Getter público para consultar el estado de carga actual.
  bool get isLoading => _isLoading;
  
  /// Getter público para obtener el mensaje de error actual.
  String get errorMessage => _errorMessage;

  /// Realiza la petición de inicio de sesión utilizando las credenciales de los controladores de texto.
  Future<String?> login() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authDao.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );
      if (_disposed) return null;

      // Si el inicio de sesión es exitoso, retorna el rol del usuario obtenido.
      if (result['success'] == true) {
        return result['role'] as String?;
      }

      // Si falla, extrae el mensaje de error del resultado o asigna uno por defecto.
      _errorMessage = result['message'] as String? ?? 'Error al iniciar sesión';
      return null;
    } catch (_) {
      if (_disposed) return null;
      _errorMessage = 'Error al iniciar sesión';
      return null;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Libera los controladores de texto y recursos del sistema al destruir el widget.
  @override
  void dispose() {
    _disposed = true;
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}