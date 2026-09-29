import 'package:flutter/material.dart';

/// Legacy Keypad Listener placeholder. Keypad input hardware has been removed
/// in favor of direct touchscreen and voice interactions.
class KeypadControllerListener extends StatelessWidget {
  final Widget child;
  final dynamic state;
  final int currentScreenMaxItems;
  final VoidCallback? onConfirmFocused;

  const KeypadControllerListener({
    super.key,
    required this.child,
    this.state,
    this.currentScreenMaxItems = 1,
    this.onConfirmFocused,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
