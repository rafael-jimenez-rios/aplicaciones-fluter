import 'package:flutter/material.dart';

import '../controllers/product_detail_controller.dart';
import 'product_form_screen.dart';

// Pantalla que muestra el detalle de un producto y maneja
// estados de carga, error y permisos de administrador.
class ProductDetailScreen extends StatefulWidget {
  // Identificador del producto recibido desde la pantalla anterior.
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailController _controller;
  bool _unavailableDialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = ProductDetailController(productId: widget.productId)
      ..addListener(_handleControllerChange)
      ..initialize();
  }

  void _handleControllerChange() {
    if (!_controller.isUnavailable || _unavailableDialogShown) return;
    _unavailableDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnavailableAndGoBack();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChange)
      ..dispose();
    super.dispose();
  }

  // Muestra un diálogo indicando que el producto no está disponible y regresa.
  Future<void> _showUnavailableAndGoBack() async {
    if (!mounted) return;

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

  Future<void> _editProduct() async {
    final product = _controller.product;
    if (product == null) return;
    final updatedProduct = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (!mounted || updatedProduct == null) return;
    _controller.applyUpdatedProduct(updatedProduct);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto actualizado correctamente')),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _controller.isDeleting
                ? null
                : () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await _controller.deleteProduct();
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context, true);
    } else if (_controller.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_controller.errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Mientras carga, muestra un spinner de carga.
    if (_controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si hubo un error, muestra un mensaje y un botón para reintentar.
    if (_controller.errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _controller.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _controller.loadProduct,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Extrae el producto actual; si es nulo, muestra un mensaje.
    final product = _controller.product;
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Producto no disponible')),
      );
    }

    // Toma los campos relevantes del JSON para mostrarlos en la UI.
    final title = product['title'] as String? ?? 'Sin título';
    final description = product['description'] as String? ?? 'Sin descripción';
    final category = product['category'] as String? ?? 'Sin categoría';
    final price = product['price'];
    final image = product['image'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal del producto con fallback si falla la carga.
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_not_supported, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título del producto.
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Precio formateado con dos decimales.
            Text(
              '\$${(price as num?)?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Sección de descripción.
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Sección de categoría.
            const Text(
              'Categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(category, style: const TextStyle(fontSize: 16)),

            // Si el usuario es administrador, aparecen acciones de edición y eliminación.
            if (_controller.isAdmin) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _editProduct,
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
                  onPressed: _controller.isDeleting ? null : _confirmDelete,
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
