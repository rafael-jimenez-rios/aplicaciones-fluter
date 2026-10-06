import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../data/daos/auth_dao.dart';
import '../../data/network/api_client.dart';

/// Controlador encargado de gestionar la lógica de detalle de un producto, 
/// incluyendo su obtención, verificación de permisos de administrador y eliminación.
class ProductDetailController extends ChangeNotifier {
  /// Constructor que recibe el ID del producto y permite inyectar opcionalmente un AuthDao.
  ProductDetailController({required this.productId, AuthDao? authDao})
    : _authDao = authDao ?? AuthDao();

  /// Identificador único del producto que se va a consultar y gestionar.
  final int productId;
  
  /// Objeto de acceso a datos para validar las credenciales y el rol del usuario actual.
  final AuthDao _authDao;

  /// Almacena la información detallada del producto en formato de mapa clave-valor.
  Map<String, dynamic>? _product;
  
  /// Bandera para indicar si los datos del producto se están cargando actualmente.
  bool _isLoading = true;
  
  /// Bandera que define si el usuario actual cuenta con privilegios de Administrador.
  bool _isAdmin = false;
  
  /// Bandera para indicar si el proceso de eliminación del producto está en curso.
  bool _isDeleting = false;
  
  /// Bandera que indica si el producto no se encuentra disponible (ej. error 404 o no existe).
  bool _isUnavailable = false;
  
  /// Bandera para verificar si el controlador ha sido destruido y evitar operaciones asíncronas.
  bool _disposed = false;
  
  /// Almacena el mensaje de error actual en caso de fallos de red o permisos.
  String _errorMessage = '';
  
  /// Suscripción para escuchar los cambios de conectividad a internet en tiempo real.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Getter público para consultar los datos del producto.
  Map<String, dynamic>? get product => _product;
  
  /// Getter público para verificar si el controlador está cargando.
  bool get isLoading => _isLoading;
  
  /// Getter público para saber si el usuario es administrador.
  bool get isAdmin => _isAdmin;
  
  /// Getter público para consultar si se está eliminando el producto.
  bool get isDeleting => _isDeleting;
  
  /// Getter público para saber si el producto no está disponible.
  bool get isUnavailable => _isUnavailable;
  
  /// Getter público para obtener el mensaje de error actual.
  String get errorMessage => _errorMessage;

  /// Inicializa la escucha de red y dispara la carga de sesión y del producto.
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _loadSessionAndProduct();
  }

  /// Maneja los cambios de conectividad detectados por el dispositivo.
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (_disposed) return;
    final isConnected = !results.contains(ConnectivityResult.none);

    if (!isConnected) {
      _isLoading = false;
      _errorMessage = 'Sin conexión a internet';
      notifyListeners();
    } else if (_errorMessage.isNotEmpty) {
      loadProduct();
    }
  }

  /// Carga el rol de la sesión almacenada para definir permisos y luego solicita el producto.
  Future<void> _loadSessionAndProduct() async {
    final role = await _authDao.getStoredRole();
    if (_disposed) return;
    _isAdmin = role == 'Administrador';
    notifyListeners();
    await loadProduct();
  }

  /// Realiza la petición HTTP para obtener los detalles específicos del producto por su ID.
  Future<void> loadProduct() async {
    _isLoading = true;
    _isUnavailable = false;
    _errorMessage = '';
    notifyListeners();

    try {
      if (!await ApiClient.hasInternetConnection()) {
        if (_disposed) return;
        _isLoading = false;
        _errorMessage = 'Sin conexión a internet';
        notifyListeners();
        return;
      }

      final response = await ApiClient.get('/products/$productId');
      if (_disposed) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          _product = decoded;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _isUnavailable = true;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      if (_disposed) return;
      _isLoading = false;
      _errorMessage = 'Sin conexión a internet';
      notifyListeners();
    }
  }

  /// Actualiza de forma local los datos del producto tras una edición exitosa y notifica a la vista.
  void applyUpdatedProduct(Map<String, dynamic> product) {
    _product = product;
    _errorMessage = '';
    notifyListeners();
  }

  /// Elimina el producto mediante una petición DELETE si el usuario cuenta con permisos de administrador y red.
  Future<bool> deleteProduct() async {
    if (_isDeleting || !_isAdmin) return false;

    _isDeleting = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final role = await _authDao.getStoredRole();
      if (_disposed) return false;
      if (role != 'Administrador') {
        _errorMessage = 'No tienes permisos para eliminar productos';
        return false;
      }

      if (!await ApiClient.hasInternetConnection()) {
        if (!_disposed) _errorMessage = 'Sin conexión a internet';
        return false;
      }

      final response = await ApiClient.delete('/products/$productId');
      if (_disposed) return false;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _errorMessage = 'No se pudo eliminar el producto';
        return false;
      }
      return true;
    } catch (_) {
      if (!_disposed) _errorMessage = 'Error de red al eliminar el producto';
      return false;
    } finally {
      _isDeleting = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Libera los recursos del controlador y cancela la suscripción de conectividad al destruir el widget.
  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}