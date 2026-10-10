import 'package:flutter/material.dart';

/// Tab pages that are built on first visit and then kept alive.
///
/// An [IndexedStack] builds every page up front, so five tabs load five
/// screens of data and run five screens of animation at start. This builds a
/// page only when it is first shown, and mutes tickers on the hidden ones.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({required this.index, required this.children, super.key});

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final Set<int> _visited = {widget.index};

  @override
  void didUpdateWidget(LazyIndexedStack old) {
    super.didUpdateWidget(old);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_visited.contains(i))
            TickerMode(enabled: i == widget.index, child: widget.children[i])
          else
            const SizedBox.shrink(),
      ],
    );
  }
}
