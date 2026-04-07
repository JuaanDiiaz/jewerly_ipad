import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/models/product_image_model.dart';
import 'package:p_a_jewerly/widgets/product_image_gallery.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

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
  List<String> _additionalImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<ProductImageProvider>().fetchAllImages();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _openProductDialog({dynamic product}) {
    _editingId = product?.id;
    _descriptionController.text = product?.description ?? '';
    _primaryImagePath = product?.picture;
    _additionalImages = [];

    showDialog(
      context: context,
      builder: (_) => _buildProductDialog(product),
    );
  }

  Widget _buildProductDialog(dynamic product) {
    final imageProvider = context.watch<ProductImageProvider>();
    final productImages = _editingId != null
        ? imageProvider.getImagesForProduct(_editingId!)
        : <ProductImageModel>[];

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
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
                        style: const TextStyle(
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
                        const Text(
                          'Primary Image',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
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
                              setState(() {
                                _primaryImagePath = pickedFile.path;
                              });
                            }
                          },
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.cream,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGold.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: _primaryImagePath != null && _primaryImagePath!.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _primaryImagePath!.startsWith('http')
                                            ? Image.network(
                                                _primaryImagePath!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_primaryImagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _primaryImagePath = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
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
                                          color: AppTheme.subtleText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description Field
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Gold Ring - Size 7',
                              hintStyle: TextStyle(color: AppTheme.subtleText.withOpacity(0.5)),
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

                        // Additional Images (for both new and existing products)
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Additional Images',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkText,
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
                                      color: AppTheme.subtleText,
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
                    color: AppTheme.cream,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _saveProduct(setState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.darkText,
                        ),
                        child: const Text('Save'),
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
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductProvider>();
    final imageProvider = context.read<ProductImageProvider>();
    bool success;

    setState(() {
      // Show loading state
    });

    final productData = {
      'description': _descriptionController.text.trim(),
      'picture': _primaryImagePath,
    };

    if (_editingId == null) {
      // Create new product
      success = await provider.createProduct(productData);

      if (success && provider.lastCreatedProductId != null) {
        // Upload additional images for the new product
        for (final imagePath in _additionalImages) {
          await imageProvider.addProductImage(
            provider.lastCreatedProductId!,
            imagePath,
            'Product image',
          );
        }
      }
    } else {
      // Update existing product
      success = await provider.updateProduct(_editingId!, productData);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Product ${_editingId == null ? 'created' : 'updated'} successfully'
                : provider.error ?? 'Operation failed',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
          if (provider.error != null) {
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
                      color: AppTheme.subtleText,
                      fontFamily: 'PlayfairDisplay',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first product',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.subtleText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          // Grid View
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.darkText,
      ),
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
            // Image - fixed aspect ratio instead of expanded
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: primaryImage != null && primaryImage.isNotEmpty
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
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${product.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtleText,
                    ),
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

SnackBar successSnackBar(String message) {
  return SnackBar(
    content: Text(message),
    backgroundColor: AppTheme.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

SnackBar errorSnackBar(String message) {
  return SnackBar(
    content: Text(message),
    backgroundColor: AppTheme.error,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}