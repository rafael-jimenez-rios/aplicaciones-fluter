import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/daos/auth_dao.dart';
import '../../data/network/api_client.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AuthDao _authDao = AuthDao();

  Map<String, dynamic>? _product;
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _loadSessionAndProduct();
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
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSessionAndProduct() async {
    final role = await _authDao.getStoredRole();

    if (!mounted) return;

    setState(() {
      _isAdmin = role == 'Administrador';
    });

    await _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final isConnected = await ApiClient.hasInternetConnection();
      if (!isConnected) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sin conexión a internet';
        });
        return;
      }

      final response = await ApiClient.get('/products/${widget.productId}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _product = decoded;
            _isLoading = false;
            _errorMessage = '';
          });
          return;
        }
      }

      _showUnavailableAndGoBack();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sin conexión a internet';
      });
    }
  }

  Future<void> _showUnavailableAndGoBack() async {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Producto no disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProduct,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(
        body: Center(
          child: Text('Producto no disponible'),
        ),
      );
    }

    final title = product['title'] as String? ?? 'Sin título';
    final description = product['description'] as String? ?? 'Sin descripción';
    final category = product['category'] as String? ?? 'Sin categoría';
    final price = product['price'];
    final image = product['image'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${(price as num?)?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(fontSize: 16),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Acciones futuras.
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Acciones futuras.
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
