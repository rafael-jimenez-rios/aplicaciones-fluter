import 'package:app4/ui/controllers/product_detail_controller.dart';
import 'package:app4/ui/controllers/product_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductFormController validation', () {
    late ProductFormController controller;

    setUp(() {
      controller = ProductFormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('requires non-empty text', () {
      expect(controller.validateRequired('  ', 'título'), isNotNull);
      expect(controller.validateRequired('Libro', 'título'), isNull);
    });

    test('accepts only positive numeric prices', () {
      expect(controller.validatePrice('abc'), isNotNull);
      expect(controller.validatePrice('0'), isNotNull);
      expect(controller.validatePrice('12.50'), isNull);
    });

    test('accepts only absolute HTTP image URLs', () {
      expect(controller.validateImageUrl('imagen.png'), isNotNull);
      expect(controller.validateImageUrl('https://'), isNotNull);
      expect(
        controller.validateImageUrl('https://store.test/item.png'),
        isNull,
      );
    });
  });

  test('does not send DELETE without administrator authorization', () async {
    final controller = ProductDetailController(productId: 1);
    expect(await controller.deleteProduct(), isFalse);
    controller.dispose();
  });
}
