import 'package:flutter/material.dart';

/// Shared scroll listener for the Paged* widgets: fires [onLoadMore] when
/// the scroll passes ~80% of the extent.
class _PagedScrollHandler {
  _PagedScrollHandler({
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final Future<void> Function()? onLoadMore;
  final bool Function() hasMore;
  final bool Function() isLoadingMore;

  void onScroll(ScrollController controller) {
    if (!hasMore() || isLoadingMore()) return;
    if (controller.position.maxScrollExtent <= 0) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.8) {
      onLoadMore?.call();
    }
  }
}

class _PagedFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const _PagedFooter({
    required this.isLoadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (hasMore) {
      return const SizedBox(height: 24);
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '— end of list —',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

/// ListView with built-in infinite-scroll pagination and pull-to-refresh.
/// [onLoadMore] fires when the user scrolls past ~80% of the list, as long
/// as [hasMore] is true and [isLoadingMore] is false — both come from the
/// provider driving the list.
class PagedListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry padding;

  const PagedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    this.onLoadMore,
    this.onRefresh,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<PagedListView> createState() => _PagedListViewState();
}

class _PagedListViewState extends State<PagedListView> {
  final ScrollController _controller = ScrollController();
  late final _handler = _PagedScrollHandler(
    onLoadMore: widget.onLoadMore,
    hasMore: () => widget.hasMore,
    isLoadingMore: () => widget.isLoadingMore,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _handler.onScroll(_controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh?.call();
      },
      child: ListView.builder(
        controller: _controller,
        padding: widget.padding,
        itemCount: widget.itemCount + 1,
        itemBuilder: (context, index) {
          if (index == widget.itemCount) {
            return _PagedFooter(
              isLoadingMore: widget.isLoadingMore,
              hasMore: widget.hasMore,
            );
          }
          return widget.itemBuilder(context, index);
        },
      ),
    );
  }
}

/// GridView equivalent of [PagedListView] for grid-based screens (a trailing
/// footer cell takes the place of the footer item).
class PagedGridView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry padding;

  const PagedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    required this.hasMore,
    required this.isLoadingMore,
    this.onLoadMore,
    this.onRefresh,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<PagedGridView> createState() => _PagedGridViewState();
}

class _PagedGridViewState extends State<PagedGridView> {
  final ScrollController _controller = ScrollController();
  late final _handler = _PagedScrollHandler(
    onLoadMore: widget.onLoadMore,
    hasMore: () => widget.hasMore,
    isLoadingMore: () => widget.isLoadingMore,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _handler.onScroll(_controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh?.call();
      },
      child: GridView.builder(
        controller: _controller,
        padding: widget.padding,
        gridDelegate: widget.gridDelegate,
        itemCount: widget.itemCount + 1,
        itemBuilder: (context, index) {
          if (index == widget.itemCount) {
            return Center(
              child: _PagedFooter(
                isLoadingMore: widget.isLoadingMore,
                hasMore: widget.hasMore,
              ),
            );
          }
          return widget.itemBuilder(context, index);
        },
      ),
    );
  }
}