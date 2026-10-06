import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../data/daos/auth_dao.dart';
import '../../data/network/api_client.dart';

/// Controlador principal de la vista Home que extiende ChangeNotifier para 
/// gestionar el estado reactivo de la pantalla de productos y conectividad.
class HomeController extends ChangeNotifier {
  /// Constructor que recibe el rol del usuario e inyecta opcionalmente el AuthDao.
  HomeController({required this.role, AuthDao? authDao})
    : _authDao = authDao ?? AuthDao();

  /// Rol del usuario autenticado actualmente en la sesión.
  final String role;
  
  /// Objeto de acceso a datos para operaciones de autenticación (ej. cierre de sesión).
  final AuthDao _authDao;
  
  /// Lista interna que almacena los productos obtenidos desde la API.
  List<Map<String, dynamic>> _products = [];
  
  /// Bandera que indica si el controlador se encuentra cargando datos.
  bool _isLoading = true;
  
  /// Bandera para verificar si el controlador ha sido eliminado (evita llamadas tras dispose).
  bool _disposed = false;
  
  /// Almacena el mensaje de error actual en caso de fallos de red o carga.
  String _errorMessage = '';
  
  /// Categoría seleccionada actualmente para filtrar los productos ('Todas' por defecto).
  String _selectedCategory = 'Todas';
  
  /// Suscripción para escuchar los cambios de conectividad a internet en tiempo real.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Getter público para consultar si está cargando.
  bool get isLoading => _isLoading;
  
  /// Getter público para obtener el mensaje de error actual.
  String get errorMessage => _errorMessage;
  
  /// Getter público para consultar la categoría seleccionada.
  String get selectedCategory => _selectedCategory;

  /// Obtiene una lista única y ordenada de todas las categorías disponibles en los productos.
  List<String> get categories {
    final categories =
        _products
            .map((product) => product['category'] as String?)
            .whereType<String>()
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Todas', ...categories];
  }

  /// Retorna la lista de productos filtrada según la categoría seleccionada.
  List<Map<String, dynamic>> get visibleProducts {
    if (_selectedCategory == 'Todas') return _products;
    return _products
        .where((product) => product['category'] == _selectedCategory)
        .toList();
  }

  /// Inicializa la escucha de la red y dispara la carga inicial del catálogo.
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    loadCatalog();
  }

  /// Maneja los eventos de cambio de conectividad del dispositivo.
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (_disposed) return;
    final isConnected = !results.contains(ConnectivityResult.none);
    if (!isConnected) {
      _isLoading = false;
      _errorMessage = 'Sin conexión a internet';
      notifyListeners();
    } else if (_errorMessage.isNotEmpty) {
      loadCatalog();
    }
  }

  /// Realiza la petición HTTP para obtener el catálogo de productos desde la API.
  Future<void> loadCatalog() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final isConnected = await ApiClient.hasInternetConnection();
      if (_disposed) return;
      if (!isConnected) {
        _showOfflineMessage();
        return;
      }

      final response = await ApiClient.get('/products');
      if (_disposed) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          _products = decoded.whereType<Map<String, dynamic>>().toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _showOfflineMessage();
    } catch (_) {
      if (_disposed) return;
      _showOfflineMessage();
    }
  }

  /// Verifica si hay conexión a internet activa antes de realizar una acción.
  Future<bool> ensureConnection() async {
    final isConnected = await ApiClient.hasInternetConnection();
    if (_disposed) return false;
    if (isConnected) return true;
    _showOfflineMessage();
    return false;
  }

  /// Cambia la categoría seleccionada si hay conexión disponible y notifica a la vista.
  Future<void> selectCategory(String category) async {
    if (!await ensureConnection()) return;
    if (_disposed) return;
    _selectedCategory = category;
    notifyListeners();
  }

  /// Cierra la sesión del usuario actual delegando en el AuthDao.
  Future<void> logout() => _authDao.logout();

  /// Actualiza el estado para reflejar que no hay conexión y notifica a los escuchas.
  void _showOfflineMessage() {
    if (_disposed) return;
    _isLoading = false;
    _errorMessage = 'Sin conexión a internet';
    notifyListeners();
  }

  /// Libera los recursos del controlador y cancela la suscripción de red al destruir el widget.
  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}