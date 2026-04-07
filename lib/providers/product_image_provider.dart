import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/product_image_model.dart';

class ProductImageProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Cache images by product ID
  Map<int, List<ProductImageModel>> _imagesByProduct = {};
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  // Cloudinary config
  static const String _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/duw0j4d3p/image/upload?upload_preset=tenis_v1';

  List<ProductImageModel> getImagesForProduct(int productId) {
    return _imagesByProduct[productId] ?? [];
  }

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;

  /// Fetch all images for a specific product
  Future<void> fetchImagesForProduct(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/ProductImage');
      final List<dynamic> allImages = response is List ? response : [];

      // Filter images for this product
      final productImages = allImages
          .where((img) => img['productId'] == productId)
          .map((json) => ProductImageModel.fromJson(json))
          .toList();

      _imagesByProduct[productId] = productImages;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all product images (for caching all products)
  Future<void> fetchAllImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/ProductImage');
      final List<dynamic> allImages = response is List ? response : [];

      // Group images by productId
      _imagesByProduct.clear();
      for (final json in allImages) {
        final image = ProductImageModel.fromJson(json);
        _imagesByProduct.putIfAbsent(image.productId, () => []);
        _imagesByProduct[image.productId]!.add(image);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload image to Cloudinary
  Future<String?> uploadImage(String imagePath) async {
    _isUploading = true;
    notifyListeners();

    try {
      debugPrint('Starting image upload from: $imagePath');
      final url = Uri.parse(_cloudinaryUrl);
      final imageUploadRequest = http.MultipartRequest('POST', url);

      // Add the file
      final file = await http.MultipartFile.fromPath('file', imagePath);
      imageUploadRequest.files.add(file);

      // Add upload preset explicitly
      imageUploadRequest.fields['upload_preset'] = 'tenis_v1';

      debugPrint('Sending request to Cloudinary...');
      final streamResponse = await imageUploadRequest.send();
      final resp = await http.Response.fromStream(streamResponse);

      debugPrint('Cloudinary response status: ${resp.statusCode}');
      debugPrint('Cloudinary response body: ${resp.body}');

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        debugPrint('Image upload failed with status ${resp.statusCode}: ${resp.body}');
        _error = 'Upload failed (${resp.statusCode}): ${resp.body}';
        return null;
      }

      final decodedData = json.decode(resp.body);
      final secureUrl = decodedData['secure_url'];

      if (secureUrl == null) {
        debugPrint('No secure_url in response: $decodedData');
        _error = 'Upload succeeded but no URL returned';
        return null;
      }

      debugPrint('Uploaded image URL: $secureUrl');
      return secureUrl;
    } catch (e, stackTrace) {
      debugPrint('Error uploading image: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Upload error: $e';
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Add a new image to a product
  Future<bool> addProductImage(
    int productId,
    String imagePath,
    String? description,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Adding image for product $productId from path: $imagePath');

      // Upload to Cloudinary first
      final uploadedUrl = await uploadImage(imagePath);
      if (uploadedUrl == null) {
        _error = 'Failed to upload image to Cloudinary';
        debugPrint('Image upload failed: Cloudinary returned null');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint('Image uploaded successfully: $uploadedUrl');

      // Create record in database
      final response = await _apiService.post('/ProductImage', body: {
        'productId': productId,
        'imageUrl': uploadedUrl,
        'description': description ?? '',
      });

      debugPrint('ProductImage API response: $response');

      if (response != null) {
        final newImage = ProductImageModel.fromJson(response);
        _imagesByProduct.putIfAbsent(productId, () => []);
        _imagesByProduct[productId]!.add(newImage);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to save image record to database';
        debugPrint('API returned null response');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding product image: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Add image with existing URL (no upload needed)
  Future<bool> addProductImageWithUrl(
    int productId,
    String imageUrl,
    String? description,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/ProductImage', body: {
        'productId': productId,
        'imageUrl': imageUrl,
        'description': description ?? '',
      });

      if (response != null) {
        final newImage = ProductImageModel.fromJson(response);
        _imagesByProduct.putIfAbsent(productId, () => []);
        _imagesByProduct[productId]!.add(newImage);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Delete an image
  Future<bool> deleteProductImage(int imageId, int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/ProductImage/$imageId');
      _imagesByProduct[productId]?.removeWhere((img) => img.id == imageId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear cache
  void clearCache() {
    _imagesByProduct.clear();
    notifyListeners();
  }
}