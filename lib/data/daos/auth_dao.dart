// Permite convertir respuestas JSON en objetos Dart.
import 'dart:convert';

// Permite guardar datos localmente en el dispositivo.
import 'package:shared_preferences/shared_preferences.dart';

// Importa el cliente encargado de realizar peticiones a la API.
import '../network/api_client.dart';

/// DAO encargado de gestionar la autenticación del usuario.
///
/// DAO significa Data Access Object. Su función es acceder
/// y gestionar datos procedentes de la API o del almacenamiento local.
class AuthDao {
  /// Asigna un rol según el identificador del usuario.
  ///
  /// Usuarios con ID 1 o 2 reciben el rol de Administrador.
  /// El usuario con ID 3 recibe el rol de Auditor.
  /// Los demás usuarios reciben el rol de Cliente.
  String mapUserRole(int userId) {
    if (userId == 1 || userId == 2) {
      return 'Administrador';
    } else if (userId == 3) {
      return 'Auditor';
    } else {
      return 'Cliente';
    }
  }

  /// Intenta iniciar sesión utilizando los datos de la API.
  ///
  /// [username] es el nombre del usuario.
  /// [password] es la contraseña del usuario.
  ///
  /// Devuelve un mapa con:
  ///
  /// - `success: true` si el inicio de sesión fue correcto.
  /// - `success: false` si ocurrió algún error.
  /// - `message` con la descripción del error.
  /// - `role` con el rol del usuario autenticado.
  Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    // Comprueba si el dispositivo tiene conexión.
    final isConnected =
        await ApiClient.hasInternetConnection();

    // Si no hay conexión, se cancela el inicio de sesión.
    if (!isConnected) {
      return {
        'success': false,
        'message': 'Sin conexión a internet. Verifique su red.',
      };
    }

    try {
      // Solicita a la API la lista de usuarios.
      final response = await ApiClient.get('/users');

      // Comprueba que la API haya respondido correctamente.
      if (response.statusCode == 200) {
        // Convierte el texto JSON recibido en una lista de usuarios.
        final List users = json.decode(response.body);

        // Busca un usuario con el nombre y contraseña indicados.
        final matchedUser = users.firstWhere(
          (user) =>
              user['username'] == username &&
              user['password'] == password,
          orElse: () => null,
        );

        // Si no se encontró ningún usuario, las credenciales son inválidas.
        if (matchedUser == null) {
          return {
            'success': false,
            'message': 'Usuario o contraseña inválidos',
          };
        }

        // Obtiene el identificador del usuario encontrado.
        final userId = matchedUser['id'] as int;

        // Determina el rol correspondiente al usuario.
        final assignedRole = mapUserRole(userId);

        // Genera un token local utilizando la fecha actual.
        final token =
            'local-token-${DateTime.now().millisecondsSinceEpoch}';

        // Obtiene una instancia del almacenamiento local.
        final prefs =
            await SharedPreferences.getInstance();

        // Guarda el token de sesión.
        await prefs.setString('token', token);

        // Guarda el rol del usuario.
        await prefs.setString('role', assignedRole);

        // Guarda el identificador del usuario.
        await prefs.setInt('userId', userId);

        // Devuelve un resultado exitoso con el rol asignado.
        return {
          'success': true,
          'role': assignedRole,
        };
      } else {
        // Se ejecuta si la API devuelve un código diferente de 200.
        return {
          'success': false,
          'message':
              'No se pudo consultar la lista de usuarios',
        };
      }
    } catch (e) {
      // Captura errores de red, JSON u otros errores inesperados.
      return {
        'success': false,
        'message':
            'Sin conexión a internet o error de red.',
      };
    }
  }

  /// Comprueba si existe una sesión guardada localmente.
  ///
  /// Devuelve el token y el rol almacenados.
  /// Si no existe una sesión, sus valores serán `null`.
  Future<Map<String, String?>> getActiveSession() async {
    // Obtiene el almacenamiento local.
    final prefs =
        await SharedPreferences.getInstance();

    // Recupera el token guardado.
    final token = prefs.getString('token');

    // Recupera el rol guardado.
    final role = prefs.getString('role');

    // Devuelve los datos de la sesión.
    return {
      'token': token,
      'role': role,
    };
  }

  /// Recupera el rol almacenado localmente sin consultar la API.
  Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  /// Cierra la sesión del usuario.
  ///
  /// Elimina todos los datos almacenados localmente.
  Future<void> logout() async {
    // Obtiene el almacenamiento local.
    final prefs =
        await SharedPreferences.getInstance();

    // Elimina el token, el rol y cualquier otro dato guardado.
    await prefs.clear();
  }
}