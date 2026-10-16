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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// Tracks the device's light/dark switch so Theme mode "system" follows it
/// live (AppTheme's static flag must be re-synced even while mode is system).
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Created once here so the brightness observer can reach it directly:
  // State.context sits above MultiProvider, so Provider.of would throw.
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _themeProvider.updatePlatformBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
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
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      // builder gives a context *below* the providers — watching MyApp's own
      // build context would throw ProviderNotFoundException.
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'P&A Jewelry',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: context.watch<ThemeProvider>().mode,
        home: child,
      ),
      child: const HomeScreen(),
    );
  }
}
