import 'package:flutter/material.dart';

import '../controllers/product_form_controller.dart';
import 'home_screen.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Map<String, dynamic>? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProductFormController _controller;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _controller = ProductFormController(product: widget.product);
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final role = await _controller.checkAccess();
    if (!mounted || _controller.isAuthorized || _redirecting) return;
    _redirecting = true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(role: role ?? 'Cliente')),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final savedProduct = await _controller.save();
    if (!mounted || savedProduct == null) return;

    if (_controller.isEditing) {
      Navigator.pop(context, savedProduct);
      return;
    }

    final id = savedProduct['id'];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Producto creado. ID: ${id ?? 'sin ID'}')),
      );
    _formKey.currentState!.reset();
    _controller.clearForm();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isCheckingAccess || !_controller.isAuthorized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _controller.isEditing ? 'Editar producto' : 'Agregar producto',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _controller.titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      _controller.validateRequired(value, 'título'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller.priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _controller.validatePrice,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      _controller.validateRequired(value, 'descripción'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller.imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  validator: _controller.validateImageUrl,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller.categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      _controller.validateRequired(value, 'categoría'),
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_controller.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _controller.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _controller.isSaving ? null : _save,
                    icon: _controller.isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _controller.isSaving
                          ? 'Guardando...'
                          : _controller.isEditing
                          ? 'Guardar cambios'
                          : 'Crear producto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
