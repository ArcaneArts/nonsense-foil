library foil;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../models/scalar.dart';

/// Function signature for callbacks that report normalized pointer position.
///
/// The [normalizedX] and [normalizedY] parameters represent the pointer position
/// normalized to a range of -1.0 to 1.0, where (0,0) is the center of the tracking area.
typedef PointerCallback = void Function(double normalizedX, double normalizedY);

/// A widget that tracks pointer movements and reports normalized positions.
///
/// This widget replaces the previous accelerometer-based implementation and
/// provides similar functionality but using pointer (mouse/touch) input instead.
/// It normalizes pointer positions to a range of -1.0 to 1.0 and applies
/// scaling based on the provided [scalar].
///
/// When [useRelativePosition] is true, the widget tracks movement relative to the
/// initial touch position rather than absolute position within the widget bounds.
///
/// Use this widget when you need to create effects that respond to pointer movement,
/// such as the rainbow shimmer effect in [Foil].
class PointerTracker extends StatefulWidget {
  /// Creates a [PointerTracker] widget.
  ///
  /// The [disabled] parameter controls whether pointer tracking is active.
  /// The [scalar] parameter adjusts the sensitivity of the tracking.
  /// The [onPositionChange] callback is called whenever the pointer position changes.
  /// The [useRelativePosition] parameter determines whether tracking should be
  /// relative to the initial pointer position or absolute within the widget bounds.
  const PointerTracker({
    Key? key,
    required this.disabled,
    required this.scalar,
    required this.child,
    required this.onPositionChange,
    this.useRelativePosition = true,
  }) : super(key: key);

  /// Whether pointer tracking is disabled.
  ///
  /// When true, pointer movements will not trigger the [onPositionChange] callback.
  final bool disabled;

  /// Scaling factors to apply to normalized pointer position values.
  ///
  /// This allows adjusting sensitivity independently on each axis.
  final Scalar scalar;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether to track movement relative to initial touch position.
  ///
  /// When true, movements are reported relative to where the pointer first
  /// contacted the widget, making (0,0) the initial touch point.
  /// When false, positions are reported relative to the widget's bounds,
  /// with (0,0) being the center of the widget.
  final bool useRelativePosition;

  /// Callback that receives normalized pointer position.
  ///
  /// Called whenever the pointer position changes with values
  /// normalized to -1.0 to 1.0 on both axes and scaled by [scalar].
  final PointerCallback onPositionChange;

  @override
  _PointerTrackerState createState() => _PointerTrackerState();
}

/// State for the [PointerTracker] widget.
class _PointerTrackerState extends State<PointerTracker> {
  /// Current normalized X coordinate in the range -1.0 to 1.0.
  double normalizedX = 0.0;

  /// Current normalized Y coordinate in the range -1.0 to 1.0.
  double normalizedY = 0.0;

  /// Initial position where the pointer made contact.
  ///
  /// Used when [PointerTracker.useRelativePosition] is true to
  /// calculate relative movement from the initial touch point.
  Offset? initialPosition;

  /// Key used to get the render box for position calculations.
  final GlobalKey _containerKey = GlobalKey();

  /// Whether a pointer is currently in contact with the widget.
  bool isPointerDown = false;

  /// Updates the normalized position based on pointer location.
  ///
  /// Calculates normalized coordinates (-1.0 to 1.0) based on the pointer
  /// position relative to widget bounds or initial position, then calls
  /// [PointerTracker.onPositionChange] with the scaled values.
  void _updatePosition(Offset position) {
    if (widget.disabled) return;

    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;

    Offset effectivePosition;
    if (widget.useRelativePosition && initialPosition != null) {
      // Calculate position relative to initial touch point
      effectivePosition = position - initialPosition!;
      normalizedX =
          (effectivePosition.dx / (size.width / 2)).clamp(-1.0, 1.0) *
          widget.scalar.horizontal;
      normalizedY =
          (effectivePosition.dy / (size.height / 2)).clamp(-1.0, 1.0) *
          widget.scalar.vertical;
    } else {
      // Calculate position relative to widget center
      normalizedX =
          ((position.dx / size.width) * 2 - 1).clamp(-1.0, 1.0) *
          widget.scalar.horizontal;
      normalizedY =
          ((position.dy / size.height) * 2 - 1).clamp(-1.0, 1.0) *
          widget.scalar.vertical;
    }

    widget.onPositionChange(normalizedX, normalizedY);
  }

  /// Handles initial pointer contact.
  ///
  /// Stores the initial position for relative tracking and updates
  /// the current position.
  void _handlePointerDown(PointerDownEvent event) {
    if (widget.disabled) return;

    final RenderBox renderBox =
        _containerKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    setState(() {
      isPointerDown = true;
      initialPosition = localPosition;
    });

    _updatePosition(localPosition);
  }

  /// Handles pointer movement when in contact with the widget.
  ///
  /// Updates position based on the current pointer location.
  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.disabled || !isPointerDown) return;

    final RenderBox renderBox =
        _containerKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    _updatePosition(localPosition);
  }

  /// Handles pointer release.
  ///
  /// Marks the pointer as no longer in contact with the widget.
  void _handlePointerUp(PointerUpEvent event) {
    if (widget.disabled) return;

    setState(() {
      isPointerDown = false;
    });
  }

  /// Handles pointer hover when not in contact with the widget.
  ///
  /// Updates position based on hover location for desktop and web platforms.
  void _handlePointerHover(PointerHoverEvent event) {
    if (widget.disabled || isPointerDown) return;

    final renderBox =
        _containerKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    _updatePosition(localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerHover: _handlePointerHover,
      child: SizedBox(
        key: _containerKey,
        width: double.infinity,
        height: double.infinity,
        child: widget.child,
      ),
    );
  }
}
