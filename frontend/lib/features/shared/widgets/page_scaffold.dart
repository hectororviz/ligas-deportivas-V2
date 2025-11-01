import 'package:flutter/material.dart';

class PageScaffold extends StatefulWidget {
  const PageScaffold({
    super.key,
    required this.builder,
    this.floatingActionButton,
    this.backgroundColor = Colors.transparent,
  });

  final Widget Function(BuildContext context, ScrollController scrollController) builder;
  final Widget? floatingActionButton;
  final Color backgroundColor;

  @override
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold> {
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShow;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (_showScrollToTop) {
      buttons.add(
        FloatingActionButton.small(
          heroTag: const ValueKey('scroll-to-top'),
          onPressed: _scrollToTop,
          tooltip: 'Ir arriba',
          child: const Icon(Icons.arrow_upward),
        ),
      );
    }

    if (widget.floatingActionButton != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(widget.floatingActionButton!);
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: PrimaryScrollController(
        controller: _scrollController,
        child: widget.builder(context, _scrollController),
      ),
      floatingActionButton: buttons.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buttons,
            ),
    );
  }
}
