import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/daos/auth_dao.dart';
import '../../data/network/api_client.dart';

// Controlador del formulario para crear o editar un producto.
// Extiende ChangeNotifier para avisar a la UI cuando cambian estados.
class ProductFormController extends ChangeNotifier {
  // Constructor: recibe opcionalmente un producto existente y un DAO de autenticación.
  // Si se recibe un producto, el formulario entra en modo edición.
  ProductFormController({Map<String, dynamic>? product, AuthDao? authDao})
    : _product = product,
      _authDao = authDao ?? AuthDao() {
    // Inicializa cada campo del formulario con el valor actual del producto,
    // o con cadena vacía si se está creando uno nuevo.
    titleController = TextEditingController(
      text: product?['title'] as String? ?? '',
    );
    priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: product?['description'] as String? ?? '',
    );
    imageController = TextEditingController(
      text: product?['image'] as String? ?? '',
    );
    categoryController = TextEditingController(
      text: product?['category'] as String? ?? '',
    );
  }

  // Producto actual si estamos editando; null si es creación.
  final Map<String, dynamic>? _product;

  // Servicio para consultar el rol del usuario autenticado.
  final AuthDao _authDao;

  // TextEditingController para cada input del formulario.
  late final TextEditingController titleController;
  late final TextEditingController priceController;
  late final TextEditingController descriptionController;
  late final TextEditingController imageController;
  late final TextEditingController categoryController;

  // Estados internos del controlador.
  bool _isCheckingAccess = true;
  bool _isAuthorized = false;
  bool _isSaving = false;
  bool _disposed = false;
  String _errorMessage = '';

  // Getters para exponer información a la pantalla.
  bool get isEditing => _product != null;
  bool get isCheckingAccess => _isCheckingAccess;
  bool get isAuthorized => _isAuthorized;
  bool get isSaving => _isSaving;
  String get errorMessage => _errorMessage;

  // Verifica si el usuario autenticado tiene permisos de administrador.
  Future<String?> checkAccess() async {
    final role = await _authDao.getStoredRole();

    // Si el controlador ya fue destruido, no continúo.
    if (_disposed) return null;

    // Si el rol es Administrador, habilita la edición.
    _isAuthorized = role == 'Administrador';
    _isCheckingAccess = false;

    // Notifica a la UI para que actualice la pantalla.
    notifyListeners();
    return role;
  }

  // Valida que un campo obligatorio no esté vacío.
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  // Valida que el precio sea numérico y mayor que cero.
  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el precio';
    }

    final price = num.tryParse(value.trim());
    if (price == null || !price.isFinite || price <= 0) {
      return 'Ingresa un precio numérico mayor que cero';
    }
    return null;
  }

  // Valida que la imagen tenga una URL válida y con http/https.
  String? validateImageUrl(String? value) {
    final requiredError = validateRequired(value, 'URL de imagen');
    if (requiredError != null) return requiredError;

    final uri = Uri.tryParse(value!.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Ingresa una URL válida (http o https)';
    }
    return null;
  }

  // Guarda el producto: crea uno nuevo o actualiza uno existente.
  Future<Map<String, dynamic>?> save() async {
    // Evita doble guardado y valida permisos y formulario.
    if (_isSaving || !_isAuthorized || !_isValidFormData()) return null;

    _isSaving = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Vuelvo a confirmar el rol por seguridad.
      final role = await _authDao.getStoredRole();
      if (role != 'Administrador') {
        _errorMessage = 'No tienes permisos para modificar productos';
        return null;
      }

      // Reviso conexión antes de enviar la petición.
      if (!await ApiClient.hasInternetConnection()) {
        _errorMessage = 'Sin conexión a internet';
        return null;
      }

      // Construyo el body con los datos del formulario.
      final body = <String, dynamic>{
        'title': titleController.text.trim(),
        'price': num.parse(priceController.text.trim()),
        'description': descriptionController.text.trim(),
        'image': imageController.text.trim(),
        'category': categoryController.text.trim(),
      };

      // Si es edición, uso PUT; si es creación, uso POST.
      final response = isEditing
          ? await ApiClient.put('/products/${_product!['id']}', body)
          : await ApiClient.post('/products', body);

      // Si el controlador ya fue destruido, no sigo.
      if (_disposed) return null;

      // Verifico que la respuesta HTTP sea exitosa.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _errorMessage = 'No se pudo guardar el producto';
        return null;
      }

      // Decodifico el JSON y devuelvo el producto resultante.
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return {...body, ...decoded};
      }

      _errorMessage = 'La respuesta del servidor no es válida';
      return null;
    } catch (_) {
      // Captura errores de red o parseo del JSON.
      if (!_disposed) _errorMessage = 'Error de red al guardar el producto';
      return null;
    } finally {
      // Siempre termino el estado de carga y actualizo la UI.
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  // Comprueba que todos los campos principales estén bien llenados.
  bool _isValidFormData() {
    return titleController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        categoryController.text.trim().isNotEmpty &&
        validatePrice(priceController.text) == null &&
        validateImageUrl(imageController.text) == null;
  }

  // Vacia todos los inputs del formulario.
  void clearForm() {
    titleController.clear();
    priceController.clear();
    descriptionController.clear();
    imageController.clear();
    categoryController.clear();
  }

  // Limpieza final: libera los controladores y marca el objeto como destruido.
  @override
  void dispose() {
    _disposed = true;
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}
