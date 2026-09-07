import 'package:flutter_test/flutter_test.dart';
import 'package:kala_connect/models/product_payload.dart';
import 'package:kala_connect/state/cart_and_orders_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Cart calculates totals, quantities, and delivery fee correctly', () {
    final controller = CartAndOrdersController();

    const product1 = ProductPayload(
      id: 'test-p1',
      heroImagePath: 'https://example.com/horse.jpg',
      name: 'Panchmura Horse',
      category: 'Terracotta',
      description: 'Clay horse',
      suggestedPrice: 300,
      priceLow: 250,
      priceHigh: 400,
      mrp: 500,
      discountPercent: 40,
      currency: 'INR',
      tags: ['terracotta'],
      moreInfo: '',
      additionalImages: [],
      comments: [],
    );

    controller.addToCart(product1, quantity: 1);

    expect(controller.totalItemCount, 1);
    expect(controller.totalSellingPrice, 300);
    expect(controller.totalMrp, 500);
    // Under ₹500, delivery fee is ₹70
    expect(controller.deliveryFee, 70);
    expect(controller.grandTotal, 370);

    // Increase quantity to 2 -> ₹600 > 499 -> Delivery fee is free!
    controller.updateQuantity(product1.id, 2);
    expect(controller.totalItemCount, 2);
    expect(controller.totalSellingPrice, 600);
    expect(controller.deliveryFee, 0);
    expect(controller.grandTotal, 600);

    // Remove from cart
    controller.removeFromCart(product1.id);
    expect(controller.totalItemCount, 0);
    expect(controller.cartItems.isEmpty, true);
  });

  test('Checkout creates an order with tracking and clears cart', () async {
    final controller = CartAndOrdersController();

    const product = ProductPayload(
      id: 'test-p2',
      heroImagePath: 'https://example.com/canvas.jpg',
      name: 'Madhubani Canvas',
      category: 'Folk Art',
      description: 'Handpainted',
      suggestedPrice: 800,
      priceLow: 700,
      priceHigh: 1000,
      mrp: 1200,
      discountPercent: 33,
      currency: 'INR',
      tags: ['madhubani'],
      moreInfo: '',
      additionalImages: [],
      comments: [],
    );

    controller.addToCart(product, quantity: 1);
    final order = await controller.checkout(deliveryAddress: 'Delhi 110001');

    expect(order.items.length, 1);
    expect(order.totalAmount, 800);
    expect(order.status, OrderStatus.ordered);
    expect(order.trackingNumber.startsWith('IN-POST-'), true);
    expect(controller.cartItems.isEmpty, true);
    expect(controller.orders.length, 1);
  });
}
