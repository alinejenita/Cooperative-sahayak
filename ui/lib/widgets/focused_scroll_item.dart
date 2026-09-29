import 'package:flutter/material.dart';

class FocusedScrollItem extends StatefulWidget {
  final bool isFocused;
  final Widget child;

  const FocusedScrollItem({
    super.key,
    required this.isFocused,
    required this.child,
  });

  @override
  State<FocusedScrollItem> createState() => _FocusedScrollItemState();
}

class _FocusedScrollItemState extends State<FocusedScrollItem> {
  @override
  void didUpdateWidget(FocusedScrollItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused && !oldWidget.isFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
