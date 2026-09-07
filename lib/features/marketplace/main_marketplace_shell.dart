import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart_and_orders_controller.dart';
import '../../state/locale_controller.dart';
import '../../theme/kala_theme.dart';
import '../ai_studio/ai_product_creator_screen.dart';
import '../profile/marketplace_profile_screen.dart';
import 'cart_and_orders_screen.dart';
import 'categories_explorer_screen.dart';
import 'marketplace_home_screen.dart';

class MainMarketplaceShell extends StatefulWidget {
  const MainMarketplaceShell({this.initialTabIndex = 0, super.key});

  final int initialTabIndex;

  static void openStudio(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const AiProductCreatorScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<MainMarketplaceShell> createState() => _MainMarketplaceShellState();
}

class _MainMarketplaceShellState extends State<MainMarketplaceShell> {
  late int _currentIndex = widget.initialTabIndex;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartAndOrdersController>();
    final loc = context.watch<LocaleController>();

    final screens = <Widget>[
      MarketplaceHomeScreen(
        onOpenStudio: () => MainMarketplaceShell.openStudio(context),
        onOpenCart: () => _switchTab(2),
        onOpenProfile: () => _switchTab(3),
      ),
      const CategoriesExplorerScreen(),
      const CartAndOrdersScreen(),
      MarketplaceProfileScreen(
        onOpenStudio: () => MainMarketplaceShell.openStudio(context),
        onOpenOrders: () => _switchTab(2),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _switchTab,
            backgroundColor: Colors.white,
            indicatorColor: KalaColors.terracotta.withValues(alpha: 0.18),
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded, color: KalaColors.terracotta),
                label: loc.tr('tab_shop'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.category_outlined),
                selectedIcon: const Icon(Icons.category_rounded, color: KalaColors.terracotta),
                label: loc.tr('tab_categories'),
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  label: Text('${cart.totalItemCount}'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  label: Text('${cart.totalItemCount}'),
                  child: const Icon(Icons.shopping_bag_rounded, color: KalaColors.terracotta),
                ),
                label: loc.tr('tab_cart_orders'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded, color: KalaColors.terracotta),
                label: loc.tr('tab_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
