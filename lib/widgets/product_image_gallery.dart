import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/providers/product_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/picked_image.dart';

/// A gallery display item: a server URL, in-memory bytes (primary picked on
/// the product dialog), or a picked file that gets decoded on demand.
/// Bytes/memory rendering matters because `Image.file` needs dart:io, which
/// doesn't exist on Flutter web.
class _GalleryItem {
  final String? url;
  final Uint8List? bytes;
  final XFile? file;

  const _GalleryItem({this.url, this.bytes, this.file});

  bool get isEmpty => (url == null || url!.isEmpty) && bytes == null && file == null;
}

class ProductImageGallery extends StatefulWidget {
  final int? productId; // Make nullable for new products
  final List<XFile> existingImageUrls; // For new products, picked files
  final bool isEditable;
  final String? primaryImageUrl;
  final Uint8List? primaryImageBytes; // picked primary (web-safe display)
  final Function(List<XFile>)? onImagesChanged; // Callback when images change
  final String? heroTag; // For Hero animation

  const ProductImageGallery({
    super.key,
    this.productId,
    this.existingImageUrls = const [],
    this.isEditable = false,
    this.primaryImageUrl,
    this.primaryImageBytes,
    this.onImagesChanged,
    this.heroTag,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _selectedIndex = 0;
  final _imagePicker = ImagePicker();
  final _pageController = PageController();
  bool _isAddingImage = false;
  List<XFile> _localImages = []; // New products: picked files (paths are browser blob URLs)

  /// Normalizes the display list the same way as `build` so deletion and
  /// pick handlers map indexes consistently with what is rendered. The
  /// provider is passed in (watch in build, read in handlers) so handlers
  /// can call this outside the build phase without provider errors.
  List<_GalleryItem> _displayItems(ProductImageProvider imageProvider) {
    final items = <_GalleryItem>[];
    final primary = _GalleryItem(
      url: widget.primaryImageUrl,
      bytes: widget.primaryImageBytes,
    );

    if (widget.productId != null) {
      // Existing product - get from provider
      final productImages = imageProvider.getImagesForProduct(widget.productId!);
      final urls = productImages
          .map((img) => img.imageUrl)
          .where((url) => url.isNotEmpty)
          .toSet();

      if (!primary.isEmpty && !urls.contains(primary.url)) {
        items.add(primary);
      }
      for (final url in urls) {
        items.add(_GalleryItem(url: url));
      }
    } else {
      // New product - primary + picked files
      if (_hasPrimaryItem()) {
        items.add(primary);
      }
      for (final picked in _localImages) {
        items.add(_GalleryItem(file: picked));
      }
    }
    return items;
  }

  List<_GalleryItem> _buildDisplayItems() {
    return _displayItems(context.watch<ProductImageProvider>());
  }

  /// For new products: whether the primary image (picked on the product
  /// dialog) is part of the rendered display list at index 0.
  bool _hasPrimaryItem() {
    final primary = _GalleryItem(url: widget.primaryImageUrl, bytes: widget.primaryImageBytes);
    return !primary.isEmpty &&
        !_localImages.any((i) => i.path == widget.primaryImageUrl);
  }

  /// Syncs `_selectedIndex` (highlight, counter) and the PageView itself.
  /// Thumbnail taps and post-add/delete selections previously only changed
  /// `_selectedIndex` — the main image silently stayed where it was.
  void _goToPage(int index, {bool animate = false}) {
    if (index < 0) return;
    setState(() => _selectedIndex = index);
    void jump() {
      if (mounted && _pageController.hasClients) {
        if (animate) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          _pageController.jumpToPage(index);
        }
      }
    }

    if (_pageController.hasClients) {
      jump();
    } else {
      // PageView not attached yet (e.g. first image just appeared) — retry
      // after this frame's build, when the attach has happened.
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    }
  }

  @override
  void initState() {
    super.initState();
    _localImages = List.from(widget.existingImageUrls);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset local images when switching to a different product
    if (oldWidget.productId != widget.productId) {
      _localImages = List.from(widget.existingImageUrls);
      _selectedIndex = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _buildDisplayItems();

    // Ensure selectedIndex is within bounds; if the list shrank (an image
    // was deleted), pull the PageView back in range too.
    if (_selectedIndex >= displayItems.length) {
      // `double.infinity.toInt()` throws `UnsupportedError` — index into an
      // empty list must simply reset to 0.
      _selectedIndex = displayItems.isEmpty ? 0 : displayItems.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients && displayItems.isNotEmpty) {
          _pageController.jumpToPage(_selectedIndex);
        }
      });
    }

    final hasImages = displayItems.isNotEmpty;

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
                ? _buildImageCarousel(displayItems)
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
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) => _buildThumbnail(displayItems, index),
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

  Widget _buildImageCarousel(List<_GalleryItem> images) {
    if (images.isEmpty) return _buildEmptyPlaceholder();

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          itemBuilder: (context, index) {
            final item = images[index];
            final isFirstImage = index == 0 && widget.heroTag != null;

            // Picked bytes / picked file render on web too; Image.file
            // (dart:io) does not.
            Widget imageWidget = PickedImage(
              url: item.url,
              bytes: item.bytes,
              file: item.file,
              fit: BoxFit.cover,
              showLoader: true,
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
                  // _goToPage guards the PageView-not-attached case
                  // (`PageController.page` asserts before the attach).
                  if (_selectedIndex > 0) _goToPage(_selectedIndex - 1, animate: true);
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
                  if (_selectedIndex < images.length - 1) {
                    _goToPage(_selectedIndex + 1, animate: true);
                  }
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
              color: AppTheme.mutedText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(List<_GalleryItem> images, int index) {
    final item = images[index];
    final isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () => _goToPage(index),
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
              PickedImage(url: item.url, bytes: item.bytes, file: item.file),
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
                  color: AppTheme.mutedText,
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
        color: AppTheme.error.withOpacity(0.9),
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
      final provider = context.read<ProductImageProvider>();

      if (widget.productId != null) {
        // Existing product - upload immediately (the XFile is read as bytes
        // inside the provider, which works on web too)
        final success = await provider.addProductImage(
          widget.productId!,
          pickedFile,
          'Product image',
        );

        if (mounted) {
          setState(() => _isAddingImage = false);
          if (success) {
            // Select the image just added (last in the display list)
            final items = _displayItems(provider);
            _goToPage(items.length - 1);
          }

          if (!success) {
            final errorMsg = provider.error ?? 'Failed to add image';
            debugPrint('Image upload error: $errorMsg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      } else {
        // New product - just add to local list (rendered from bytes via
        // PickedImage; the parent uploads after createProduct)
        setState(() {
          _isAddingImage = false;
          _localImages.add(pickedFile);
        });

        // Select the image just added and notify parent
        _goToPage(_displayItems(provider).length - 1);
        widget.onImagesChanged?.call(_localImages);
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    // Resolve against the rendered display list: the primary image (when
    // shown) occupies index 0, so provider/list indexes are offset.
    final items = _displayItems(context.read<ProductImageProvider>());
    if (index < 0 || index >= items.length) return;
    final item = items[index];

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
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final imageProvider = context.read<ProductImageProvider>();
    if (widget.productId != null) {
      final productProvider = context.read<ProductProvider>();

      if (item.url != null) {
        // Server image - delete the ProductImage record holding this URL
        final record = imageProvider
            .getImagesForProduct(widget.productId!)
            .where((img) => img.imageUrl == item.url)
            .firstOrNull;
        if (record == null) return;
        await imageProvider.deleteProductImage(record.id, widget.productId!);
      } else {
        // The display item was the product's primary picture — clear it on
        // the product itself (there is no ProductImage record for it).
        final product = productProvider.products
            .where((p) => p.id == widget.productId)
            .firstOrNull;
        if (product == null) return;
        await productProvider.updateProduct(
          widget.productId!,
          {'description': product.description, 'picture': ''},
        );
      }

      if (mounted) _goToPage(_displayItems(imageProvider).length - 1);
    } else {
      // New product - remove from the local picked list
      final localIndex = _localImages.indexWhere((i) => i.path == item.file?.path);
      if (localIndex < 0) return;
      setState(() => _localImages.removeAt(localIndex));
      widget.onImagesChanged?.call(_localImages);

      // Select the last remaining image (0 when everything was removed)
      final remaining = _displayItems(imageProvider);
      _goToPage(remaining.isNotEmpty ? remaining.length - 1 : 0);
    }
  }
}