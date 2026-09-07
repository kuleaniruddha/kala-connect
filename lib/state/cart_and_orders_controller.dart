import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_payload.dart';

class CartItem {
  const CartItem({required this.product, this.quantity = 1});

  final ProductPayload product;
  final int quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: ProductPayload.fromJson(json['product'] as Map<String, dynamic>),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

enum OrderStatus {
  ordered,
  artisanPreparing,
  shippedOndc,
  delivered,
}

class MarketplaceOrder {
  const MarketplaceOrder({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.createdAt,
    required this.status,
    required this.trackingNumber,
    this.userId,
  });

  final String orderId;
  final List<CartItem> items;
  final int totalAmount;
  final String shippingAddress;
  final DateTime createdAt;
  final OrderStatus status;
  final String trackingNumber;
  final String? userId;

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'items': items.map((i) => i.toJson()).toList(),
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'trackingNumber': trackingNumber,
        if (userId != null) 'userId': userId,
      };

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) => MarketplaceOrder(
        orderId: json['orderId'] as String,
        items: (json['items'] as List<dynamic>)
            .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        totalAmount: (json['totalAmount'] as num).toInt(),
        shippingAddress: json['shippingAddress'] as String? ?? 'Delivery Address',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        status: OrderStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => OrderStatus.ordered,
        ),
        trackingNumber: json['trackingNumber'] as String? ?? 'IN-POST-482910',
        userId: json['userId'] as String?,
      );
}

class CartAndOrdersController extends ChangeNotifier {
  CartAndOrdersController() {
    initialization = _loadState();
  }

  static const _cartKey = 'kala_cart_items_v2';
  static const _ordersKey = 'kala_orders_list_v2';
  static const _legacyOrdersKey = 'kala_orders_list_v1';

  late final Future<void> initialization;
  final List<CartItem> _cartItems = [];
  final List<MarketplaceOrder> _orders = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  List<MarketplaceOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  int get totalItemCount => _cartItems.fold(0, (total, item) => total + item.quantity);

  int get totalMrp => _cartItems.fold(0, (total, item) => total + (item.product.effectiveMrp * item.quantity));

  int get totalSellingPrice => _cartItems.fold(0, (total, item) => total + (item.product.suggestedPrice * item.quantity));

  int get totalSavings => totalMrp - totalSellingPrice;

  int get deliveryFee => totalSellingPrice > 499 ? 0 : 70;

  int get grandTotal => totalSellingPrice + deliveryFee;

  void addToCart(ProductPayload product, {int quantity = 1}) {
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: _cartItems[index].quantity + quantity);
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: newQuantity);
      _saveCart();
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
    notifyListeners();
  }

  /// Discard any fake/mock orders and clear order history
  Future<void> clearAllOrders() async {
    _orders.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_ordersKey);
    await preferences.remove(_legacyOrdersKey);
    notifyListeners();
  }

  Future<MarketplaceOrder> checkout({
    required String deliveryAddress,
    ProductPayload? directBuyProduct,
    String? userId,
  }) async {
    await initialization;
    final orderItems = directBuyProduct != null
        ? [CartItem(product: directBuyProduct, quantity: 1)]
        : List<CartItem>.from(_cartItems);

    if (orderItems.isEmpty) {
      throw StateError('Cannot checkout an empty cart.');
    }

    final total = directBuyProduct != null
        ? directBuyProduct.suggestedPrice
        : grandTotal;

    final orderId = 'KC-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
    final tracking = 'IN-POST-${(100000 + DateTime.now().millisecond * 87).toString()}';

    final newOrder = MarketplaceOrder(
      orderId: orderId,
      items: orderItems,
      totalAmount: total,
      shippingAddress: deliveryAddress.isEmpty ? 'Deliver to: Current Location' : deliveryAddress,
      createdAt: DateTime.now(),
      status: OrderStatus.ordered,
      trackingNumber: tracking,
      userId: userId,
    );

    _orders.insert(0, newOrder);
    if (directBuyProduct == null) {
      _cartItems.clear();
      await _saveCart();
    }
    await _saveOrders();

    // Persist real order to Cloud Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      final payload = {
        ...newOrder.toJson(),
        'serverTimestamp': FieldValue.serverTimestamp(),
      };
      await firestore.collection('orders').doc(orderId).set(payload);
      if (userId != null && userId.isNotEmpty) {
        await firestore.collection('users').doc(userId).collection('orders').doc(orderId).set(payload);
      }
      debugPrint('📦 [Firestore] Order $orderId persisted successfully to kala-connect-9648e');
    } catch (e) {
      debugPrint('Order Firestore persistence note: $e');
    }

    notifyListeners();
    return newOrder;
  }

  Future<void> _loadState() async {
    _isLoading = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      
      // Clean legacy mock orders from earlier versions
      if (preferences.containsKey(_legacyOrdersKey)) {
        await preferences.remove(_legacyOrdersKey);
      }

      final cartRaw = preferences.getStringList(_cartKey) ?? [];
      _cartItems.clear();
      for (final raw in cartRaw) {
        try {
          _cartItems.add(CartItem.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {}
      }

      final ordersRaw = preferences.getStringList(_ordersKey) ?? [];
      _orders.clear();
      for (final raw in ordersRaw) {
        try {
          _orders.add(MarketplaceOrder.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {}
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final preferences = await SharedPreferences.getInstance();
    final rawList = _cartItems.map((item) => jsonEncode(item.toJson())).toList(growable: false);
    await preferences.setStringList(_cartKey, rawList);
  }

  Future<void> _saveOrders() async {
    final preferences = await SharedPreferences.getInstance();
    final rawList = _orders.map((order) => jsonEncode(order.toJson())).toList(growable: false);
    await preferences.setStringList(_ordersKey, rawList);
  }
}
