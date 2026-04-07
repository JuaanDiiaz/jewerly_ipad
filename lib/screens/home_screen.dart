import 'package:flutter/material.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:p_a_jewerly/screens/screens.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<CollapsibleItem> _items;
  late Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    _items = _generateItems;
    _currentWidget = _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diamond_outlined,
            size: 80,
            color: AppTheme.primaryGold,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to P&A Jewelry',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepPurple,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an option from the menu to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.subtleText,
            ),
          ),
        ],
      ),
    );
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
          text: 'Sales',
          icon: Icons.point_of_sale,
          onPressed: () => setState(() {
                _currentWidget = SaleScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'New Sale',
              icon: Icons.add_shopping_cart,
              onPressed: () => setState(() {
                _currentWidget = SaleScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Sales History',
              icon: Icons.history,
              onPressed: () => setState(() {
                _currentWidget = SalesListScreen();
              }),
            ),
          ]),
      CollapsibleItem(
          text: 'Inventory',
          icon: Icons.inventory_2_outlined,
          onPressed: () => setState(() {
                _currentWidget = InventoryMainScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Movements',
              icon: Icons.swap_horiz,
              onPressed: () => setState(() {
                _currentWidget = InventoryMovementsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Physical Count',
              icon: Icons.fact_check_outlined,
              onPressed: () => setState(() {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PhysicalCountMainScreen()));
              }),
            ),
          ]),
      CollapsibleItem(
        text: 'Prices',
        icon: Icons.price_change_outlined,
        onPressed: () => setState(() {
          _currentWidget = PricesMainScreen();
        }),
      ),
      CollapsibleItem(
          text: 'Purchases',
          icon: Icons.shopping_bag_outlined,
          onPressed: () => setState(() {
                _currentWidget = PurchasesMainScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Purchase Orders',
              icon: Icons.receipt_long_outlined,
              onPressed: () => setState(() {
                _currentWidget = PurchasesMainScreen();
              }),
            ),
          ]),
      CollapsibleItem(
          text: 'Customers',
          icon: Icons.people_outline,
          onPressed: () => setState(() {
                _currentWidget = CustomerMainScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Payments',
              icon: Icons.payments_outlined,
              onPressed: () => setState(() {
                _currentWidget = PaymentsScreen();
              }),
            ),
          ]),
      CollapsibleItem(
        text: 'Products',
        icon: Icons.diamond_outlined,
        onPressed: () => setState(() {
          _currentWidget = ProductsMainScreen();
        }),
      ),
      CollapsibleItem(
        text: 'Settings',
        icon: Icons.settings_outlined,
        onPressed: () => setState(() {
          _currentWidget = const SettingsScreen();
        }),
      ),
      CollapsibleItem(
          text: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          onPressed: () => setState(() {
                _currentWidget = const WarehousesScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Warehouses',
              icon: Icons.store_outlined,
              onPressed: () => setState(() {
                _currentWidget = const WarehousesScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Categories',
              icon: Icons.category_outlined,
              onPressed: () => setState(() {
                _currentWidget = const CategoriesScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Payment Methods',
              icon: Icons.credit_card_outlined,
              onPressed: () => setState(() {
                _currentWidget = const PaymentMethodsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Suppliers',
              icon: Icons.business_outlined,
              onPressed: () => setState(() {
                _currentWidget = const SuppliersScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Supplier Products',
              icon: Icons.inventory_outlined,
              onPressed: () => setState(() {
                _currentWidget = const SupplierProductsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Price List Details',
              icon: Icons.attach_money,
              onPressed: () => setState(() {
                _currentWidget = const PriceListDetailsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Sales Tax',
              icon: Icons.percent_outlined,
              onPressed: () => setState(() {
                _currentWidget = const SalesTaxScreen();
              }),
            ),
          ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CollapsibleSidebar(
          isCollapsed: MediaQuery.of(context).size.width <= 800,
          items: _items,
          collapseOnBodyTap: false,
          title: 'P&A Jewelry',
          onTitleTap: () {},
          body: _body(context),
          backgroundColor: AppTheme.deepPurple.withOpacity(0.05),
          selectedTextColor: AppTheme.primaryGold,
          unselectedTextColor: AppTheme.subtleText,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          titleStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGold,
            fontFamily: 'PlayfairDisplay',
          ),
          toggleTitleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGold,
          ),
          sidebarBoxShadow: [
            BoxShadow(
              color: AppTheme.deepPurple.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0.01,
              offset: const Offset(3, 3),
            )
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
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
    );
  }
}