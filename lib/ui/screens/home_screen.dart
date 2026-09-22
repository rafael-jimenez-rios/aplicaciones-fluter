// Permite convertir respuestas JSON en objetos Dart.
import 'dart:convert';
import 'dart:async';

// Importa los componentes visuales de Flutter.
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Importa la clase encargada de gestionar la sesión.
import '../../data/daos/auth_dao.dart';
import '../../data/network/api_client.dart';

// Importa la pantalla de inicio de sesión.
import 'login_screen.dart';
import 'product_detail_screen.dart';

/// Pantalla principal que funciona como catálogo general.
class HomeScreen extends StatefulWidget {
  final String role;

  const HomeScreen({
    super.key,
    required this.role,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthDao _authDao = AuthDao();

  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedCategory = 'Todas';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _loadCatalog();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (!mounted) return;

    final isConnected = !results.contains(ConnectivityResult.none);
    if (!isConnected) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sin conexión a internet';
      });
    } else if (_errorMessage.isNotEmpty) {
      _loadCatalog();
    }
  }

  void _showOfflineMessage() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'Sin conexión a internet';
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.role) {
      case 'Administrador':
        return const Color(0xFFB3E5FC);
      case 'Auditor':
        return const Color(0xFFE1BEE7);
      case 'Cliente':
        return const Color(0xFFC8E6C9);
      default:
        return Colors.white;
    }
  }

  Future<void> _loadCatalog() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final isConnected = await ApiClient.hasInternetConnection();
      if (!isConnected) {
        _showOfflineMessage();
        return;
      }

      final response = await ApiClient.get('/products');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _products = decoded;
            _errorMessage = '';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = 'Sin conexión a internet';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Sin conexión a internet';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authDao.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  List<String> get _categories {
    final categories = _products
        .whereType<Map<String, dynamic>>()
        .map((product) => product['category'] as String?)
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return ['Todas', ...categories];
  }

  List<dynamic> get _visibleProducts {
    if (_selectedCategory == 'Todas') return _products;

    return _products.where((product) {
      if (product is! Map<String, dynamic>) return false;
      return product['category'] == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCategory == 'Todas'
              ? 'Catálogo (${widget.role})'
              : '${_selectedCategory} (${widget.role})',
        ),
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCatalog,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 68,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = category == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                showCheckmark: isSelected,
                                onSelected: (_) async {
                                  final isConnected =
                                      await ApiClient.hasInternetConnection();
                                  if (!isConnected) {
                                    _showOfflineMessage();
                                    return;
                                  }
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _visibleProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay productos en esta categoría.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _visibleProducts.length,
                              itemBuilder: (context, index) {
                                final product = _visibleProducts[index]
                                    as Map<String, dynamic>;
                                final productId = product['id'] as int;
                                final title =
                                    product['title'] as String? ?? 'Producto';
                                final image = product['image'] as String? ?? '';
                                final price = product['price'] as num? ?? 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: Image.network(
                                        image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '\$${price.toStringAsFixed(2)}',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                    ),
                                    onTap: () async {
                                      final isConnected =
                                          await ApiClient.hasInternetConnection();
                                      if (!isConnected) {
                                        _showOfflineMessage();
                                        return;
                                      }
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailScreen(
                                            productId: productId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
