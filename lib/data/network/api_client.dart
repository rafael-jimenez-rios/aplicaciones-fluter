import 'dart:convert';

// Permite comprobar el tipo de conexión disponible en el dispositivo.
import 'package:connectivity_plus/connectivity_plus.dart';

// Permite realizar peticiones HTTP a servicios web.
import 'package:http/http.dart' as http;

/// Cliente encargado de comunicarse con la API externa.
class ApiClient {
  /// URL principal de la API.
  ///
  /// Los endpoints se añadirán a esta dirección.
  static const String baseUrl = 'https://fakestoreapi.com';

  /// Comprueba si el dispositivo tiene algún tipo de conexión.
  ///
  /// Devuelve `true` si existe conexión Wi-Fi, móvil u otra.
  /// Devuelve `false` si no existe ninguna conexión.
  ///
  /// Nota: esto no garantiza que Internet esté disponible,
  /// solo comprueba el estado de conectividad del dispositivo.
  static Future<bool> hasInternetConnection() async {
    // Obtiene los tipos de conexión disponibles.
    final connectivityResult = await Connectivity().checkConnectivity();

    // Devuelve false únicamente cuando no hay conexión.
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Realiza una petición HTTP de tipo GET.
  ///
  /// [endpoint] representa la ruta de la API, por ejemplo `/users`.
  ///
  /// Devuelve la respuesta HTTP del servidor.
  static Future<http.Response> get(String endpoint) async {
    // Combina la URL base con el endpoint recibido.
    final url = Uri.parse('$baseUrl$endpoint');

    // Envía la petición GET y espera la respuesta.
    return await http.get(url);
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    return http.delete(Uri.parse('$baseUrl$endpoint'));
  }
}
