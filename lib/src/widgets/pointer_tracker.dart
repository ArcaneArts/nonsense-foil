/// Provides `PointerTracker` to replace accelerometer sensor data
/// with pointer/touch position tracking
library foil;

import 'package:flutter/gestures.dart';
import 'package:nonsense_foil/foil.dart';

import '../common.dart';

/// A callback used to provide a parent with normalized
/// pointer position data as `double`s between `-1..1`.
///
/// [PointerTracker.onPositionChange] is invoked on pointer movement.
typedef PointerCallback = void Function(double normalizedX, double normalizedY);

/// A widget that tracks pointer/touch position and normalizes the coordinates
/// relative to the widget's size.
class PointerTracker extends StatefulWidget {
  const PointerTracker({
    Key? key,
    required this.disabled,
    required this.scalar,
    required this.child,
    required this.onPositionChange,
    this.useRelativePosition = true,
  }) : super(key: key);

  /// If `disabled` is `true`, then this `PointerTracker`
  /// will stop tracking pointer movement.
  final bool disabled;

  /// Scale factor for pointer movement values
  final Scalar scalar;

  /// The `child` of this tracker, returned from `build`.
  final Widget child;

  /// When true, position is relative to initial touch/hover position
  /// When false, position is based on absolute position within the widget
  final bool useRelativePosition;

  /// Callback that delivers normalized pointer position values
  final PointerCallback onPositionChange;

  @override
  _PointerTrackerState createState() => _PointerTrackerState();
}

class _PointerTrackerState extends State<PointerTracker> {
  /// Current normalized x,y position (-1.0 to 1.0)
  double normalizedX = 0.0;
  double normalizedY = 0.0;

  /// Capture the initial position for relative movement
  Offset? initialPosition;

  /// Reference to the render box for size calculations
  final GlobalKey _containerKey = GlobalKey();

  /// Track if pointer is currently inside the widget
  bool isPointerDown = false;

  /// Normalize position values to the -1.0 to 1.0 range
  void _updatePosition(Offset position) {
    if (widget.disabled) return;

    final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;

    Offset effectivePosition;
    if (widget.useRelativePosition && initialPosition != null) {
      // Calculate relative movement from initial position
      effectivePosition = position - initialPosition!;

      // Scale relative movement to be more noticeable
      // Normalize to -1.0 to 1.0 based on half the widget size
      normalizedX = (effectivePosition.dx / (size.width / 2)).clamp(-1.0, 1.0) * widget.scalar.horizontal;
      normalizedY = (effectivePosition.dy / (size.height / 2)).clamp(-1.0, 1.0) * widget.scalar.vertical;
    } else {
      // Use absolute position within the widget
      // Convert from widget coordinates (0 to width/height) to -1.0 to 1.0
      normalizedX = ((position.dx / size.width) * 2 - 1).clamp(-1.0, 1.0) * widget.scalar.horizontal;
      normalizedY = ((position.dy / size.height) * 2 - 1).clamp(-1.0, 1.0) * widget.scalar.vertical;
    }

    widget.onPositionChange(normalizedX, normalizedY);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.disabled) return;

    final RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    setState(() {
      isPointerDown = true;
      initialPosition = localPosition;
    });

    _updatePosition(localPosition);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.disabled || !isPointerDown) return;

    final RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    _updatePosition(localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.disabled) return;

    setState(() {
      isPointerDown = false;

      // Optional: Reset position when pointer is released
      // normalizedX = 0.0;
      // normalizedY = 0.0;
      // widget.onPositionChange(normalizedX, normalizedY);
    });
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (widget.disabled || isPointerDown) return;

    final renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    _updatePosition(localPosition);
  }

  // @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerHover: _handlePointerHover,
      child: Container(
        key: _containerKey,
        width: double.infinity,
        height: double.infinity,
        child: widget.child,
      ),
    );
  }
}

// File: lib/src/widgets/foil.dart (updated version)
// Note: Only showing the changes in the _FoilState class

class _FoilState extends State<Foil> {
  /// Ranges from `-1.0..1.0` based on pointer position
  double normalizedX = 0, normalizedY = 0;

  /// Values come from [rollController] which drives an animation from any
  /// potential ancestral [Roll.crinkle]'s `Crinkle.min` -> `Crinkle.max`
  /// values. Further multiplied by `Crinkle.scalar`, a [Scalar] that allows
  /// per-axis scaling (up, down, negation, inversion).
  double rollX = 0, rollY = 0;

  /// A potential value from an [AnimationController]
  /// in a potential ancestral [Roll].
  ValueListenable? rollController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (rollController != null) {
      rollController!.removeListener(onRollChange);
    }
    rollController = Roll.of(context)?.rollListenable;
    if (rollController != null) {
      rollController!.addListener(onRollChange);
    }
  }

  @override
  void dispose() {
    rollController?.removeListener(onRollChange);
    super.dispose();
  }

  void onRollChange() => (!widget.isUnwrapped) ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    /// There may be a [Roll] above this `Foil`.
    final roll = Roll.of(context);
    final gradient = widget.gradient ?? roll?.gradient ?? Foils.linearLooping;

    /// For smoother `lerp`s when unwrapping `Foil`.
    final effectiveGradient = widget.isUnwrapped
        ? widget.unwrappedGradient ?? gradient.asNill
        : gradient.scale(widget.opacity); // scale() controls overall opacity

    /// The `PointerTracker` and `AnimatedFoil` need to be built regardless of
    /// whether a parent `Roll.crinkle.isAnimated` or not (or even exists).
    Widget _foil() => PointerTracker(
      disabled: widget.isUnwrapped,
      scalar: widget.scalar,
      onPositionChange: (x, y) => setState(() {
        normalizedX = x;
        normalizedY = y;
      }),
      child: AnimatedFoil(
        gradient: effectiveGradient,
        rolloutX: [rollX, normalizedX],
        rolloutY: [rollY, normalizedY],
        blendMode: widget.blendMode,
        useSensor: widget.useSensor, // renamed but kept for compatibility
        isAgressive: widget.isAgressive,
        speed: widget.speed,
        duration: widget.duration,
        curve: widget.curve,
        onEnd: widget.onEnd,
        child: widget.box ?? widget.child, // _box created by `Foil.sheet`
      ),
    );

    return (roll != null && roll.isAnimated)
        ? ValueListenableBuilder(
      valueListenable: rollController!,
      builder: (_, value, child) {
        rollX = roll.scalar.horizontal * (value as double);
        rollY = roll.scalar.vertical * value;
        return _foil();
      },
    )
        : _foil();
  }
}