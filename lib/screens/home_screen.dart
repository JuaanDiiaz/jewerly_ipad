import 'package:flutter/material.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:p_a_jewerly/screens/screens.dart';

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
    _currentWidget = Center(
      child: Text('Inicio'),
    );
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
          text: 'Sales',
          icon: Icons.assessment,
          onPressed: () => setState(() {
                _currentWidget = Center(child: Text('Sale'));
              }),
          isSelected: true,
          subItems: [
            CollapsibleItem(
              text: 'New sale',
              icon: Icons.add,
              onPressed: () => setState(() {
                _currentWidget = SaleScreen();
              }),
              isSelected: true,
            ),
            CollapsibleItem(
              text: 'Sales list',
              icon: Icons.list,
              onPressed: () => setState(() {
                _currentWidget = Center(child: Text('Sales list'));
              }),
              isSelected: true,
            ),
          ]),
      CollapsibleItem(
          text: 'Inventory',
          icon: Icons.list_alt_sharp,
          onPressed: () => setState(() {
                _currentWidget = InventoryMainScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Movements',
              icon: Icons.directions,
              onPressed: () => setState(() {
                _currentWidget = InventoryMovementsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Physical count',
              icon: Icons.list_rounded,
              onPressed: () => setState(() {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PhysicalCountMainScreen()));
              }),
            ),
          ]),
      CollapsibleItem(
        text: 'Prices',
        icon: Icons.money,
        onPressed: () => setState(() {
          _currentWidget = PricesMainScreen();
        }),
      ),
      CollapsibleItem(
          text: 'Purchases',
          icon: Icons.shopping_cart,
          onPressed: () => setState(() {
                _currentWidget = PurchasesMainScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Purchase orders',
              icon: Icons.edit_document,
              onPressed: () => setState(() {
                _currentWidget = PurchasesMainScreen();
              }),
            ),
          ]),
      CollapsibleItem(
          text: 'Customers',
          icon: Icons.person_2,
          onPressed: () => setState(() {
                _currentWidget = CustomerMainScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Payments',
              icon: Icons.money_sharp,
              onPressed: () => setState(() {
                _currentWidget = CustomerPaymentsScreen();
              }),
            ),
          ]),
      CollapsibleItem(
        text: 'Products',
        icon: Icons.article,
        onPressed: () => setState(() {
          _currentWidget = ProductsMainScreen();
        }),
      ),
      CollapsibleItem(
        text: 'Settings',
        icon: Icons.settings,
        onPressed: () => setState(() {
          _currentWidget = const SettingsScreen();
        }),
        onHold: () => setState(() {
          _currentWidget = const SettingsScreen();
        }),
      ),
      CollapsibleItem(
          text: 'Admin',
          icon: Icons.admin_panel_settings,
          onPressed: () => setState(() {
                _currentWidget = const WarehousesScreen();
              }),
          subItems: [
            CollapsibleItem(
              text: 'Warehouses',
              icon: Icons.store,
              onPressed: () => setState(() {
                _currentWidget = const WarehousesScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Categories',
              icon: Icons.category,
              onPressed: () => setState(() {
                _currentWidget = const CategoriesScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Payment Methods',
              icon: Icons.payment,
              onPressed: () => setState(() {
                _currentWidget = const PaymentMethodsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Suppliers',
              icon: Icons.business,
              onPressed: () => setState(() {
                _currentWidget = const SuppliersScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Supplier Products',
              icon: Icons.production_quantity_limits,
              onPressed: () => setState(() {
                _currentWidget = const SupplierProductsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Price List Details',
              icon: Icons.price_check,
              onPressed: () => setState(() {
                _currentWidget = const PriceListDetailsScreen();
              }),
            ),
            CollapsibleItem(
              text: 'Sales Tax',
              icon: Icons.percent,
              onPressed: () => setState(() {
                _currentWidget = const SalesTaxScreen();
              }),
            ),
          ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: CollapsibleSidebar(
          isCollapsed: MediaQuery.of(context).size.width <= 800,
          items: _items,
          collapseOnBodyTap: false,
          title: 'P&A Jewerly',
          onTitleTap: () {},
          body: _body(size, context),
          backgroundColor: Colors.black12,
          selectedTextColor: Colors.blueAccent,
          unselectedTextColor: Colors.black26,
          textStyle: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          titleStyle: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
          toggleTitleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          sidebarBoxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              spreadRadius: 0.01,
              offset: Offset(3, 3),
            )
          ],
        ),
      ),
    );
  }

  Widget _body(Size size, BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      margin: EdgeInsets.all(20),
      child: _currentWidget,
    );
  }
}
