import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'spiral_spinner.dart';

class NeumorphicButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double depth;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.color,
    this.padding,
    this.borderRadius = 12,
    this.depth = 20,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final Color buttonColor =
        widget.color ?? Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: ClayContainer(
          color: buttonColor,
          borderRadius: widget.borderRadius,
          depth: _isPressed
              ? (-widget.depth / 2).round()
              : widget.depth.round(),
          spread: 1,
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Center(
              child: widget.isLoading
                  ? WebPSpinner(
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                      isVisible: widget.isLoading,
                    )
                  : DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: isEnabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Segoe UI',
                        letterSpacing: 0.3,
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: isEnabled
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        child: widget.child,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
