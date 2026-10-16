import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p_a_jewerly/models/product_image_model.dart';
import 'package:p_a_jewerly/providers/product_image_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/product_image_gallery.dart';
import 'package:provider/provider.dart';

class _FakeImageProvider extends ProductImageProvider {
  @override
  List<ProductImageModel> getImagesForProduct(int productId) => [
        ProductImageModel(id: 10, productId: 1, imageUrl: 'https://a.example/1.png', description: ''),
        ProductImageModel(id: 11, productId: 1, imageUrl: 'https://a.example/2.png', description: ''),
        ProductImageModel(id: 12, productId: 1, imageUrl: 'https://a.example/3.png', description: ''),
      ];
}

/// Regression test: tapping a thumbnail in the product image gallery must
/// switch the main carousel page (the counter text follows the page).
void main() {
  testWidgets('thumbnail tap switches the main carousel page', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Declared as the BASE type so context.watch<ProductImageProvider> finds it
          ChangeNotifierProvider<ProductImageProvider>.value(value: _FakeImageProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: ListView(
                children: [
                  ProductImageGallery(
                    productId: 1,
                    isEditable: false,
                    primaryImageUrl: 'https://a.example/primary.png',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Display list: [primary, img1, img2, img3] — counter starts at 1 / 4
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    // The thumbnail strip is the horizontal ListView; its GestureDetectors
    // are the tappable thumbnails. Tap the 3rd one.
    final strip = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    expect(strip, findsOneWidget);
    final taps = find.descendant(of: strip, matching: find.byType(GestureDetector));
    expect(tester.widgetList(taps).length, 4);

    await tester.tap(taps.at(2));
    await tester.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);
  });
}