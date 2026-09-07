import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart_and_orders_controller.dart';
import '../../state/locale_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import 'checkout_bottom_sheet.dart';

class CartAndOrdersScreen extends StatefulWidget {
  const CartAndOrdersScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<CartAndOrdersScreen> createState() => _CartAndOrdersScreenState();
}

class _CartAndOrdersScreenState extends State<CartAndOrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartAndOrdersController>();
    final loc = context.watch<LocaleController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(loc.tr('cart_and_orders'), style: const TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)),
        actions: [
          if (cart.orders.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text(loc.tr('clear_orders'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    content: Text(loc.tr('clear_orders_msg')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.tr('cancel'))),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
                        child: Text(loc.tr('clear_all')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await cart.clearAllOrders();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.tr('all_orders_cleared'))),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: KalaColors.terracotta),
              label: Text(loc.tr('clear_all'), style: const TextStyle(color: KalaColors.terracotta, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KalaColors.terracotta,
          labelColor: KalaColors.terracotta,
          unselectedLabelColor: const Color(0xFF6B6572),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          tabs: [
            Tab(text: '${loc.tr('cart')} (${cart.totalItemCount})'),
            Tab(text: '${loc.tr('my_orders')} (${cart.orders.length})'),
          ],
        ),
      ),
      body: AmbientLivingCanvas(
        child: TabBarView(
          controller: _tabController,
          children: [
            _CartView(cart: cart),
            _OrdersView(cart: cart),
          ],
        ),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({required this.cart});
  final CartAndOrdersController cart;

  Future<void> _proceedToCheckout(BuildContext context) async {
    final loc = context.read<LocaleController>();
    final order = await CheckoutBottomSheet.show(context);
    if (order != null && context.mounted) {
      showDialog<void>(
        context: context,
        builder: (alertCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: KalaColors.leaf, size: 28),
              const SizedBox(width: 8),
              Text(loc.tr('order_placed_title'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Text(
            '${loc.tr('order_placed_desc')}\n\nOrder #${order.orderId} • ₹${order.totalAmount}\nTracking: ${order.trackingNumber}',
            style: const TextStyle(height: 1.3),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(alertCtx).pop(),
              style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
              child: Text(loc.tr('view_in_my_orders')),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cart.cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_rounded, size: 70, color: Colors.black26),
            SizedBox(height: 14),
            Text('Your Cart is Empty', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            SizedBox(height: 6),
            Text('Explore authentic handcrafted art from artisans across India.', style: TextStyle(color: Color(0xFF6B6572))),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Free delivery progress banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: KalaColors.leaf.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: KalaColors.leaf, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cart.deliveryFee == 0
                      ? 'Congratulations! Your order qualifies for FREE Delivery.'
                      : 'Add ₹${500 - cart.totalSellingPrice} more for FREE Delivery.',
                  style: const TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = cart.cartItems[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildCartImage(item.product.heroImagePath, width: 80, height: 80),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text('By ${item.product.artisanName}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B6572), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('₹${item.product.suggestedPrice}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: KalaColors.ink)),
                              const SizedBox(width: 6),
                              Text('₹${item.product.effectiveMrp}', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.black38)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildQtyButton(
                                icon: Icons.remove,
                                onTap: () => cart.updateQuantity(item.product.id, item.quantity - 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              ),
                              _buildQtyButton(
                                icon: Icons.add,
                                onTap: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.black45, size: 20),
                                onPressed: () => cart.removeFromCart(item.product.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Bottom checkout bar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.watch<LocaleController>().tr('total_to_pay'), style: const TextStyle(fontSize: 12, color: Color(0xFF6B6572), fontWeight: FontWeight.w700)),
                      Text('₹${cart.grandTotal}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: KalaColors.ink)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _proceedToCheckout(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: KalaColors.terracotta,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: Text('${context.watch<LocaleController>().tr('proceed_to_buy')} (${cart.totalItemCount})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: KalaColors.ink),
      ),
    );
  }

  Widget _buildCartImage(String path, {required double width, required double height}) {
    if (path.startsWith('http')) {
      return Image.network(path, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image)));
    }
    return Image.file(File(path), width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image)));
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView({required this.cart});
  final CartAndOrdersController cart;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleController>();

    if (cart.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 70, color: Colors.black26),
            const SizedBox(height: 14),
            Text(loc.tr('no_orders_yet'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(loc.tr('no_orders_sub'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B6572))),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = cart.orders[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KalaColors.leaf.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.status == OrderStatus.ordered ? loc.tr('order_status_crafting') : order.status.name.toUpperCase(),
                      style: const TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Placed on ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} • Tracking: ${order.trackingNumber}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B6572)),
              ),
              const Divider(height: 20),
              // Items
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: KalaColors.terracotta, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${i.quantity}x ${i.product.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                        Text('₹${i.product.suggestedPrice * i.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              // Real-time timeline
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KalaColors.ivory,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: KalaColors.indigo, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.tr('dispatched_direct_post'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A3525)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${loc.tr('total_to_pay')} ₹${order.totalAmount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: KalaColors.ink)),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Certified artisan invoice downloaded.')),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: Text(loc.tr('invoice'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
