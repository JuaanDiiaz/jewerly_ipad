import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Cloudinary config (same as gestor_tenis project)
  static const String _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/duw0j4d3p/image/upload?upload_preset=tenis_v1';

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Product');
      _products = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Product/$id');
      // Handle single product response if needed
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Upload image if it's a local file
      if (productData['picture'] != null &&
          productData['picture'].toString().isNotEmpty &&
          !productData['picture'].toString().startsWith('http')) {
        final uploadedUrl = await uploadImage(productData['picture']);
        if (uploadedUrl != null) {
          productData['picture'] = uploadedUrl;
        }
      }

      // Backend expects: { id, description, picture }
      final backendData = {
        'description': productData['description'] ?? productData['name'],
        'picture': productData['picture'],
      };
      final response = await _apiService.post('/Product', body: backendData);
      if (response != null) {
        _products.add(ProductModel.fromJson(response));
        _isLoading = false;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> productData) async {
    _isLoading = true;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Upload image if it's a local file
      if (productData['picture'] != null &&
          productData['picture'].toString().isNotEmpty &&
          !productData['picture'].toString().startsWith('http')) {
        final uploadedUrl = await uploadImage(productData['picture']);
        if (uploadedUrl != null) {
          productData['picture'] = uploadedUrl;
        }
      }

      final response = await _apiService.put('/Product/$id', body: productData);
      if (response != null) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = ProductModel.fromJson(response);
        }
        _isLoading = false;
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/Product/$id');
      _products.removeWhere((p) => p.id == id);
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

  /// Uploads an image to Cloudinary and returns the secure URL
  Future<String?> uploadImage(String imagePath) async {
    _isSaving = true;
    notifyListeners();

    try {
      final url = Uri.parse(_cloudinaryUrl);
      final imageUploadRequest = http.MultipartRequest('POST', url);
      final file = await http.MultipartFile.fromPath('file', imagePath);
      imageUploadRequest.files.add(file);

      final streamResponse = await imageUploadRequest.send();
      final resp = await http.Response.fromStream(streamResponse);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        debugPrint('Image upload failed: ${resp.body}');
        return null;
      }

      final decodedData = json.decode(resp.body);
      return decodedData['secure_url'];
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
