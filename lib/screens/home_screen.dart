import 'package:flutter/material.dart';
import 'package:p_a_jewerly/screens/screens.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/modern_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _currentWidget = const SaleScreen();
  bool _isSidebarCollapsed = false;

  final List<MenuItem> _menuItems = [
    MenuItem(
      title: 'Sales',
      icon: Icons.point_of_sale,
      subItems: [
        MenuItem(
          title: 'New Sale',
          icon: Icons.add_shopping_cart,
          screen: const SaleScreen(),
        ),
        MenuItem(
          title: 'Sales History',
          icon: Icons.history,
          screen: const SalesListScreen(),
        ),
      ],
    ),
    MenuItem(
      title: 'Inventory',
      icon: Icons.inventory_2_outlined,
      subItems: [
        MenuItem(
          title: 'Movements',
          icon: Icons.swap_horiz,
          screen: const InventoryMovementsScreen(),
        ),
        MenuItem(
          title: 'Physical Count',
          icon: Icons.fact_check_outlined,
          screen: const PhysicalCountMainScreen(),
        ),
      ],
    ),
    MenuItem(
      title: 'Prices',
      icon: Icons.price_change_outlined,
      screen: const PricesMainScreen(),
    ),
    MenuItem(
      title: 'Purchases',
      icon: Icons.shopping_bag_outlined,
      screen: const PurchasesMainScreen(),
    ),
    MenuItem(
      title: 'Customers',
      icon: Icons.people_outline,
      subItems: [
        MenuItem(
          title: 'All Customers',
          icon: Icons.person_outline,
          screen: const CustomerMainScreen(),
        ),
        MenuItem(
          title: 'Payments',
          icon: Icons.payments_outlined,
          screen: const PaymentsScreen(),
        ),
      ],
    ),
    MenuItem(
      title: 'Products',
      icon: Icons.diamond_outlined,
      screen: const ProductsMainScreen(),
    ),
    MenuItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      screen: const SettingsScreen(),
    ),
    MenuItem(
      title: 'Admin',
      icon: Icons.admin_panel_settings_outlined,
      subItems: [
        MenuItem(
          title: 'Warehouses',
          icon: Icons.store_outlined,
          screen: const WarehousesScreen(),
        ),
        MenuItem(
          title: 'Categories',
          icon: Icons.category_outlined,
          screen: const CategoriesScreen(),
        ),
        MenuItem(
          title: 'Payment Methods',
          icon: Icons.credit_card_outlined,
          screen: const PaymentMethodsScreen(),
        ),
        MenuItem(
          title: 'Suppliers',
          icon: Icons.business_outlined,
          screen: const SuppliersScreen(),
        ),
        MenuItem(
          title: 'Supplier Products',
          icon: Icons.inventory_outlined,
          screen: const SupplierProductsScreen(),
        ),
        MenuItem(
          title: 'Price Lists',
          icon: Icons.attach_money,
          screen: const PriceListDetailsScreen(),
        ),
        MenuItem(
          title: 'Sales Tax',
          icon: Icons.percent_outlined,
          screen: const SalesTaxScreen(),
        ),
      ],
    ),
  ];

  void _navigateTo(Widget screen) {
    setState(() {
      _currentWidget = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 800;

    return SafeArea(
      child: Scaffold(
        body: Row(
          children: [
            if (isTablet)
              ModernSidebar(
                items: _menuItems,
                title: 'P&A Jewelry',
                subtitle: 'Inventory Management',
                isCollapsed: _isSidebarCollapsed,
                onCollapsedChanged: (collapsed) {
                  setState(() {
                    _isSidebarCollapsed = collapsed;
                  });
                },
                onItemSelected: (screen) {
                  setState(() {
                    _currentWidget = screen;
                  });
                },
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepPurple.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _currentWidget,
                ),
              ),
            ),
          ],
        ),
        drawer: isTablet ? null : _buildDrawer(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGold, AppTheme.secondaryGold],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'P&A Jewelry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay',
                    ),
                  ),
                  Text(
                    'Inventory Management',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ..._buildDrawerItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    final widgets = <Widget>[];
    for (final item in _menuItems) {
      if (item.subItems != null && item.subItems!.isNotEmpty) {
        widgets.add(_buildDrawerExpandable(item));
      } else {
        widgets.add(_buildDrawerItem(item));
      }
    }
    return widgets;
  }

  Widget _buildDrawerItem(MenuItem item) {
    return ListTile(
      leading: Icon(item.icon, color: Colors.white.withOpacity(0.8)),
      title: Text(item.title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        if (item.screen != null) _navigateTo(item.screen!);
      },
    );
  }

  Widget _buildDrawerExpandable(MenuItem item) {
    return ExpansionTile(
      iconColor: Colors.white.withOpacity(0.8),
      textColor: Colors.white,
      leading: Icon(item.icon, color: Colors.white.withOpacity(0.8)),
      title: Text(item.title, style: const TextStyle(color: Colors.white)),
      children: item.subItems!
          .map((sub) => ListTile(
                leading: Icon(sub.icon, color: Colors.white.withOpacity(0.6), size: 20),
                title: Text(sub.title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  if (sub.screen != null) _navigateTo(sub.screen!);
                },
              ))
          .toList(),
    );
  }
}