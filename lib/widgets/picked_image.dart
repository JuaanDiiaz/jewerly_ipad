import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

/// Renders an image from in-memory bytes, a freshly picked file, or a server
/// URL. `Image.file(File(path))` requires dart:io, which does not exist on
/// Flutter web — this widget covers both platforms by always preferring
/// bytes/memory for picked files and Image.network for server URLs.
class PickedImage extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final XFile? file;
  final BoxFit fit;
  final bool showLoader;

  const PickedImage({
    super.key,
    this.url,
    this.bytes,
    this.file,
    this.fit = BoxFit.cover,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: fit);
    }
    if (file != null) {
      return _FileImage(file: file!, fit: fit, showLoader: showLoader);
    }
    if (url != null && url!.startsWith('http')) {
      return Image.network(
        url!,
        fit: fit,
        loadingBuilder: showLoader
            ? (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppTheme.lightGold.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGold),
                  ),
                );
              }
            : null,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }
    return _broken();
  }

  Widget _broken() {
    return Container(
      color: AppTheme.lightGold.withOpacity(0.3),
      child: Icon(Icons.broken_image, size: 48, color: AppTheme.mutedText),
    );
  }
}

/// Decodes a picked file once and keeps the bytes across rebuilds (the future
/// is created in State.initState so a rebuild never re-reads the file).
class _FileImage extends StatefulWidget {
  final XFile file;
  final BoxFit fit;
  final bool showLoader;

  const _FileImage({required this.file, required this.fit, required this.showLoader});

  @override
  State<_FileImage> createState() => _FileImageState();
}

class _FileImageState extends State<_FileImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(bytes, fit: widget.fit);
        }
        if (snapshot.hasError) {
          return _brokenImage();
        }
        final loading = widget.showLoader || snapshot.connectionState == ConnectionState.waiting;
        return Container(
          color: AppTheme.lightGold.withOpacity(0.3),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _brokenImage() {
    return Container(
      color: AppTheme.lightGold.withOpacity(0.3),
      child: Icon(Icons.broken_image, size: 48, color: AppTheme.mutedText),
    );
  }
}