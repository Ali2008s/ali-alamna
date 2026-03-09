import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class PaginatedHorizontalList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;
  final bool isLoading;
  final bool isLastPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onSwipeRefresh;
  final ScrollController? controller;
  final double? itemWidth;
  final double? itemHeight;
  final bool showLoadingIndicator;
  final Widget? loadingWidget;
  final Widget? emptyWidget;

  const PaginatedHorizontalList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding = EdgeInsets.zero,
    this.isLoading = false,
    this.isLastPage = false,
    this.onNextPage,
    this.onSwipeRefresh,
    this.controller,
    this.itemWidth,
    this.itemHeight,
    this.showLoadingIndicator = true,
    this.loadingWidget,
    this.emptyWidget,
  });

  @override
  State<PaginatedHorizontalList<T>> createState() =>
      _PaginatedHorizontalListState<T>();
}

class _PaginatedHorizontalListState<T>
    extends State<PaginatedHorizontalList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (!_isLoadingMore && !widget.isLastPage && widget.onNextPage != null) {
      setState(() {
        _isLoadingMore = true;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      widget.onNextPage!();

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        HorizontalList(
          controller: _scrollController,
          spacing: widget.spacing,
          runSpacing: widget.runSpacing,
          padding: widget.padding,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return widget.itemBuilder(context, item, index);
          },
        ),

        // Loading indicator for pagination
        if (widget.showLoadingIndicator && _isLoadingMore && !widget.isLastPage)
          Positioned(
            bottom: 16,
            right: 16,
            child: widget.loadingWidget ??
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
          ),
      ],
    );
  }
}

// Extension for easier usage with common data types
extension PaginatedHorizontalListExtensions on PaginatedHorizontalList {
  static PaginatedHorizontalList<dynamic> fromVideoPlayerModel({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    double spacing = 8.0,
    double runSpacing = 8.0,
    EdgeInsets padding = EdgeInsets.zero,
    bool isLoading = false,
    bool isLastPage = false,
    VoidCallback? onNextPage,
    VoidCallback? onSwipeRefresh,
    ScrollController? controller,
    double? itemWidth,
    double? itemHeight,
    bool showLoadingIndicator = true,
    Widget? loadingWidget,
    Widget? emptyWidget,
  }) {
    return PaginatedHorizontalList(
      items: items,
      itemBuilder: itemBuilder,
      spacing: spacing,
      runSpacing: runSpacing,
      padding: padding,
      isLoading: isLoading,
      isLastPage: isLastPage,
      onNextPage: onNextPage,
      onSwipeRefresh: onSwipeRefresh,
      controller: controller,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      showLoadingIndicator: showLoadingIndicator,
      loadingWidget: loadingWidget,
      emptyWidget: emptyWidget,
    );
  }
}
