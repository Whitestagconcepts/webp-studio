import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math' as math;

class SpiralSpinner extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final Duration duration;
  final bool isVisible;
  final VoidCallback? onAnimationComplete;

  const SpiralSpinner({
    super.key,
    this.size = 60.0,
    this.color = Colors.blue,
    this.strokeWidth = 4.0,
    this.duration = const Duration(milliseconds: 2000),
    this.isVisible = true,
    this.onAnimationComplete,
  });

  @override
  State<SpiralSpinner> createState() => _SpiralSpinnerState();
}

class _SpiralSpinnerState extends State<SpiralSpinner>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _speedController;
  late AnimationController _fadeOutController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _speedAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.isVisible;
    
    // Main rotation controller
    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Speed variation controller (tail chase effect)
    _speedController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds * 3),
      vsync: this,
    );
    
    // 3D fade-out controller
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Rotation animation (continuous)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    
    // Speed variation animation (tail chase speed up/slow down)
    _speedAnimation = Tween<double>(
      begin: 0.3,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _speedController,
      curve: Curves.easeInOutSine,
    ));
    
    // 3D shrinking scale animation (1.0 to 0.0)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeOutController,
      curve: Curves.easeInQuart, // Accelerating into the distance
    ));
    
    // Opacity fade animation (1.0 to 0.0)
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeOutController,
      curve: Curves.easeOutQuad, // Slower fade for realistic 3D effect
    ));
    
    // Listen for fade-out completion
    _fadeOutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
    
    // Start continuous animations if visible
    if (_isVisible) {
      _rotationController.repeat();
      _speedController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SpiralSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle visibility changes
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        // Show: Reset and start animations
        _fadeOutController.reset();
        _rotationController.repeat();
        _speedController.repeat(reverse: true);
        setState(() {
          _isVisible = true;
        });
      } else {
        // Hide: Start 3D fade-out animation
        _startFadeOut();
      }
    }
  }

  void _startFadeOut() {
    // Stop rotation animations smoothly
    _rotationController.stop();
    _speedController.stop();
    
    // Start the 3D fade-out effect
    _fadeOutController.forward().then((_) {
      setState(() {
        _isVisible = false;
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _speedController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible && _fadeOutController.isDismissed) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation, 
          _speedAnimation, 
          _scaleAnimation, 
          _opacityAnimation
        ]),
        builder: (context, child) {
          // Apply speed variation to rotation
          final adjustedRotation = _rotationAnimation.value * _speedAnimation.value;
          
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.rotate(
                angle: adjustedRotation,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: SpiralPainter(
                    color: widget.color,
                    strokeWidth: widget.strokeWidth,
                    progress: _rotationAnimation.value,
                    speedFactor: _speedAnimation.value,
                    fadeProgress: _fadeOutController.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SpiralPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;
  final double speedFactor;
  final double fadeProgress;

  SpiralPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
    required this.speedFactor,
    required this.fadeProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - strokeWidth;
    
    // LDRS Spiral: Simple growing spiral with dots at ends
    const int segments = 80;
    const double turns = 2.5; // How many turns the spiral makes
    
    // Main spiral paint
    final spiralPaint = Paint()
      ..color = color.withValues(alpha: 0.8 * (1.0 - fadeProgress))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw the main spiral path
    final path = Path();
    bool pathStarted = false;
    
    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      
      // Spiral grows from center outward
      final spiralRadius = maxRadius * t * 0.9;
      
      // Angle increases to create spiral + rotation animation
      final angle = (t * turns * 2 * math.pi) + (progress * 2 * math.pi);
      
      final x = center.dx + spiralRadius * math.cos(angle);
      final y = center.dy + spiralRadius * math.sin(angle);
      
      if (!pathStarted) {
        path.moveTo(x, y);
        pathStarted = true;
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Draw the spiral
    canvas.drawPath(path, spiralPaint);
    
    // Draw dots at the spiral ends (LDRS style)
    const int numDots = 6;
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.9 * (1.0 - fadeProgress))
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < numDots; i++) {
      final t = (segments - numDots + i) / segments;
      final spiralRadius = maxRadius * t * 0.9;
      final angle = (t * turns * 2 * math.pi) + (progress * 2 * math.pi);
      
      final x = center.dx + spiralRadius * math.cos(angle);
      final y = center.dy + spiralRadius * math.sin(angle);
      
      // Dots get smaller towards the center
      final dotSize = strokeWidth * (0.3 + t * 0.7);
      canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
    }
    
    // Center dot
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.7 * (1.0 - fadeProgress))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, strokeWidth * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant SpiralPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.speedFactor != speedFactor ||
           oldDelegate.fadeProgress != fadeProgress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

// Rotating Pulsing Grid Spinner
class RotatingPulseGrid extends StatefulWidget {
  final double size;
  final Color color;
  final bool isVisible;
  final VoidCallback? onAnimationComplete;

  const RotatingPulseGrid({
    super.key,
    this.size = 48.0,
    this.color = Colors.blue,
    this.isVisible = true,
    this.onAnimationComplete,
  });

  @override
  State<RotatingPulseGrid> createState() => _RotatingPulseGridState();
}

class _RotatingPulseGridState extends State<RotatingPulseGrid>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeOutController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Slow rotation controller
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 8000), // Very slow 8-second rotation
      vsync: this,
    );

    // 3D fade-out controller
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear, // Smooth constant rotation
    ));

    // 3D shrinking scale animation
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeOutController,
      curve: Curves.easeInQuart,
    ));

    // Opacity fade animation
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeOutController,
      curve: Curves.easeOutQuad,
    ));

    // Listen for fade-out completion
    _fadeOutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // Start rotation if visible
    if (widget.isVisible) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(RotatingPulseGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        // Show: Reset and start rotation
        _fadeOutController.reset();
        _rotationController.repeat();
      } else {
        // Hide: Start 3D fade-out
        _startFadeOut();
      }
    }
  }

  void _startFadeOut() {
    _rotationController.stop();
    _fadeOutController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _fadeOutController.isDismissed) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _scaleAnimation,
          _opacityAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: SpinKitPulsingGrid(
                  color: widget.color,
                  size: widget.size,
                  duration: const Duration(milliseconds: 1200), // Pulsing speed
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Convenience widget for common use cases
class WebPSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final bool isVisible;
  final VoidCallback? onAnimationComplete;

  const WebPSpinner({
    super.key,
    this.size = 48.0,
    this.color,
    this.isVisible = true,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return RotatingPulseGrid(
      size: size,
      color: color ?? Theme.of(context).colorScheme.primary,
      isVisible: isVisible,
      onAnimationComplete: onAnimationComplete,
    );
  }
}