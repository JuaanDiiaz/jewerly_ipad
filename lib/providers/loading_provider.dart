import 'package:flutter/material.dart';

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _loadingMessage = '';

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void startLoading([String message = 'Loading...']) {
    _isLoading = true;
    _loadingMessage = message;
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    _loadingMessage = '';
    notifyListeners();
  }
}
