import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/sales_provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/inventory_provider.dart';
import 'package:p_a_jewerly/providers/price_list_provider.dart';
import 'package:p_a_jewerly/providers/price_list_detail_provider.dart';
import 'package:p_a_jewerly/providers/payment_method_provider.dart';
import 'package:p_a_jewerly/providers/warehouse_provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/providers/tax_rate_provider.dart';
import 'package:p_a_jewerly/providers/product_category_provider.dart';
import 'package:p_a_jewerly/models/inventory_model.dart';
import 'package:p_a_jewerly/models/price_list_model.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/utils/format.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/widgets/picked_image.dart';
import 'package:p_a_jewerly/screens/Sales/cart_panel.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final salesProvider = context.read<SalesProvider>();
      context.read<ProductProvider>().fetchProducts(fetchAll: true);
      context.read<CustomerProvider>().fetchCustomers(fetchAll: true);
      context.read<InventoryProvider>().fetchInventory();
      context.read<PriceListDetailProvider>().fetchPriceListDetails();
      context.read<PaymentMethodProvider>().fetchPaymentMethods();
      context.read<ProductImageProvider>().fetchAllImages();
      // Tax preview inputs (rates + per-product category links): without
      // these the rail's Total silently shows the pre-tax subtotal.
      context.read<TaxRateProvider>().fetchTaxRates();
      context.read<ProductCategoryProvider>().fetchProductCategories();
      // Preselect warehouse + price list: the grid used to stay blank and
      // the register unpriced until these were picked from inside the cart
      // panel — both dead ends now resolve on open (fallbacks remain for a
      // warehouse-less backend).
      final warehouseProvider = context.read<WarehouseProvider>();
      await warehouseProvider.fetchWarehouses();
      if (!mounted) return;
      if (salesProvider.selectedWarehouseId == null &&
          warehouseProvider.warehouses.isNotEmpty) {
        salesProvider.setWarehouse(warehouseProvider.warehouses.first.id);
      }
      final priceListProvider = context.read<PriceListProvider>();
      await priceListProvider.fetchPriceLists();
      if (!mounted) return;
      if (salesProvider.selectedPriceListId == null &&
          priceListProvider.priceLists.isNotEmpty) {
        salesProvider.setSelectedPriceList(priceListProvider.priceLists.first.id);
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(dynamic product, double price, {int maxQuantity = 0}) {
    final salesProvider = context.read<SalesProvider>();

    if (price <= 0) {
      // Never add at a made-up $0.00 — that bug is what killed the old grid
      // quick-add. Quick-add only fires when the selected list prices the
      // product; the long-press detail sheet offers every list's prices.
      ScaffoldMessenger.of(context).showSnackBar(
        warningSnackBar(
            'No price in this list for ${product.description ?? 'this product'} — long-press the product to pick one'),
      );
      return;
    }

    // Get existing cart quantity for this product
    final existingCartItem = salesProvider.cart.where((i) => i.productId == product.id).firstOrNull;
    final existingQty = existingCartItem?.quantity ?? 0;

    // Check if trying to add more than available
    if (maxQuantity > 0 && existingQty >= maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        warningSnackBar("No more stock available for ${product.description ?? 'Product'}"),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    // Cart tiles render a thumbnail; keep the same image the grid showed.
    final imageProvider = context.read<ProductImageProvider>();
    final productImages = imageProvider.getImagesForProduct(product.id);
    final imageUrl = product.picture ??
        (productImages.isNotEmpty ? productImages.first.imageUrl : null);

    salesProvider.addToCart(CartItem(
      productId: product.id,
      productName: product.description ?? 'Product ${product.id}',
      quantity: 1,
      unitPrice: price,
      imageUrl: imageUrl,
      maxQuantity: maxQuantity,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar("${product.description ?? 'Product'} added to cart"),
    );
  }

  /// Price-list switch from the cart rail: prices are client-supplied per
  /// list, so the switch reprices every cart line the new list has a row for
  /// (lines with no row in the new list keep their price). The same merge in
  /// SalesProvider.addToCart also lets a long-press add from another list's
  /// sheet row reprice an existing line explicitly.
  void _onPriceListSwitch(int? priceListId) {
    final salesProvider = context.read<SalesProvider>();
    salesProvider.setSelectedPriceList(priceListId);
    if (priceListId == null) return;
    final priceDetailProvider = context.read<PriceListDetailProvider>();
    for (final item in salesProvider.cart) {
      final price = priceDetailProvider.priceFor(item.productId, priceListId);
      if (price != null && price > 0 && price != item.unitPrice) {
        salesProvider.updateCartItemPrice(item.productId, price);
      }
    }
  }

  void _showProductDetails(dynamic product, InventoryModel? inventory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Image Carousel
                _buildProductImageCarousel(product),
                const SizedBox(height: 24),
                _buildDetailRow('ID', '#${product.id}'),
                _buildDetailRow('Description', product.description ?? 'N/A'),
                _buildDetailRow(
                  'Weight',
                  inventory?.weight != null ? '${inventory!.weight} g' : 'Not specified',
                ),
                _buildDetailRow(
                  'Location',
                  inventory?.location ?? 'Not specified',
                ),
                _buildDetailRow(
                  'Warehouse',
                  inventory?.warehouseId != null ? 'WH #${inventory!.warehouseId}' : 'Not assigned',
                ),
                const SizedBox(height: 24),
                Consumer2<PriceListProvider, PriceListDetailProvider>(
                  builder: (context, priceListProvider, priceDetailProvider, _) {
                    final productPrices = priceDetailProvider.priceListDetails
                        .where((d) => d.productId == product.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (productPrices.isEmpty)
                          Text(
                            'No prices available for this product',
                            style: TextStyle(color: AppTheme.mutedText, fontStyle: FontStyle.italic),
                          )
                        else
                          ...productPrices.map((priceDetail) {
                            final priceList = priceListProvider.priceLists
                                .firstWhere((pl) => pl.id == priceDetail.priceListId, orElse: () => PriceListModel(id: 0, description: 'Unknown'));
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '\$${priceDetail.price?.toStringAsFixed(2) ?? "N/A"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                subtitle: Text(priceList.description),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_shopping_cart, color: AppTheme.success),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _addToCart(
                                      product,
                                      (priceDetail.price ?? 0).toDouble(),
                                      maxQuantity: inventory?.quantity ?? 0,
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImageCarousel(dynamic product) {
    final imageProvider = context.watch<ProductImageProvider>();
    final productImages = imageProvider.getImagesForProduct(product.id);
    final allImages = <String>[];

    // Add primary image first
    if (product.picture != null && product.picture.isNotEmpty) {
      allImages.add(product.picture);
    }
    // Add additional images
    for (final img in productImages) {
      if (img.imageUrl.isNotEmpty && !allImages.contains(img.imageUrl)) {
        allImages.add(img.imageUrl);
      }
    }

    if (allImages.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.hairline,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(Icons.shopping_bag, size: 80, color: AppTheme.warning),
        ),
      );
    }

    return _ProductImageCarousel(images: allImages);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.mutedText, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showSummary() {
    if (context.read<SalesProvider>().cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add items before checkout.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SalesProvider>(
          builder: (context, salesProvider, _) {
            return DraggableScrollableSheet(
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sale Summary',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Customer', _getCustomerName(salesProvider.selectedCustomerId)),
                        _buildSummaryRow('Salesperson', salesProvider.salespersonName ?? 'Not specified'),
                        _buildSummaryRow('Payment Method', _getPaymentMethodName(salesProvider.paymentMethodId)),
                        const SizedBox(height: 16),
                        const Text(
                          'Cart Items:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...salesProvider.cart.map((item) => Card(
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text('${formatCurrency(item.unitPrice)} x ${item.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${formatCurrency(item.total)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_shopping_cart, color: AppTheme.error),
                                  onPressed: () => salesProvider.removeFromCart(item.productId),
                                ),
                              ],
                            ),
                          ),
                        )),
                        const Divider(height: 24),
                        ...buildTaxRows(cartTaxBreakdown(context, salesProvider),
                            totalLabelWithTax: true),
                        const SizedBox(height: 20),
                        Consumer<SalesProvider>(
                          builder: (context, provider, _) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : _processCheckout,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Checkout', style: TextStyle(fontSize: 16)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getCustomerName(int? customerId) {
    if (customerId == null) return 'Not selected';
    final customerProvider = context.read<CustomerProvider>();
    try {
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == customerId,
      );
      return customer.name;
    } catch (_) {
      return 'Customer #$customerId';
    }
  }

  String _getPaymentMethodName(int? methodId) {
    if (methodId == null) return 'Not selected';
    final pmProvider = context.read<PaymentMethodProvider>();
    try {
      final method = pmProvider.paymentMethods.firstWhere((m) => m.id == methodId);
      return method.description ?? 'Method #$methodId';
    } catch (_) {
      return 'Method #$methodId';
    }
  }

  Future<void> _processCheckout() async {
    final salesProvider = context.read<SalesProvider>();

    if (salesProvider.selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a customer'),
      );
      return;
    }

    if (salesProvider.paymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a payment method'),
      );
      return;
    }

    if (salesProvider.selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar('Please select a warehouse'),
      );
      return;
    }

    final success = await salesProvider.checkout();

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      // CompleteSale decrements stock server-side — refetch so the product
      // grid and "N available" labels reflect it immediately.
      context.read<InventoryProvider>().fetchInventory();
      // Close every sheet this checkout was reached through: the compact flow
      // stacks the summary sheet over the cart sheet, the expanded flow has
      // just the summary sheet.
      Navigator.of(context).popUntil((route) => route is! ModalBottomSheetRoute);
      ScaffoldMessenger.of(context).showSnackBar(
        successSnackBar('Sale completed successfully!'),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(salesProvider.error ?? 'Failed to complete sale'),
      );
    }
  }

  List<dynamic> _filterProducts(List<dynamic> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((product) {
      final description = (product.description ?? '').toLowerCase();
      final id = product.id.toString();
      return description.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > AppBreakpoints.posRailAt;

    return Form(
      key: _formKey,
      child: Container(
        color: AppTheme.background,
        child: Column(
          children: [
            // Header with search and filters
            _buildHeader(),
            // Main content - split view for tablets
            Expanded(
              child: isTablet
                  ? Row(
                      children: [
                        // Products grid
                        Expanded(
                          child: _buildProductsGrid(),
                        ),
                        // Cart rail - 35% width, min 300, max 400
                        Container(
                          width: screenWidth * 0.35,
                          constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: CartPanel(
                            onCheckout: _showSummary,
                            onPriceListChanged: _onPriceListSwitch,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildProductsGrid()),
                        _buildBottomBar(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'New Sale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuickStats(),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products by name or ID...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, _) {
        if (salesProvider.cart.isEmpty) return const SizedBox.shrink();
        return Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${salesProvider.cart.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${salesProvider.cartTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return Consumer4<SalesProvider, ProductProvider, InventoryProvider, PriceListDetailProvider>(
      builder: (context, salesProvider, productProvider, inventoryProvider, priceDetailProvider, _) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
        }
        if (productProvider.error != null) {
          return _buildErrorState(productProvider.error!, () => productProvider.fetchProducts());
        }
        if (productProvider.products.isEmpty) {
          return _buildEmptyState();
        }

        final filteredProducts = _filterProducts(productProvider.products);
        final inventoryMap = <int, InventoryModel>{};
        for (final inv in inventoryProvider.inventory) {
          if (inv.productId != null && inv.warehouseId == salesProvider.selectedWarehouseId) {
            inventoryMap[inv.productId!] = inv;
          }
        }

        final productsWithInventory = filteredProducts.where((p) {
          final inv = inventoryMap[p.id];
          return inv != null && (inv.quantity ?? 0) > 0;
        }).toList();

        if (productsWithInventory.isEmpty) {
          // Distinguish "picked a warehouse and nothing is in stock" from
          // "no warehouse picked yet" — the filter is a no-op without one.
          final noWarehouse = salesProvider.selectedWarehouseId == null;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  noWarehouse ? Icons.warehouse_outlined : Icons.inventory_2_outlined,
                  size: 64,
                  color: AppTheme.mutedText,
                ),
                const SizedBox(height: 16),
                Text(
                  noWarehouse
                      ? 'Select a warehouse to see available products'
                      : filteredProducts.isEmpty
                          ? 'No products found for "$_searchQuery"'
                          : 'No products in stock in this warehouse',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedText),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          // Pull-to-refresh covers stock changes made anywhere else (purchases,
          // manual inventory adjustments, another device).
          onRefresh: () => Future.wait([
            inventoryProvider.fetchInventory(),
            productProvider.fetchProducts(),
          ]),
          child: LayoutBuilder(
            // Column count from the actual grid width, not the screen: beside
            // the cart rail the grid is narrower than the window, and the
            // rail's width flexes with the window.
            builder: (context, constraints) {
              final crossAxisCount = (constraints.maxWidth / 240).floor().clamp(1, 5);
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: productsWithInventory.length,
                itemBuilder: (context, index) {
                  final product = productsWithInventory[index];
                  final inventory = inventoryMap[product.id];
                  // The tile advertises the REGISTER price: the selected
                  // price list's valid row, not the cheapest of all lists
                  // (which misled when the sale wasn't that list's).
                  final currentPriceDetail = priceDetailProvider.detailFor(
                      product.id, salesProvider.selectedPriceListId);
                  final currentPrice = currentPriceDetail?.price?.toDouble();
                  final imageProvider = context.read<ProductImageProvider>();
                  final productImages = imageProvider.getImagesForProduct(product.id);
                  final imageUrl = product.picture ??
                      (productImages.isNotEmpty ? productImages.first.imageUrl : null);

                  return _ProductCard(
                    product: product,
                    inventory: inventory,
                    currentPrice: currentPrice,
                    imageUrl: imageUrl,
                    onQuickAdd: () => _addToCart(
                      product,
                      currentPrice ?? 0,
                      maxQuantity: inventory?.quantity ?? 0,
                    ),
                    onShowDetails: () => _showProductDetails(product, inventory),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Compact layout: the cart panel normally lives in the side rail, which
  /// payment, salesperson, checkout) normally lives in the side rail, which
  /// portrait phones/small tablets don't show — surface it as a tall bottom
  /// sheet. Available even with an empty cart: the warehouse must be
  /// selectable before the first item is added, and product availability is
  /// warehouse-dependent.
  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.heightOf(sheetContext) * 0.85,
        child: CartPanel(
          onCheckout: _showSummary,
          onPriceListChanged: _onPriceListSwitch,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Consumer<SalesProvider>(
          builder: (context, salesProvider, _) {
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    // Always enabled in compact mode: the cart sheet is the
                    // only way to reach the warehouse selector here (product
                    // stock is warehouse-dependent), so an empty cart must
                    // still open it.
                    onPressed: _showCartSheet,
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      salesProvider.cart.isEmpty
                          ? 'Open cart - select warehouse'
                          : '${salesProvider.cart.length} items - ${formatCurrency(salesProvider.cartTotal)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    // Same cart panel as the button: the person-add shortcut
                    // used to open a separate customer/payment sheet — the
                    // CartPanel covers those selectors now.
                    onPressed: _showCartSheet,
                    icon: const Icon(Icons.manage_accounts, color: AppTheme.deepPurple),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.mutedText),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: TextStyle(fontSize: 18, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppTheme.mutedText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

}

class _ProductCard extends StatefulWidget {
  final dynamic product;
  final InventoryModel? inventory;

  /// The selected price list's current price (validity-filtered); null when
  /// the list has no valid row — the tile is dimmed and quick-add is refused
  /// by [_SaleScreenState._addToCart] rather than adding at a made-up $0.00.
  final double? currentPrice;
  final String? imageUrl;

  /// Tap anywhere on the tile: add one unit at [currentPrice].
  final VoidCallback onQuickAdd;

  /// Long-press: the full detail sheet (carousel, every list's price rows).
  final VoidCallback onShowDetails;

  const _ProductCard({
    required this.product,
    this.inventory,
    this.currentPrice,
    this.imageUrl,
    required this.onQuickAdd,
    required this.onShowDetails,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasPrice = widget.currentPrice != null && widget.currentPrice! > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onQuickAdd,
      onLongPress: widget.onShowDetails,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        // Dim tiles the selected list can't price so "why won't it add?"
        // answers itself at a glance.
        opacity: hasPrice ? 1.0 : 0.5,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        child: Card(
          elevation: _isPressed ? 2 : 4,
          shadowColor: AppTheme.deepPurple.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                    // Price badge: the selected list's current price — the
                    // same figure the tap-add will use (no $0.00 adds, ever).
                    if (hasPrice)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryGold, AppTheme.secondaryGold],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${formatCurrency(widget.currentPrice!)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    // Stock badge
                    if (widget.inventory?.quantity != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Stock: ${widget.inventory!.quantity}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info section
              Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.description ?? 'Product ${widget.product.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.inventory?.weight != null)
                      Row(
                        children: [
                          Icon(Icons.scale, size: 12, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.inventory!.weight} g',
                              style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (widget.inventory?.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.inventory!.location!,
                              style: TextStyle(color: AppTheme.mutedText, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightGold.withOpacity(0.3),
            AppTheme.lightGold.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          size: 48,
          color: AppTheme.primaryGold.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  final List<String> images;

  const _ProductImageCarousel({required this.images});

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.lightGold),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    // PickedImage renders server URLs and picked bytes on web
                    // too; Image.file (dart:io) would crash on Chrome.
                    return PickedImage(url: widget.images[index], fit: BoxFit.cover);
                  },
                ),
                if (widget.images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentIndex > 0) {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.deepPurple.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentIndex < widget.images.length - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.deepPurple.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                    _pageController.jumpToPage(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGold : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGold.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: PickedImage(url: widget.images[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
