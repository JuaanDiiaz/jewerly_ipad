import 'package:flutter/material.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null && message!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact error strip shown ABOVE list content when a refresh failed but
/// stale data is still on screen — the list stays usable and the failure
/// isn't silently swallowed.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 20, color: Colors.red[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.red[700]),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: 16, color: Colors.red[700]),
              label: Text('Retry', style: TextStyle(fontSize: 13, color: Colors.red[700])),
            ),
        ],
      ),
    );
  }
}

SnackBar errorSnackBar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
    backgroundColor: Colors.red[700],
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

SnackBar successSnackBar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
    backgroundColor: Colors.green[700],
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

SnackBar warningSnackBar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.warning_amber_outlined, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
    backgroundColor: Colors.orange[700],
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
