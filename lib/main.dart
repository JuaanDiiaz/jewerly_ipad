import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/config/environment.dart';
import 'package:p_a_jewerly/providers/providers.dart';
import 'package:p_a_jewerly/screens/screens.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');
  Environment.initialize();

  // Load cached API URL from shared_preferences before app starts
  await Environment.refreshBaseUrl();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => ApiConfigProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductImageProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProductProvider()),
        ChangeNotifierProvider(create: (_) => PriceListProvider()),
        ChangeNotifierProvider(create: (_) => PriceListDetailProvider()),
        ChangeNotifierProvider(create: (_) => SalesTaxProvider()),
        ChangeNotifierProvider(create: (_) => CustomerPaymentProvider()),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'P&A Jewelry',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
