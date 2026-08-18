import 'package:flutter/material.dart';

/// Custom gesture detector for swipe cards that reports drag delta
/// and triggers like / dislike thresholds with haptic feedback.
class CardGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback? onSuperLike;
  final double likeThreshold;
  final double dislikeThreshold;

  const CardGestureDetector({
    super.key,
    required this.child,
    required this.onLike,
    required this.onDislike,
    this.onSuperLike,
    this.likeThreshold = 120.0,
    this.dislikeThreshold = -120.0,
  });

  @override
  State<CardGestureDetector> createState() => _CardGestureDetectorState();
}

class _CardGestureDetectorState extends State<CardGestureDetector>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_offset.dx > widget.likeThreshold) {
      _animateOut(const Offset(500, 0), widget.onLike);
    } else if (_offset.dx < widget.dislikeThreshold) {
      _animateOut(const Offset(-500, 0), widget.onDislike);
    } else if (_offset.dy < -150 && widget.onSuperLike != null) {
      _animateOut(const Offset(0, -600), widget.onSuperLike!);
    } else {
      // Snap back
      _controller.reset();
      _animation = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward().then((_) {
        setState(() => _offset = Offset.zero);
      });
    }
  }

  void _animateOut(Offset target, VoidCallback callback) {
    _controller.reset();
    _animation = Tween<Offset>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward().then((_) {
      callback();
      if (mounted) {
        setState(() => _offset = Offset.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_offset.dx / 300) * 0.3;
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentOffset = _controller.isAnimating ? _animation.value : _offset;
          return Transform.translate(
            offset: currentOffset,
            child: Transform.rotate(
              angle: angle,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
