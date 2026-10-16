import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/product_image_model.dart';

class ProductImageProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Cache images by product ID
  Map<int, List<ProductImageModel>> _imagesByProduct = {};
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

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
    _isLoading = _imagesByProduct.isEmpty;
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
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload image to Cloudinary (bytes-based — works on Flutter web and
  /// mobile, unlike path-based MultipartFile.fromPath which needs dart:io).
  Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'product.jpg',
  }) async {
    _isUploading = true;
    notifyListeners();

    try {
      final url = Uri.parse(_cloudinaryUrl);
      final imageUploadRequest = http.MultipartRequest('POST', url)
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamResponse = await imageUploadRequest.send();
      final resp = await http.Response.fromStream(streamResponse);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        debugPrint('Image upload failed with status ${resp.statusCode}: ${resp.body}');
        _error = 'Upload failed (${resp.statusCode}): ${resp.body}';
        return null;
      }

      final decodedData = json.decode(resp.body);
      final secureUrl = decodedData['secure_url'];

      if (secureUrl == null) {
        _error = 'Upload succeeded but no URL returned';
        return null;
      }

      return secureUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _error = 'Upload error: $e';
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Upload image to Cloudinary from a filesystem path — desktop/mobile only;
  /// prefer [uploadImageBytes].
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

  /// Add a new image to a product. Takes the picked [XFile] directly: on
  /// Flutter web its path is not an accessible file, so the bytes are read
  /// instead (works on mobile too).
  Future<bool> addProductImage(
    int productId,
    XFile imageFile,
    String? description,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Adding image for product $productId: ${imageFile.name}');

      // Upload to Cloudinary first (bytes route)
      final uploadedUrl = await uploadImageBytes(
        await imageFile.readAsBytes(),
        filename:
            imageFile.name.isNotEmpty ? imageFile.name : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
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

      if (response is Map<String, dynamic>) {
        final newImage = ProductImageModel.fromJson(response);
        _imagesByProduct.putIfAbsent(productId, () => []);
        _imagesByProduct[productId]!.add(newImage);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchImagesForProduct(productId);
        _isLoading = false;
        notifyListeners();
        return true;
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

      if (response is Map<String, dynamic>) {
        final newImage = ProductImageModel.fromJson(response);
        _imagesByProduct.putIfAbsent(productId, () => []);
        _imagesByProduct[productId]!.add(newImage);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchImagesForProduct(productId);
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
    _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
    notifyListeners();
  }
}