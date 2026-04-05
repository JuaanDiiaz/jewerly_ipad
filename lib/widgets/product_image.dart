import 'dart:io';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: _buildBoxDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: getImage(url),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() => BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      );

  Widget getImage(String? picture) {
    if (picture == null || picture.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.inventory_2_outlined,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    if (picture.startsWith('http')) {
      return Image.network(
        picture,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return Image.file(
          File(picture),
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      } else {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
      );
    }
  }
}