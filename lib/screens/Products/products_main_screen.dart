import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/providers/category_provider.dart';
import 'package:p_a_jewerly/providers/product_category_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/picked_image.dart';
import 'package:p_a_jewerly/widgets/product_image_gallery.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/widgets/paged_list_view.dart';

class ProductsMainScreen extends StatefulWidget {
  const ProductsMainScreen({super.key});

  @override
  State<ProductsMainScreen> createState() => _ProductsMainScreenState();
}

class _ProductsMainScreenState extends State<ProductsMainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  int? _editingId;
  String? _primaryImagePath;
  // Freshly picked images must be kept as bytes: on Flutter web the path is
  // a blob URL that neither File() nor MultipartFile.fromPath can touch.
  Uint8List? _primaryImageBytes;
  List<XFile> _additionalImages = [];
  // True while a create/update request is in flight — the form dialog stays
  // open with its action buttons disabled until the result arrives.
  bool _isSaving = false;
  // Category assignment for the product dialog: products carry their
  // category through the ProductCategory link, which drives per-category
  // tax rates. Null = uncategorized.
  int? _selectedCategoryId;
  int? _originalCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
      context.read<ProductImageProvider>().fetchAllImages();
      if (context.read<CategoryProvider>().isStale) {
        context.read<CategoryProvider>().fetchCategories();
      }
      if (context.read<ProductCategoryProvider>().isStale) {
        context.read<ProductCategoryProvider>().fetchProductCategories();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _openProductDialog({dynamic product}) {
    _originalCategoryId =
        product == null ? null : context.read<ProductCategoryProvider>().linkForProduct(product.id)?.categoryId;
    _selectedCategoryId = _originalCategoryId;
    _editingId = product?.id;
    _descriptionController.text = product?.description ?? '';
    _primaryImagePath = product?.picture;
    _primaryImageBytes = null;
    _additionalImages = [];
    _isSaving = false;

    showDialog(
      context: context,
      builder: (_) => _buildProductDialog(product),
    );
  }

  Widget _buildProductDialog(dynamic product) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: AppBreakpoints.dialogWidth(context, 500),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height < 748
                  ? MediaQuery.sizeOf(context).height - 48
                  : 700,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.gradientDecoration(radius: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.diamond_outlined,
                        color: AppTheme.primaryGold,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product == null ? 'Add New Product' : 'Edit Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary Image Section
                        Text(
                          'Primary Image',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final XFile? pickedFile = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (pickedFile != null) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _primaryImagePath = pickedFile.path;
                                _primaryImageBytes = bytes;
                              });
                            }
                          },
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGold.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: (_primaryImageBytes != null ||
                                    (_primaryImagePath != null && _primaryImagePath!.isNotEmpty))
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        // Picked files must be shown from bytes on
                                        // web (no dart:io); server URLs via network.
                                        child: PickedImage(
                                          url: _primaryImageBytes == null ? _primaryImagePath : null,
                                          bytes: _primaryImageBytes,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _primaryImagePath = null;
                                            _primaryImageBytes = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 40,
                                        color: AppTheme.primaryGold.withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add primary image',
                                        style: TextStyle(
                                          color: AppTheme.mutedText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description Field
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Gold Ring - Size 7',
                              hintStyle: TextStyle(color: AppTheme.mutedText.withOpacity(0.5)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              if (value.trim().length < 3) {
                                return 'Description must be at least 3 characters';
                              }
                              return null;
                            },
                            autofocus: true,
                          ),
                        ),

                        // Category assignment — drives per-category tax
                        // rates and the category-share report.
                        Consumer<CategoryProvider>(
                          builder: (context, categoryProvider, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int?>(
                                  value: _selectedCategoryId,
                                  decoration: const InputDecoration(
                                    hintText: 'No category (pays default rate)',
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null, child: Text('No category')),
                                    ...categoryProvider.categories.map((c) {
                                      return DropdownMenuItem(
                                        value: c.id,
                                        child: Text(
                                            c.description ?? 'Category ${c.id}',
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) => setState(() {
                                    _selectedCategoryId = value;
                                  }),
                                ),
                              ],
                            );
                          },
                        ),

                        // Additional Images (for both new and existing products)
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Additional Images',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                              ),
                            ),
                            if (_editingId != null)
                              Consumer<ProductImageProvider>(
                                builder: (context, provider, _) {
                                  final images = provider.getImagesForProduct(_editingId!);
                                  return Text(
                                    '${images.length} images',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ProductImageGallery(
                          productId: _editingId,
                          existingImageUrls: _additionalImages,
                          isEditable: true,
                          primaryImageUrl: _primaryImagePath,
                          primaryImageBytes: _primaryImageBytes,
                          heroTag: _editingId != null ? 'product-hero-$_editingId' : null,
                          onImagesChanged: (images) {
                            setState(() {
                              _additionalImages = images;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        // Cancel is disabled while saving so the dialog can't
                        // be dismissed with the request in flight.
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        // The dialog stays open until the response arrives;
                        // success (only) pops it from inside _saveProduct.
                        onPressed: _isSaving ? null : () => _saveProduct(setState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.textColor,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProduct(StateSetter setState) async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final provider = context.read<ProductProvider>();
    final imageProvider = context.read<ProductImageProvider>();
    final wasNew = _editingId == null;
    bool success;

    setState(() {
      _isSaving = true;
    });

    final productData = {
      'description': _descriptionController.text.trim(),
      'picture': _primaryImagePath,
      if (_primaryImageBytes != null) 'pictureBytes': _primaryImageBytes,
    };

    if (wasNew) {
      // Create new product
      success = await provider.createProduct(productData);

      if (success && provider.lastCreatedProductId != null) {
        if (_selectedCategoryId != null) {
          await context.read<ProductCategoryProvider>().upsertProductCategory(
                provider.lastCreatedProductId!,
                _selectedCategoryId!,
              );
        }
        // Upload additional images for the new product
        for (final imageFile in _additionalImages) {
          await imageProvider.addProductImage(
            provider.lastCreatedProductId!,
            imageFile,
            'Product image',
          );
        }
      }
    } else {
      // Update existing product
      success = await provider.updateProduct(_editingId!, productData);

      if (success && _selectedCategoryId != _originalCategoryId) {
        // Category changed (or added): sync the link. A null selection with
        // no prior link is simply nothing to do.
        if (_selectedCategoryId != null) {
          await context
              .read<ProductCategoryProvider>()
              .upsertProductCategory(_editingId!, _selectedCategoryId!);
        }
      }
    }

    if (!mounted) return;
    if (!success) {
      // Keep the dialog open with the user's edits intact on failure.
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(provider.error ?? 'Operation failed'),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar('Product ${wasNew ? 'created' : 'updated'} successfully'),
    );
  }

  void _editProduct(dynamic product) {
    _openProductDialog(product: product);
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductProvider>().deleteProduct(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        flexibleSpace: Container(
          decoration: AppTheme.gradientDecoration(),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.products.isEmpty) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchProducts(),
            );
          }
          if (provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.diamond_outlined,
                    size: 80,
                    color: AppTheme.primaryGold.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppTheme.mutedText,
                      fontFamily: 'PlayfairDisplay',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first product',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          // Refresh failure with stale rows: keep the grid usable, surface
          // the failure as a banner instead of swallowing it.
          if (provider.error != null) {
            return Column(
              children: [
                ErrorBanner(message: provider.error!, onRetry: () => provider.fetchProducts()),
                Expanded(child: _buildProductGrid(provider)),
              ],
            );
          }

          // Grid View
          return _buildProductGrid(provider);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.textColor,
      ),
    );
  }

  Widget _buildProductGrid(ProductProvider provider) {
    // Column count follows the canvas: phone-portrait 2, tablet ~3-4, so
    // iPad's wide layout isn't a stretched 3-up grid anymore.
    final crossAxis = switch (MediaQuery.sizeOf(context).width) {
      < 500 => 2,
      < 1000 => 3,
      < 1400 => 4,
      _ => 5,
    };
    return PagedGridView(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.products.length,
            hasMore: provider.hasMore,
            isLoadingMore: provider.isLoadingMore,
            onLoadMore: () => provider.fetchProducts(loadMore: true),
            onRefresh: () => provider.fetchProducts(),
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return _buildProductCard(product);
            },
          );
  }

  Widget _buildProductCard(dynamic product) {
    final imageProvider = context.watch<ProductImageProvider>();
    final productImages = imageProvider.getImagesForProduct(product.id);
    final primaryImage = product.picture ??
        (productImages.isNotEmpty ? productImages.first.imageUrl : null);
    final imageCount = productImages.length;

    return GestureDetector(
      onTap: () => _editProduct(product),
      child: Container(
        decoration: AppTheme.goldBorderDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image takes the slack in the fixed grid cell so the info
            // section below (text + action row) always fits — with a fixed
            // AspectRatio here the two could exceed the cell height and the
            // card showed RenderFlex overflow stripes on narrow columns.
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                  primaryImage != null && primaryImage.isNotEmpty
                        ? Hero(
                            tag: 'product-hero-${product.id}',
                            child: Image.network(
                              primaryImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.lightGold.withOpacity(0.3),
                                child: Icon(
                                  Icons.diamond_outlined,
                                  size: 48,
                                  color: AppTheme.primaryGold.withOpacity(0.5),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.lightGold.withOpacity(0.3),
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 48,
                              color: AppTheme.primaryGold.withOpacity(0.5),
                            ),
                          ),
                  // Image count indicator
                  if (imageCount > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.deepPurple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${imageCount + 1}', // +1 for primary image
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.description ?? 'Product #${product.id}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${product.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editProduct(product),
                        color: AppTheme.mediumPurple,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDelete(product.id),
                        color: AppTheme.error,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Snack bar helpers live in lib/widgets/loading_overlay.dart (successSnackBar /
// errorSnackBar) — they used to be duplicated here unused.