import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class ProductsMainScreen extends StatefulWidget {
  const ProductsMainScreen({super.key});

  @override
  State<ProductsMainScreen> createState() => _ProductsMainScreenState();
}

class _ProductsMainScreenState extends State<ProductsMainScreen> {
  Flutter3DController controller = Flutter3DController();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  int? _editingId;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    controller.onModelLoaded.addListener(() {
      debugPrint('model is loaded : ${controller.onModelLoaded.value}');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
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
    _selectedImagePath = product?.picture;
    showDialog(context: context, builder: (_) => _buildProductDialog(product));
  }

  Widget _buildProductDialog(dynamic product) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker section
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final XFile? pickedFile = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 100,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              _selectedImagePath = pickedFile.path;
                            });
                          }
                        },
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _selectedImagePath != null && _selectedImagePath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _selectedImagePath!.startsWith('http')
                                      ? Image.network(
                                          _selectedImagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Image.file(
                                          File(_selectedImagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap to add image',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                        ),
                      ),
                      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImagePath = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description field
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length < 5) {
                          return 'Description must be at least 5 characters';
                        }
                        return null;
                      },
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _saveProduct,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductProvider>();
    bool success;

    final productData = {
      'description': _descriptionController.text.trim(),
      'picture': _selectedImagePath,
    };

    if (_editingId == null) {
      success = await provider.createProduct(productData);
    } else {
      success = await provider.updateProduct(_editingId!, productData);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Product ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ProductProvider>(
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: product.picture != null && product.picture!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: product.picture!.startsWith('http')
                                    ? Image.network(
                                        product.picture!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => CircleAvatar(
                                          backgroundColor: Colors.amber[100],
                                          child: const Icon(Icons.shopping_bag, color: Colors.amber),
                                        ),
                                      )
                                    : Image.file(
                                        File(product.picture!),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => CircleAvatar(
                                          backgroundColor: Colors.amber[100],
                                          child: const Icon(Icons.shopping_bag, color: Colors.amber),
                                        ),
                                      ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.amber[100],
                                child: const Icon(Icons.shopping_bag, color: Colors.amber),
                              ),
                        title: Text(product.description ?? 'Product ${product.id}'),
                        subtitle: Text('ID: ${product.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProduct(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(product.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(
            height: 200,
            child: _ModelThreeD(
              controller: controller,
              isPortrait: isPortrait,
              screenHeight: screenHeight,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}

class _ModelThreeD extends StatelessWidget {
  const _ModelThreeD({
    required this.controller,
    required this.isPortrait,
    required this.screenHeight,
  });

  final Flutter3DController controller;
  final bool isPortrait;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    // Adaptive height: 40% of screen in portrait, 60% in landscape
    final adaptiveHeight = isPortrait ? screenHeight * 0.4 : screenHeight * 0.6;

    return Container(
      color: Colors.white,
      height: adaptiveHeight,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 250, maxHeight: 500),
      child: Flutter3DViewer(
        activeGestureInterceptor: true,
        progressBarColor: Colors.orange,
        enableTouch: true,
        onProgress: (double progressValue) {
          debugPrint('model loading progress : $progressValue');
        },
        onLoad: (String modelAddress) {
          debugPrint('model loaded : $modelAddress');
        },
        onError: (String error) {
          debugPrint('model failed to load : $error');
        },
        controller: controller,
        src: 'assets/ring.glb',
      ),
    );
  }
}
