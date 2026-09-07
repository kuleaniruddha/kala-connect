import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product_payload.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_and_orders_controller.dart';
import '../../state/locale_controller.dart';
import '../../theme/kala_theme.dart';
import '../auth/email_auth_dialog.dart';

class CheckoutBottomSheet extends StatefulWidget {
  const CheckoutBottomSheet({
    this.directBuyProduct,
    super.key,
  });

  final ProductPayload? directBuyProduct;

  static Future<MarketplaceOrder?> show(BuildContext context, {ProductPayload? directBuyProduct}) async {
    final auth = context.read<AuthController>();
    final appFlow = context.read<AppFlowController>();
    if (!auth.isSignedIn) {
      final signedIn = await EmailAuthDialog.show(context);
      if (!context.mounted) return null;
      if (!signedIn && !auth.isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in with Email OTP to proceed to checkout.')),
        );
        return null;
      }
    }

    final currentUserId = auth.identity?.uid;
    final currentProfileName = appFlow.profile?.name.trim().toLowerCase();
    if (directBuyProduct != null && currentUserId != null) {
      final isOwn = (directBuyProduct.artisanId.isNotEmpty &&
              (currentUserId == directBuyProduct.artisanId || appFlow.isBoundTo(directBuyProduct.artisanId))) ||
          (currentProfileName != null &&
              currentProfileName.isNotEmpty &&
              currentProfileName == directBuyProduct.artisanName.trim().toLowerCase());
      if (isOwn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot purchase your own listed craft.')),
        );
        return null;
      }
    }

    return showModalBottomSheet<MarketplaceOrder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutBottomSheet(directBuyProduct: directBuyProduct),
    );
  }

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _paymentMethod = 'cod'; // 'cod', 'upi', 'netbanking'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    if (auth.identity?.displayName != null) {
      _nameController.text = auth.identity!.displayName!;
    }
    if (auth.identity?.phoneNumber != null && auth.identity!.phoneNumber!.isNotEmpty) {
      _phoneController.text = auth.identity!.phoneNumber!.replaceAll('+91', '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndPlaceOrder() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (phone.length < 10) {
      _showError('Please enter a valid 10-digit mobile number.');
      return;
    }
    if (address.length < 6) {
      _showError('Please enter your complete delivery street address.');
      return;
    }
    if (pincode.length < 6) {
      _showError('Please enter a valid 6-digit delivery pincode.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = context.read<CartAndOrdersController>();
      final fullAddress = '$name, $phone, $address, Pincode: $pincode [Payment: ${_paymentMethod.toUpperCase()}]';

      final auth = context.read<AuthController>();
      final order = await cart.checkout(
        deliveryAddress: fullAddress,
        directBuyProduct: widget.directBuyProduct,
        userId: auth.identity?.uid,
      );

      if (!mounted) return;
      Navigator.of(context).pop(order);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Order failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartAndOrdersController>();
    final loc = context.watch<LocaleController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isDirectBuy = widget.directBuyProduct != null;
    final itemsTotal = isDirectBuy ? widget.directBuyProduct!.suggestedPrice : cart.totalSellingPrice;
    final deliveryFee = isDirectBuy ? (itemsTotal >= 999 ? 0 : 70) : cart.deliveryFee;
    final grandTotal = itemsTotal + deliveryFee;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: KalaColors.ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Color(0x331A1720), blurRadius: 28, offset: Offset(0, -6)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KalaColors.terracotta.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: KalaColors.terracotta, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.tr('checkout_title'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cost Overview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.tr('items_total'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('₹$itemsTotal', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.tr('delivery_fee'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        deliveryFee == 0 ? 'FREE' : '₹$deliveryFee',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: deliveryFee == 0 ? KalaColors.leaf : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.tr('grand_total'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                        '₹$grandTotal',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: KalaColors.leaf),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Delivery Fields
            Text(loc.tr('contact_name'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Full recipient name',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: KalaColors.terracotta, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.tr('contact_phone'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: InputDecoration(
                          hintText: '10-digit mobile number',
                          prefixText: '+91 ',
                          prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: KalaColors.ink),
                          prefixIcon: const Icon(Icons.phone_outlined, color: KalaColors.terracotta, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pincode / पिन', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                        decoration: InputDecoration(
                          hintText: 'e.g. 110001',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(loc.tr('delivery_address'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'House/Flat No, Landmark, Street...',
                prefixIcon: const Icon(Icons.home_outlined, color: KalaColors.terracotta, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method
            Text(loc.tr('payment_method'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            _buildPaymentOption(
              key: 'cod',
              title: loc.tr('pay_cod'),
              subtitle: 'Pay with cash upon package arrival',
              icon: Icons.payments_outlined,
            ),
            _buildPaymentOption(
              key: 'upi',
              title: loc.tr('pay_upi'),
              subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
              icon: Icons.qr_code_rounded,
            ),
            _buildPaymentOption(
              key: 'netbanking',
              title: loc.tr('pay_netbanking'),
              subtitle: 'All major Indian banks & RuPay cards',
              icon: Icons.account_balance_outlined,
            ),

            const SizedBox(height: 20),

            // Confirm & Place Order Action
            FilledButton.icon(
              onPressed: _isProcessing ? null : _confirmAndPlaceOrder,
              style: FilledButton.styleFrom(
                backgroundColor: KalaColors.leaf,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                _isProcessing ? 'Processing Order...' : '${loc.tr('confirm_place_order')} (₹$grandTotal)',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == key;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? KalaColors.terracotta : Colors.black.withValues(alpha: 0.08),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: () => setState(() => _paymentMethod = key),
        dense: true,
        leading: Icon(icon, color: isSelected ? KalaColors.terracotta : Colors.black54),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
          color: isSelected ? KalaColors.terracotta : Colors.black38,
        ),
      ),
    );
  }
}
