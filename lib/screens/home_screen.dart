import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/providers.dart';
import 'package:p_a_jewerly/screens/screens.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/modern_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSidebarCollapsed = false;

  /// Fades the content pane in on every screen swap: IndexedStack keeps all
  /// visited screens alive, so the widget tree never changes identity when the
  /// selection moves — the fade is what makes the swap perceptible.
  late final AnimationController _paneFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _paneFadeIn =
      CurvedAnimation(parent: _paneFade, curve: Curves.easeOut);
  // Lazy IndexedStack: the active screen keeps its state when navigating away
  // (search text, scroll position, tabs). Unvisited screens are only built
  // the first time they are selected.
  final Set<int> _visitedScreens = {0};
  int _selectedScreenIndex = 0;

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
      title: 'Reports',
      icon: Icons.assessment_outlined,
      screen: const ReportsMainScreen(),
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

  /// Flat list of screens, in a stable order, one per navigable menu leaf.
  List<Widget> get _screens {
    final screens = <Widget>[];
    for (final item in _menuItems) {
      if (item.subItems != null && item.subItems!.isNotEmpty) {
        for (final sub in item.subItems!) {
          if (sub.screen != null) screens.add(sub.screen!);
        }
      } else if (item.screen != null) {
        screens.add(item.screen!);
      }
    }
    return screens;
  }

  void _navigateTo(Widget screen) {
    final index = _screens.indexWhere((s) => s.runtimeType == screen.runtimeType);
    if (index == -1) return;
    setState(() {
      _selectedScreenIndex = index;
      _visitedScreens.add(index);
    });
    _paneFade.forward(from: 0);
    _refreshOnNavigate(index);
  }

  /// Data freshness on navigation, without remounting the screen: indexes
  /// map to the fetches their screen's initState performs, and each provider
  /// skips the work when its data is fresh (<60s old). Fetches are silent
  /// over existing data (spinner only when the list is empty), so switching
  /// screens never blanks what was already on view.
  void _refreshOnNavigate(int index) {
    // Staleness-gated refetches; provider fetches are silent no-ops over
    // fresh data, so this is cheap on rapid menu switching.
    switch (index) {
      case 0: // New Sale (POS) — current products, stock, debt, methods
        final sales = context.read<SalesProvider>();
        final products = context.read<ProductProvider>();
        final inventory = context.read<InventoryProvider>();
        final customers = context.read<CustomerProvider>();
        final warehouses = context.read<WarehouseProvider>();
        final methods = context.read<PaymentMethodProvider>();
        final payments = context.read<CustomerPaymentProvider>();
        final images = context.read<ProductImageProvider>();
        if (products.isStale) products.fetchProducts(fetchAll: true);
        if (inventory.isStale) inventory.fetchInventory();
        if (customers.isStale) customers.fetchCustomers(fetchAll: true);
        if (warehouses.isStale) warehouses.fetchWarehouses();
        if (methods.isStale) methods.fetchPaymentMethods();
        if (payments.isStale) payments.fetchPayments();
        if (sales.isStale) sales.fetchSales();
        if (images.isStale) images.fetchAllImages();
        break;
      case 1: // Sales History
        final sales = context.read<SalesProvider>();
        if (sales.isStale) sales.fetchSales();
        break;
      case 2: // Inventory Movements
        final inventory = context.read<InventoryProvider>();
        if (inventory.isStale) inventory.fetchMovements();
        break;
      case 3: // Physical Count
        final products = context.read<ProductProvider>();
        final warehouses = context.read<WarehouseProvider>();
        if (products.isStale) products.fetchProducts(fetchAll: true);
        if (warehouses.isStale) warehouses.fetchWarehouses();
        break;
      case 4: // Prices
        final details = context.read<PriceListDetailProvider>();
        if (details.isStale) details.fetchPriceListDetails();
        break;
      case 5: // Purchases
        final purchases = context.read<PurchaseOrderProvider>();
        if (purchases.isStale) purchases.fetchOrders();
        break;
      case 6: // All Customers
        final customers = context.read<CustomerProvider>();
        if (customers.isStale) customers.fetchCustomers();
        break;
      case 7: // Payments
        final payments = context.read<CustomerPaymentProvider>();
        final sales = context.read<SalesProvider>();
        if (payments.isStale) payments.fetchPayments();
        if (sales.isStale) sales.fetchSales(fetchAll: true);
        break;
      case 8: // Products
        final products = context.read<ProductProvider>();
        if (products.isStale) products.fetchProducts();
        break;
      case 9: // Reports — refreshes via its own controls (see refresh button)
      case 10: // Settings — nothing to fetch
        break;
      case 11: // Admin / Warehouses
        final warehouses = context.read<WarehouseProvider>();
        if (warehouses.isStale) warehouses.fetchWarehouses();
        break;
      case 12: // Admin / Categories
        final categories = context.read<CategoryProvider>();
        if (categories.isStale) categories.fetchCategories();
        break;
      case 13: // Admin / Payment Methods
        final methods = context.read<PaymentMethodProvider>();
        if (methods.isStale) methods.fetchPaymentMethods();
        break;
      case 14: // Admin / Suppliers
        final suppliers = context.read<SupplierProvider>();
        if (suppliers.isStale) suppliers.fetchSuppliers();
        break;
      case 15: // Admin / Supplier Products
        final supplierProducts = context.read<SupplierProductProvider>();
        if (supplierProducts.isStale) supplierProducts.fetchSupplierProducts();
        break;
      case 16: // Admin / Price Lists
        final details = context.read<PriceListDetailProvider>();
        if (details.isStale) details.fetchPriceListDetails();
        break;
      case 17: // Admin / Sales Tax
        final tax = context.read<SalesTaxProvider>();
        if (tax.isStale) tax.fetchSalesTaxes();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _paneFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > AppBreakpoints.wideChromeAt;
    // Watching the theme mode guarantees this builder re-runs (and the screen
    // keys below change) whenever System/Light/Dark flips — even while the
    // mode comes from the platform in System mode.
    final themeMode = context.watch<ThemeProvider>().mode;

    return SafeArea(
      child: Scaffold(
        // Narrow screens have no sidebar: the drawer is reachable from this bar.
        appBar: isTablet
            ? null
            : AppBar(
                title: const Text('P&A Jewelry'),
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
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
                onItemSelected: (screen) => _navigateTo(screen),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
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
                  // Screens not yet visited are skipped so they don't fetch on
                  // app start; each visited page keeps its state afterwards.
                  //
                  // Every kept-alive screen is wrapped in a KeyedSubtree whose
                  // key includes the theme mode: the menu screens are const
                  // (shared instances), so without the key they'd stay in
                  // their old palette after a System/Light/Dark switch instead
                  // of rebuilding — the root cause of the mixed-theme bug.
                  child: FadeTransition(
                    opacity: _paneFadeIn,
                    child: IndexedStack(
                      index: _selectedScreenIndex,
                      children: [
                        for (var i = 0; i < _screens.length; i++)
                          _visitedScreens.contains(i)
                              ? KeyedSubtree(
                                  key: ValueKey('screen-$i-${themeMode.name}'),
                                  child: _screens[i],
                                )
                              : const SizedBox.shrink(),
                      ],
                    ),
                  ),
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