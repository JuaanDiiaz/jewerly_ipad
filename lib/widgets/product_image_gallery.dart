import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

class ProductImageGallery extends StatefulWidget {
  final int? productId; // Make nullable for new products
  final List<String> existingImageUrls; // For new products, pass local paths
  final bool isEditable;
  final String? primaryImageUrl;
  final Function(List<String>)? onImagesChanged; // Callback when images change
  final String? heroTag; // For Hero animation

  const ProductImageGallery({
    super.key,
    this.productId,
    this.existingImageUrls = const [],
    this.isEditable = false,
    this.primaryImageUrl,
    this.onImagesChanged,
    this.heroTag,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _selectedIndex = 0;
  final _imagePicker = ImagePicker();
  bool _isAddingImage = false;
  List<String> _localImages = []; // For new products, store local paths

  @override
  void initState() {
    super.initState();
    _localImages = List.from(widget.existingImageUrls);
  }

  @override
  void didUpdateWidget(ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset local images when switching to a different product
    if (oldWidget.productId != widget.productId) {
      _localImages = List.from(widget.existingImageUrls);
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // For existing products, get images from provider
    List<String> allImages = [];

    if (widget.productId != null) {
      // Existing product - get from provider
      final imageProvider = context.watch<ProductImageProvider>();
      final productImages = imageProvider.getImagesForProduct(widget.productId!);
      allImages = productImages.map((img) => img.imageUrl).where((url) => url.isNotEmpty).toList();

      // Add primary image if exists and not already in list
      if (widget.primaryImageUrl != null &&
          widget.primaryImageUrl!.isNotEmpty &&
          !allImages.contains(widget.primaryImageUrl)) {
        allImages.insert(0, widget.primaryImageUrl!);
      }
    } else {
      // New product - use local images
      allImages = _localImages;
      if (widget.primaryImageUrl != null &&
          widget.primaryImageUrl!.isNotEmpty &&
          !_localImages.contains(widget.primaryImageUrl)) {
        allImages.insert(0, widget.primaryImageUrl!);
      }
    }

    // Ensure selectedIndex is within bounds
    if (_selectedIndex >= allImages.length) {
      _selectedIndex = (allImages.length - 1).clamp(0, double.infinity.toInt());
    }

    final hasImages = allImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Display (Carousel)
        Container(
          height: 280,
          width: double.infinity,
          decoration: AppTheme.goldBorderDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasImages
                ? _buildImageCarousel(allImages)
                : _buildEmptyPlaceholder(),
          ),
        ),

        const SizedBox(height: 12),

        // Thumbnail Strip
        if (hasImages) ...[
          SizedBox(
            height: 70,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allImages.length,
                    itemBuilder: (context, index) => _buildThumbnail(allImages, index),
                  ),
                ),
                if (widget.isEditable) _buildAddImageButton(),
              ],
            ),
          ),
        ] else if (widget.isEditable) ...[
          _buildAddImageButtonLarge(),
        ],
      ],
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) return _buildEmptyPlaceholder();

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          itemBuilder: (context, index) {
            final imageUrl = images[index];
            final isNetworkImage = imageUrl.startsWith('http') || imageUrl.startsWith('https');
            final isFirstImage = index == 0 && widget.heroTag != null;

            Widget imageWidget = isNetworkImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.lightGold.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryGold),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.lightGold.withOpacity(0.3),
                      child: const Icon(Icons.broken_image, size: 64, color: AppTheme.subtleText),
                    ),
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.lightGold.withOpacity(0.3),
                      child: const Icon(Icons.broken_image, size: 64, color: AppTheme.subtleText),
                    ),
                  );

            return Stack(
              fit: StackFit.expand,
              children: [
                // Wrap first image with Hero for animation
                isFirstImage ? Hero(tag: widget.heroTag!, child: imageWidget) : imageWidget,
                // Image counter
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${index + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                // Delete button for editable mode
                if (widget.isEditable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildDeleteButton(index),
                  ),
              ],
            );
          },
        ),
        // Navigation arrows
        if (images.length > 1) ...[
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate left - implemented via PageController would be better
                  // For simplicity, we just indicate there's navigation
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
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
                  // Navigate right
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      color: AppTheme.lightGold.withOpacity(0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diamond_outlined,
            size: 64,
            color: AppTheme.primaryGold.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No images yet',
            style: TextStyle(
              color: AppTheme.subtleText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(List<String> images, int index) {
    final imageUrl = images[index];
    final isSelected = index == _selectedIndex;
    final isNetworkImage = imageUrl.startsWith('http') || imageUrl.startsWith('https');

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
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
                    color: AppTheme.primaryGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetworkImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.lightGold,
                        child: const Icon(Icons.broken_image, color: AppTheme.subtleText),
                      ),
                    )
                  : Image.file(
                      File(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.lightGold,
                        child: const Icon(Icons.broken_image, color: AppTheme.subtleText),
                      ),
                    ),
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isAddingImage ? null : _pickImage,
      child: Container(
        width: 70,
        height: 70,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryGold.withOpacity(0.5),
            width: 2,
          ),
          color: AppTheme.lightGold.withOpacity(0.3),
        ),
        child: _isAddingImage
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGold,
                  ),
                ),
              )
            : const Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: AppTheme.primaryGold,
              ),
      ),
    );
  }

  Widget _buildAddImageButtonLarge() {
    return GestureDetector(
      onTap: _isAddingImage ? null : _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGold.withOpacity(0.5),
            width: 2,
          ),
          color: AppTheme.lightGold.withOpacity(0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAddingImage) ...[
              const CircularProgressIndicator(
                color: AppTheme.primaryGold,
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading...',
                style: TextStyle(
                  color: AppTheme.subtleText,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: AppTheme.primaryGold,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to add images',
                style: TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _deleteImage(index),
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _isAddingImage = true);

      if (widget.productId != null) {
        // Existing product - upload immediately
        final provider = context.read<ProductImageProvider>();
        final success = await provider.addProductImage(
          widget.productId!,
          pickedFile.path,
          'Product image',
        );

        if (mounted) {
          setState(() {
            _isAddingImage = false;
            if (success) {
              final images = provider.getImagesForProduct(widget.productId!);
              if (images.isNotEmpty) {
                _selectedIndex = images.length - 1;
              }
            }
          });

          if (!success) {
            final errorMsg = provider.error ?? 'Failed to add image';
            debugPrint('Image upload error: $errorMsg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // New product - just add to local list
        setState(() {
          _isAddingImage = false;
          _localImages.add(pickedFile.path);
          _selectedIndex = _localImages.length - 1;
        });

        // Notify parent
        widget.onImagesChanged?.call(_localImages);
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    if (widget.productId != null) {
      // Existing product - delete from server
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to remove this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final imageProvider = context.read<ProductImageProvider>();
        final images = imageProvider.getImagesForProduct(widget.productId!);
        if (index < images.length) {
          await imageProvider.deleteProductImage(images[index].id, widget.productId!);
          if (mounted) {
            setState(() {
              if (_selectedIndex >= images.length) {
                _selectedIndex = (images.length - 1).clamp(0, double.infinity).toInt();
              }
            });
          }
        }
      }
    } else {
      // New product - just remove from local list
      setState(() {
        _localImages.removeAt(index);
        if (_selectedIndex >= _localImages.length) {
          _selectedIndex = (_localImages.length - 1).clamp(0, double.infinity).toInt();
        }
      });

      // Notify parent
      widget.onImagesChanged?.call(_localImages);
    }
  }

  /// Get local images for new products (called by parent before saving)
  List<String> getLocalImages() => _localImages;
}