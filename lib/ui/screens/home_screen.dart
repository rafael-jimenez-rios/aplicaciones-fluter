// Importa los componentes visuales y widgets de Flutter.
import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';

// Importa la pantalla de inicio de sesión para navegar al cerrar sesión.
import 'login_screen.dart';
// Importa la pantalla de detalle del producto para abrir al tocar un producto.
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

/// Pantalla principal que funciona como catálogo de productos.
class HomeScreen extends StatefulWidget {
  // Rol del usuario actual: Administrador, Auditor, Cliente, etc.
  final String role;

  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(role: widget.role)..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Devuelve un color diferente según el rol del usuario.
  Color _getBackgroundColor(String role) {
    switch (role) {
      case 'Administrador':
        // Azul claro para administración.
        return const Color(0xFFB3E5FC);
      case 'Auditor':
        // Morado claro para auditoría.
        return const Color.fromARGB(255, 192, 9, 224);
      case 'Cliente':
        // Verde claro para clientes.
        return const Color(0xFFC8E6C9);
      default:
        // Color por defecto si no coincide ningún rol.
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final backgroundColor = _getBackgroundColor(_controller.role);
        return Scaffold(
          // Barra superior con título y botón de cerrar sesión.
          appBar: AppBar(
            title: Text(
              // Si está en 'Todas', muestra 'Catálogo (rol)'; si no, muestra 'Categoría (rol)'.
              _controller.selectedCategory == 'Todas'
                  ? 'Catálogo (${_controller.role})'
                  : '${_controller.selectedCategory} (${_controller.role})',
            ),
            // El color de la AppBar cambia según el rol.
            backgroundColor: backgroundColor,
            actions: [
              // Botón para cerrar sesión.
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                onPressed: () async {
                  await _controller.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          // Fondo de la pantalla según el rol.
          backgroundColor: backgroundColor,
          floatingActionButton: _controller.role == 'Administrador'
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                )
              : null,
          body: _controller.isLoading
              // Mientras carga, muestra un spinner.
              ? const Center(child: CircularProgressIndicator())
              // Si hubo error, muestra un mensaje y botón de reintentar.
              : _controller.errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono de señal de internet apagada.
                        const Icon(Icons.wifi_off, size: 56),
                        const SizedBox(height: 16),
                        // Mensaje del error.
                        Text(
                          _controller.errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        // Botón para recargar el catálogo.
                        ElevatedButton.icon(
                          onPressed: _controller.loadCatalog,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              // Si todo está bien, muestra filtro y lista de productos.
              : Column(
                  children: [
                    // Fila horizontal con categorías.
                    SizedBox(
                      height: 68,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: _controller.categories.map((category) {
                            // Determina si la categoría está actualmente seleccionada.
                            final isSelected =
                                category == _controller.selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                // Texto de la categoría.
                                label: Text(category),
                                // Si está seleccionada, se ve activa.
                                selected: isSelected,
                                showCheckmark: isSelected,
                                // Al tocarla, cambia la categoría si hay internet.
                                onSelected: (_) =>
                                    _controller.selectCategory(category),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    // Lista de productos visibles según la categoría.
                    Expanded(
                      child: _controller.visibleProducts.isEmpty
                          // Si no hay productos en esa categoría, muestra un mensaje.
                          ? const Center(
                              child: Text(
                                'No hay productos en esta categoría.',
                              ),
                            )
                          // Si hay productos, los muestra en una lista con tarjetas.
                          : ListView.builder(
                              // Margen alrededor de la lista.
                              padding: const EdgeInsets.all(16),
                              // Cuántos elementos tendrá la lista.
                              itemCount: _controller.visibleProducts.length,
                              // Construye cada tarjeta del producto.
                              itemBuilder: (context, index) {
                                // Obtiene el producto actual como un mapa.
                                final product =
                                    _controller.visibleProducts[index];
                                // Extrae el id del producto.
                                final productId = product['id'] as int;
                                // Título del producto, con valor por defecto si falta.
                                final title =
                                    product['title'] as String? ?? 'Producto';
                                // Imagen del producto o cadena vacía si no existe.
                                final image = product['image'] as String? ?? '';
                                // Precio del producto con valor por defecto 0.
                                final price = product['price'] as num? ?? 0;

                                return Card(
                                  // Espaciado entre tarjetas.
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    // Padding interno de cada tarjeta.
                                    contentPadding: const EdgeInsets.all(12),
                                    // Imagen miniatura del producto a la izquierda.
                                    leading: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: Image.network(
                                        image,
                                        fit: BoxFit.contain,
                                        // Si la imagen falla, muestra un icono alternativo.
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                    // Título del producto.
                                    title: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Subtítulo con el precio formateado.
                                    subtitle: Text(
                                      '\$${price.toStringAsFixed(2)}',
                                    ),
                                    // Icono al final para indicar navegación.
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                    ),
                                    // Al tocar la tarjeta, abre el detalle del producto.
                                    onTap: () async {
                                      if (!await _controller
                                          .ensureConnection()) {
                                        return;
                                      }
                                      if (!context.mounted) return;
                                      final deleted =
                                          await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailScreen(
                                                    productId: productId,
                                                  ),
                                            ),
                                          );
                                      if (deleted == true && context.mounted) {
                                        await _controller.selectCategory(
                                          'Todas',
                                        );
                                        await _controller.loadCatalog();
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Producto eliminado correctamente',
                                              ),
                                            ),
                                          );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
