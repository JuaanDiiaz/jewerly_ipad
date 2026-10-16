// Smoke tests for the pagination plumbing (replaces the default template
// counter test, which never matched this app).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:p_a_jewerly/infraestructure/services/api_service.dart';
import 'package:p_a_jewerly/widgets/paged_list_view.dart';

void main() {
  group('PagedEnvelope', () {
    test('hasMore is true while unfull pages remain', () {
      final envelope = PagedEnvelope(
        data: const [],
        page: 2,
        pageSize: 50,
        totalCount: 130,
      );
      expect(envelope.hasMore, isTrue);
    });

    test('hasMore is false exactly at the last page', () {
      final envelope = PagedEnvelope(
        data: const [],
        page: 3,
        pageSize: 50,
        totalCount: 130,
      );
      expect(envelope.hasMore, isFalse);
    });

    test('hasMore is false for an empty result', () {
      final envelope = PagedEnvelope(
        data: const [],
        page: 1,
        pageSize: 50,
        totalCount: 0,
      );
      expect(envelope.hasMore, isFalse);
    });
  });

  group('PagedListView', () {
    testWidgets('renders items and the end-of-list footer when no more pages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PagedListView(
              itemCount: 3,
              hasMore: false,
              isLoadingMore: false,
              itemBuilder: (context, index) =>
                  ListTile(title: Text('item $index')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('item 0'), findsOneWidget);
      expect(find.text('item 2'), findsOneWidget);
      expect(find.text('— end of list —'), findsOneWidget);
    });

    testWidgets('shows a loading footer while fetching the next page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PagedListView(
              itemCount: 3,
              hasMore: true,
              isLoadingMore: true,
              itemBuilder: (context, index) =>
                  ListTile(title: Text('item $index')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('— end of list —'), findsNothing);
    });

    testWidgets('calls onLoadMore when scrolled past ~80%',
        (WidgetTester tester) async {
      var loadMoreCalled = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return SizedBox(
                height: 400,
                child: PagedListView(
                  itemCount: 60,
                  hasMore: true,
                  isLoadingMore: false,
                  onLoadMore: () async => loadMoreCalled++,
                  itemBuilder: (context, index) =>
                      SizedBox(height: 50, child: Text('row $index')),
                ),
              );
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 60 rows * 50px - 400 viewport ≈ 2600 total; the trigger sits at 80%,
      // so scroll past ~2100px across three flings.
      await tester.drag(find.byType(Scrollable), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(loadMoreCalled, greaterThan(0));
    });
  });
}