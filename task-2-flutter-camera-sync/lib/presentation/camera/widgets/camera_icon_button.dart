import 'package:flutter/material.dart';

/// Round dark button that stays readable over any preview. 48dp target.
class CameraIconButton extends StatelessWidget {
  const CameraIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;

  /// Tooltip and semantic label.
  final String label;
  final VoidCallback? onPressed;

  /// Highlights toggles that are on.
  final bool active;

  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: active ? Colors.white : Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, color: active ? Colors.black : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
