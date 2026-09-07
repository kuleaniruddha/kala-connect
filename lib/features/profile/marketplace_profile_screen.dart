import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/profile/artisan_follow_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_and_orders_controller.dart';
import '../../state/locale_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';
import '../artisan/join_artist_flow.dart';
import '../auth/email_auth_dialog.dart';
import '../product/my_products_screen.dart';

class MarketplaceProfileScreen extends StatelessWidget {
  const MarketplaceProfileScreen({
    required this.onOpenStudio,
    required this.onOpenOrders,
    super.key,
  });

  final VoidCallback onOpenStudio;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final flow = context.watch<AppFlowController>();
    final cart = context.watch<CartAndOrdersController>();
    final loc = context.watch<LocaleController>();
    final profile = flow.profile;
    final isArtisan = profile?.isArtisan ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(loc.tr('profile_title'), style: const TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)),
      ),
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Identity Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: auth.isSignedIn
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: KalaColors.terracotta,
                              child: Text(
                                (auth.identity?.displayName ?? profile?.name ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.identity?.displayName ?? profile?.name ?? 'Kala Connect User',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    auth.identity?.email ?? auth.identity?.phoneNumber ?? 'Verified User',
                                    style: const TextStyle(color: Color(0xFF6B6572), fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isArtisan ? KalaColors.leaf.withValues(alpha: 0.12) : KalaColors.indigo.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isArtisan ? Icons.verified_rounded : Icons.shopping_bag_outlined,
                                          size: 13,
                                          color: isArtisan ? KalaColors.leaf : KalaColors.indigo,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isArtisan ? loc.tr('verified_artisan') : loc.tr('patron_buyer'),
                                          style: TextStyle(
                                            color: isArtisan ? KalaColors.leaf : KalaColors.indigo,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle_outlined, size: 40, color: KalaColors.terracotta),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.tr('sign_in_title'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                                      Text(loc.tr('sign_in_sub'), style: const TextStyle(fontSize: 12, color: Color(0xFF6B6572))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => EmailAuthDialog.show(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: KalaColors.terracotta,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: Text(loc.tr('sign_in_title'), style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 22),

                // Artisan Hub or Become an Artisan
                if (isArtisan) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KalaColors.ivory,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: KalaColors.terracotta.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.store_rounded, color: KalaColors.leaf, size: 22),
                            const SizedBox(width: 8),
                            Text(loc.tr('artisan_hub'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionTile(
                                icon: Icons.inventory_2_outlined,
                                color: KalaColors.terracotta,
                                title: loc.tr('my_catalog'),
                                subtitle: 'Manage Listings',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const MyProductsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionTile(
                                icon: Icons.auto_awesome_rounded,
                                color: KalaColors.indigo,
                                title: loc.tr('open_studio'),
                                subtitle: 'List New Craft',
                                onTap: onOpenStudio,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ] else ...[
                  // Register as an Artisan Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E1C38), Color(0xFF5B3045)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: KalaColors.turmeric.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.handyman_rounded, color: KalaColors.turmeric, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('join_artisan'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  const Text(
                                    'Sell directly to patrons nationwide',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loc.tr('join_artisan_sub'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () {
                            if (!auth.isSignedIn) {
                              EmailAuthDialog.show(context);
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const JoinArtistFlow(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: KalaColors.terracotta,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.app_registration_rounded, size: 18),
                          label: const Text('Register as an Artisan / कारीगर पंजीकरण', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // Buyer Orders & Activity
                Text(loc.tr('my_orders'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: KalaColors.ink)),
                const SizedBox(height: 12),
                _buildMenuRow(
                  icon: Icons.local_shipping_outlined,
                  title: '${loc.tr('my_orders')} (${cart.orders.length})',
                  subtitle: loc.tr('track_delivery_sub'),
                  onTap: onOpenOrders,
                ),

                // Artisans you follow
                if (auth.isSignedIn) ...[
                  StreamBuilder<int>(
                    stream: context.read<ArtisanFollowRepository>().watchFollowingCount(userId: auth.identity!.uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildMenuRow(
                        icon: Icons.people_outline_rounded,
                        title: '${loc.tr('artisans_you_follow')} ($count)',
                        subtitle: loc.tr('artisans_follow_sub'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${loc.tr('artisans_you_follow')}: $count'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                // Account Security / Password Reset
                if (auth.isSignedIn && auth.identity?.email != null && auth.identity!.email!.isNotEmpty) ...[
                  _buildMenuRow(
                    icon: Icons.lock_reset_rounded,
                    title: loc.tr('reset_password'),
                    subtitle: '${loc.tr('reset_password_sub')} ${auth.identity!.email}',
                    onTap: () async {
                      final email = auth.identity!.email!;
                      final success = await auth.sendPasswordReset(email);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '${loc.tr('reset_password_sent')} $email'
                                : (auth.message ?? loc.tr('reset_password_failed')),
                          ),
                          backgroundColor: success ? KalaColors.leaf : Colors.red,
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Language Section
                Text(loc.tr('app_language'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppLocalizations.supportedLanguages.map((lang) {
                    final isSelected = loc.languageCode == lang['code'];
                    return ChoiceChip(
                      label: Text(
                        '${lang['name']} (${lang['englishName']})',
                        style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        loc.setLanguage(lang['code']!);
                        flow.changeLanguage(lang['code']!);
                      },
                      selectedColor: KalaColors.terracotta,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : KalaColors.ink),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  }).toList(),
                ),

                if (auth.isSignedIn) ...[
                  const SizedBox(height: 30),
                  OutlinedButton.icon(
                    onPressed: () => auth.signOut(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: Text(loc.tr('sign_out'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: KalaColors.terracotta.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KalaColors.terracotta, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
      ),
    );
  }
}
