import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/cart_and_orders_controller.dart';
import '../../theme/kala_theme.dart';

class InvoiceSheet extends StatelessWidget {
  const InvoiceSheet({required this.order, super.key});

  final MarketplaceOrder order;

  static Future<void> show(BuildContext context, MarketplaceOrder order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvoiceSheet(order: order),
    );
  }

  static String generatePlainTextInvoice(MarketplaceOrder order) {
    final buffer = StringBuffer();
    buffer.writeln('==============================================');
    buffer.writeln('          कला-Connect (KALA-CONNECT)         ');
    buffer.writeln(' DIRECT ARTISAN TAX INVOICE & CASH RECEIPT   ');
    buffer.writeln('==============================================');
    buffer.writeln('Invoice No   : INV-${order.orderId}');
    buffer.writeln('Order ID     : #${order.orderId}');
    buffer.writeln('Date         : ${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}');
    buffer.writeln('Tracking No  : ${order.trackingNumber} (India Post Speed Post)');
    buffer.writeln('Order Status : ${order.status.name.toUpperCase()}');
    buffer.writeln('----------------------------------------------');
    buffer.writeln('ARTISAN / SELLER:');
    final firstProduct = order.items.isNotEmpty ? order.items.first.product : null;
    buffer.writeln('Artisan      : ${firstProduct?.artisanName ?? "Traditional Indian Artisan"}');
    buffer.writeln('Location     : ${firstProduct?.artisanLocation ?? "India"}');
    buffer.writeln('GST Status   : Exempt (Notif 12/2017 Handicrafts & Handloom)');
    buffer.writeln('----------------------------------------------');
    buffer.writeln('BUYER / SHIP TO:');
    buffer.writeln('Address      : ${order.shippingAddress}');
    buffer.writeln('----------------------------------------------');
    buffer.writeln('ITEMS:');
    for (final item in order.items) {
      final lineTotal = item.product.suggestedPrice * item.quantity;
      buffer.writeln('- ${item.product.name}');
      buffer.writeln('  Qty: ${item.quantity}  x  ₹${item.product.suggestedPrice} = ₹$lineTotal');
    }
    buffer.writeln('----------------------------------------------');
    final itemsSubtotal = order.items.fold(0, (sum, i) => sum + (i.product.suggestedPrice * i.quantity));
    final deliveryFee = order.totalAmount > itemsSubtotal ? (order.totalAmount - itemsSubtotal) : 0;
    buffer.writeln('Subtotal     : ₹$itemsSubtotal');
    buffer.writeln('Delivery Fee : ${deliveryFee == 0 ? "FREE" : "₹$deliveryFee"}');
    buffer.writeln('GST / Taxes  : ₹0.00 (Exempted)');
    buffer.writeln('GRAND TOTAL  : ₹${order.totalAmount}');
    buffer.writeln('==============================================');
    buffer.writeln('AUTHENTICITY GUARANTEE:');
    buffer.writeln('100% of proceeds paid directly to the artisan.');
    buffer.writeln('Direct craft dispatch via India Post.');
    buffer.writeln('==============================================');
    return buffer.toString();
  }

  static String generateHtmlInvoice(MarketplaceOrder order) {
    final firstProduct = order.items.isNotEmpty ? order.items.first.product : null;
    final itemsSubtotal = order.items.fold(0, (sum, i) => sum + (i.product.suggestedPrice * i.quantity));
    final deliveryFee = order.totalAmount > itemsSubtotal ? (order.totalAmount - itemsSubtotal) : 0;

    final itemsRows = order.items.map((i) {
      final lineTotal = i.product.suggestedPrice * i.quantity;
      return '''
      <tr>
        <td style="padding: 10px; border-bottom: 1px solid #eee;">
          <strong>${i.product.name}</strong><br/>
          <small style="color: #666;">Craft: ${i.product.category} • Artisan: ${i.product.artisanName}</small>
        </td>
        <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: center;">${i.quantity}</td>
        <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">₹${i.product.suggestedPrice}</td>
        <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right; font-weight: bold;">₹$lineTotal</td>
      </tr>
      ''';
    }).join();

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice #${order.orderId} - कला-Connect</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 20px; color: #1E1A22; background: #faf9f6; }
    .invoice-box { max-width: 800px; margin: auto; padding: 30px; border: 1px solid #eee; background: #fff; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #C85A32; padding-bottom: 15px; margin-bottom: 20px; }
    .brand { font-size: 26px; font-weight: 900; color: #C85A32; }
    .brand-sub { font-size: 12px; color: #666; }
    .meta { text-align: right; font-size: 13px; color: #444; }
    .grid { display: flex; justify-content: space-between; margin-bottom: 20px; gap: 20px; }
    .card { flex: 1; padding: 14px; background: #fdfbf7; border: 1px solid #f0eae1; border-radius: 12px; font-size: 13px; }
    .card h4 { margin: 0 0 8px 0; color: #C85A32; font-size: 14px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th { background: #FAF2EC; color: #C85A32; text-align: left; padding: 10px; font-size: 13px; }
    .totals { width: 300px; margin-left: auto; margin-bottom: 20px; font-size: 14px; }
    .totals table td { padding: 6px 10px; }
    .total-highlight { font-size: 18px; font-weight: 900; color: #2E7D32; border-top: 2px solid #ddd; }
    .badge { display: inline-block; background: #E8F5E9; color: #2E7D32; padding: 4px 10px; border-radius: 8px; font-weight: bold; font-size: 12px; }
    .footer { text-align: center; border-top: 1px dashed #ccc; padding-top: 15px; font-size: 11px; color: #777; }
    @media print { body { background: #fff; margin: 0; } .invoice-box { box-shadow: none; border: none; } }
  </style>
</head>
<body>
  <div class="invoice-box">
    <div class="header">
      <div>
        <div class="brand">कला-Connect</div>
        <div class="brand-sub">Direct Indian Artisan Marketplace • ONDC Certified</div>
      </div>
      <div class="meta">
        <strong>TAX INVOICE / CASH RECEIPT</strong><br/>
        <strong>Invoice No:</strong> INV-${order.orderId}<br/>
        <strong>Order ID:</strong> #${order.orderId}<br/>
        <strong>Date:</strong> ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}<br/>
        <strong>Tracking:</strong> ${order.trackingNumber}
      </div>
    </div>

    <div class="grid">
      <div class="card">
        <h4>Artisan / Seller Details</h4>
        <strong>${firstProduct?.artisanName ?? "Traditional Indian Artisan"}</strong><br/>
        Location: ${firstProduct?.artisanLocation ?? "India"}<br/>
        Certification: Verified GI Craft Creator<br/>
        Tax Exemption: Handloom Scheme Notif. 12/2017
      </div>
      <div class="card">
        <h4>Buyer / Shipping Address</h4>
        ${order.shippingAddress.replaceAll('\n', '<br/>')}
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th>Craft / Item Description</th>
          <th style="text-align: center;">Qty</th>
          <th style="text-align: right;">Rate</th>
          <th style="text-align: right;">Amount</th>
        </tr>
      </thead>
      <tbody>
        $itemsRows
      </tbody>
    </table>

    <div class="totals">
      <table>
        <tr>
          <td>Crafts Subtotal:</td>
          <td style="text-align: right;">₹$itemsSubtotal</td>
        </tr>
        <tr>
          <td>India Post Delivery:</td>
          <td style="text-align: right;">${deliveryFee == 0 ? "FREE" : "₹$deliveryFee"}</td>
        </tr>
        <tr>
          <td>GST / Handloom Cess:</td>
          <td style="text-align: right;">₹0.00 (Exempt)</td>
        </tr>
        <tr class="total-highlight">
          <td>Grand Total:</td>
          <td style="text-align: right;">₹${order.totalAmount}</td>
        </tr>
      </table>
    </div>

    <div style="margin-bottom: 20px; text-align: center;">
      <span class="badge">✓ CERTIFIED DIRECT ARTISAN PURCHASE • 100% LIVING WAGE COMPLIANT</span>
    </div>

    <div class="footer">
      This is a digitally verified invoice generated by कला-Connect.<br/>
      Your purchase directly empowers rural Indian artisans and preserves indigenous craft heritage.<br/>
      Track parcel status using Speed Post: <strong>${order.trackingNumber}</strong>
    </div>
  </div>
</body>
</html>''';
  }

  static Future<File?> downloadInvoiceToFile(MarketplaceOrder order) async {
    final html = generateHtmlInvoice(order);
    final txt = generatePlainTextInvoice(order);
    final fileNameHtml = 'Invoice_${order.orderId}.html';
    final fileNameTxt = 'Invoice_${order.orderId}.txt';

    final candidatePaths = <String>[
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
      Directory.systemTemp.path,
    ];

    for (final path in candidatePaths) {
      try {
        final dir = Directory(path);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final htmlFile = File('${dir.path}/$fileNameHtml');
        await htmlFile.writeAsString(html);

        final txtFile = File('${dir.path}/$fileNameTxt');
        await txtFile.writeAsString(txt);

        return htmlFile;
      } catch (_) {
        // Continue to fallback path
      }
    }

    try {
      final fallbackFile = File('${Directory.systemTemp.path}/$fileNameHtml');
      await fallbackFile.writeAsString(html);
      return fallbackFile;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstProduct = order.items.isNotEmpty ? order.items.first.product : null;
    final itemsSubtotal = order.items.fold(0, (sum, i) => sum + (i.product.suggestedPrice * i.quantity));
    final deliveryFee = order.totalAmount > itemsSubtotal ? (order.totalAmount - itemsSubtotal) : 0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F7F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
          ),

          // Top action header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: KalaColors.terracotta, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Artisan Tax Invoice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KalaColors.ink),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Scrollable Invoice Paper
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8E2D8), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x101A1720), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'कला-Connect',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KalaColors.terracotta),
                            ),
                            Text(
                              'Direct Indian Artisan Market',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B6572)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: KalaColors.leaf.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PAID / CONFIRMED',
                            style: TextStyle(color: KalaColors.leaf, fontWeight: FontWeight.w900, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1.2),

                    // Invoice Metadata Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice No: INV-${order.orderId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('Order ID: #${order.orderId}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B6572))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(order.trackingNumber, style: const TextStyle(fontSize: 11, color: KalaColors.indigo, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Artisan & Buyer Cards
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEBE4D8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 16, color: KalaColors.terracotta),
                              const SizedBox(width: 6),
                              Text(
                                'Artisan: ${firstProduct?.artisanName ?? "Master Artisan"} (${firstProduct?.artisanLocation ?? "India"})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KalaColors.ink),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: KalaColors.indigo),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.shippingAddress,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5A5260)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    const Text('ORDER ITEMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF6B6572), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...order.items.map((item) {
                      final lineTotal = item.product.suggestedPrice * item.quantity;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  Text('${item.quantity} x ₹${item.product.suggestedPrice}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Text('₹$lineTotal', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Calculation breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Subtotal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text('₹$itemsSubtotal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('India Post Delivery:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(
                          deliveryFee == 0 ? 'FREE' : '₹$deliveryFee',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: deliveryFee == 0 ? KalaColors.leaf : Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Handloom GST / Cess:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text('₹0.00 (Exempted)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KalaColors.leaf)),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Paid:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: KalaColors.ink)),
                        Text('₹${order.totalAmount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KalaColors.leaf)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Authenticity seal banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: KalaColors.leaf.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: KalaColors.leaf.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 18, color: KalaColors.leaf),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Certified Genuine Indian Craft • 100% Paid Directly to Artisan',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: KalaColors.leaf),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, -4)),
              ],
            ),
            child: Row(
              children: [
                // Copy Receipt Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final text = generatePlainTextInvoice(order);
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Invoice details copied to clipboard!'),
                              ],
                            ),
                            backgroundColor: KalaColors.indigo,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: KalaColors.terracotta, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18, color: KalaColors.terracotta),
                    label: const Text('Copy Invoice', style: TextStyle(fontWeight: FontWeight.w900, color: KalaColors.terracotta, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                // Download Invoice File Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final savedFile = await downloadInvoiceToFile(order);
                      if (context.mounted) {
                        if (savedFile != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invoice downloaded: ${savedFile.path}'),
                              backgroundColor: KalaColors.leaf,
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'Copy Text',
                                textColor: Colors.white,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: generatePlainTextInvoice(order)));
                                },
                              ),
                            ),
                          );
                        } else {
                          // Fallback to clipboard
                          await Clipboard.setData(ClipboardData(text: generatePlainTextInvoice(order)));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invoice copied to clipboard (storage inaccessible).'),
                                backgroundColor: KalaColors.leaf,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: KalaColors.leaf,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
