import 'dart:convert';
import 'dart:typed_data';

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
  int? _lastCreatedProductId;

  // Pagination state for the products list
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _searchQuery;

  DateTime _lastFetched = DateTime.fromMillisecondsSinceEpoch(0);
  /// True when no data or the last successful fetch is older than 60s —
  /// HomeScreen refetches on navigation only when this is true.
  bool get isStale =>
      DateTime.now().difference(_lastFetched) > const Duration(seconds: 60);

  // Cloudinary config (same as gestor_tenis project)
  static const String _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/duw0j4d3p/image/upload?upload_preset=tenis_v1';

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  int? get lastCreatedProductId => _lastCreatedProductId;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// [loadMore] appends the next page to [products]; a plain call resets
  /// the list. [query] filters server-side by description and resets to
  /// page 1. [fetchAll] walks every page in one call — for catalog screens
  /// that need the full product list (sale cart, purchases, price lists),
  /// not for the paged grid.
  Future<void> fetchProducts({
    String? query,
    bool loadMore = false,
    bool fetchAll = false,
  }) async {
    if (!loadMore) {
      _searchQuery = (query != null && query.trim().isNotEmpty)
          ? query.trim()
          : null;
      _isLoading = _products.isEmpty;
      _error = null;
      _page = 1;
      notifyListeners();
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      _error = null;
      notifyListeners();
    }

    // Keep requesting while fetching-all (capped so a pathological server
    // response can't loop forever).
    final keepGoing = fetchAll && !loadMore;
    try {
      var targetPage = loadMore ? _page + 1 : 1;
      final fetched = <ProductModel>[];
      var totalCount = 0;
      var lastPageSize = 50;
      do {
        final envelope = await _apiService.getPaged('/Product', params: {
          'page': '$targetPage',
          if (_searchQuery != null) 'q': _searchQuery!,
        });
        fetched.addAll(envelope.data
            .whereType<Map>()
            .map((json) =>
                ProductModel.fromJson(Map<String, dynamic>.from(json)))
            .toList());
        totalCount = envelope.totalCount;
        lastPageSize = envelope.pageSize > 0 ? envelope.pageSize : 50;
        targetPage++;
      } while (keepGoing &&
          (targetPage - 1) * lastPageSize < totalCount &&
          targetPage <= 25);

      final page = targetPage - 1;
      if (loadMore) {
        _products.addAll(fetched);
      } else {
        _products = fetched;
        _lastFetched = DateTime.now();
      }
      _page = page;
      _hasMore = !keepGoing && page * lastPageSize < totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.get('/Product/$id');
      // Response handled if needed for future single-product updates
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
      // Upload image: bytes if the screen passed them (web must go through
      // fromBytes), otherwise a local file path.
      final pictureBytes = productData['pictureBytes'] as Uint8List?;
      if (pictureBytes != null) {
        final uploadedUrl = await uploadImageBytes(pictureBytes);
        if (uploadedUrl != null) {
          productData['picture'] = uploadedUrl;
        }
      } else if (productData['picture'] != null &&
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
      if (response is Map<String, dynamic>) {
        final newProduct = ProductModel.fromJson(response);
        _products.insert(0, newProduct);
        _lastCreatedProductId = newProduct.id;
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchProducts();
        _lastCreatedProductId = null;
      }
      _isLoading = false;
      _isSaving = false;
      notifyListeners();
      return true;
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
      // Upload image: bytes if the screen passed them, else a local path.
      final pictureBytes = productData['pictureBytes'] as Uint8List?;
      if (pictureBytes != null) {
        final uploadedUrl = await uploadImageBytes(pictureBytes);
        if (uploadedUrl != null) {
          productData['picture'] = uploadedUrl;
        }
      } else if (productData['picture'] != null &&
          productData['picture'].toString().isNotEmpty &&
          !productData['picture'].toString().startsWith('http')) {
        final uploadedUrl = await uploadImage(productData['picture']);
        if (uploadedUrl != null) {
          productData['picture'] = uploadedUrl;
        }
      }

      // pictureBytes is an app-only key — never serialize it to the backend
      // (it would become a giant numeric array in the PUT body).
      final payload = {...productData}..remove('pictureBytes');
      final response = await _apiService.put('/Product/$id', body: payload);
      if (response is Map<String, dynamic>) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = ProductModel.fromJson(response);
        }
      } else {
        // 2xx with empty body: it succeeded but returned no record — refetch
        await fetchProducts();
      }
      _isLoading = false;
      _isSaving = false;
      notifyListeners();
      return true;
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

  /// Uploads an image (as bytes — the only form that works on Flutter web,
  /// where MultipartFile.fromPath/dart:io file access is unavailable) to
  /// Cloudinary and returns the secure URL.
  Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'product.jpg',
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final url = Uri.parse(_cloudinaryUrl);
      final imageUploadRequest = http.MultipartRequest('POST', url)
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

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

  /// Uploads an image file by path (desktop/mobile only — prefer
  /// [uploadImageBytes]).
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
