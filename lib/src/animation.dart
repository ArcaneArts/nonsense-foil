library foil;

import 'package:nonsense_foil/nonsense_foil.dart';
import 'widgets/roll.dart';

/// An implicitly animated widget for Foil gradients.
///
/// This widget handles the animation of gradients for [Foil] widgets,
/// providing smooth transitions between gradient states. It supports
/// animations for both gradient colors and positions.
///
/// The [AnimatedFoil] widget works in conjunction with [RolledOutFoil]
/// to create the complete foil effect with animated transformations.
class AnimatedFoil extends ImplicitlyAnimatedWidget {
  /// Creates an animated foil effect.
  ///
  /// The [gradient] parameter defines the gradient to be displayed.
  /// The [rolloutX] and [rolloutY] parameters control the positioning
  /// of the gradient based on pointer or roll animations.
  /// The [blendMode] determines how the gradient is blended with the child.
  /// The [useSensor] parameter controls whether pointer input affects the gradient.
  /// The [isAgressive] parameter controls the gradient lerp method.
  /// The [duration] parameter sets how long the gradient animation will take.
  /// The [curve] parameter defines the animation curve.
  const AnimatedFoil({
    Key? key,
    required this.gradient,
    required this.rolloutX,
    required this.rolloutY,
    required this.blendMode,
    required this.useSensor,
    required this.isAgressive,
    required this.child,
    required this.speed,
    required Duration duration,
    Curve curve = Curves.linear,
    VoidCallback? onEnd,
  }) : super(key: key, duration: duration, curve: curve, onEnd: onEnd);

  /// The gradient to display.
  ///
  /// This gradient will be animated when it changes, transitioning
  /// smoothly from the previous gradient to the new one.
  final Gradient? gradient;

  /// The horizontal offset factors for the gradient.
  ///
  /// Contains values that control the horizontal positioning of the gradient.
  /// Usually has two values: one from Roll animation and one from pointer tracking.
  final List<double> rolloutX;

  /// The vertical offset factors for the gradient.
  ///
  /// Contains values that control the vertical positioning of the gradient.
  /// Usually has two values: one from Roll animation and one from pointer tracking.
  final List<double> rolloutY;

  /// The blend mode used to composite the gradient over the child.
  final BlendMode blendMode;

  /// Whether pointer input affects the gradient position.
  final bool useSensor;

  /// Controls how gradients are interpolated during animation.
  ///
  /// When true, uses a more direct interpolation method that
  /// may produce more dramatic transitions between certain gradients.
  final bool isAgressive;

  /// The widget to display with the animated gradient effect.
  final Widget child;

  /// How quickly the gradient responds to pointer movement.
  ///
  /// This duration controls the animation speed for translating the
  /// gradient in response to pointer or sensor input.
  final Duration speed;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedFoilState();
}

/// State class for [AnimatedFoil] that handles gradient animations.
class _AnimatedFoilState extends AnimatedWidgetBaseState<AnimatedFoil> {
  /// The tween that animates between different gradients.
  GradientTween? _gradient;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) =>
      _gradient =
          visitor(
                _gradient,
                widget.gradient,
                (dynamic value) => GradientTween(
                  begin: value as Gradient,
                  isAgressive: widget.isAgressive,
                ),
              )
              as GradientTween?;

  @override
  Widget build(BuildContext context) => RolledOutFoil(
    gradient: _gradient!.evaluate(animation)!,
    rolloutX: widget.rolloutX,
    rolloutY: widget.rolloutY,
    blendMode: widget.blendMode,
    duration: widget.speed,
    curve: widget.curve,
    useSensor: widget.useSensor,
    child: widget.child,
  );
}

/// An implicitly animated widget that handles position animations for foil effects.
///
/// This widget takes a gradient and animates its position based on the
/// rollout values, which can come from pointer tracking and/or Roll animations.
/// It works as a second animation layer after [AnimatedFoil] handles the
/// gradient color animations.
///
/// This class is responsible for the smooth movement of the gradient as the
/// user interacts with the widget or as Roll animations progress.
class RolledOutFoil extends ImplicitlyAnimatedWidget {
  /// Creates a position-animated foil effect.
  ///
  /// The [gradient] parameter is the current gradient to display.
  /// The [rolloutX] and [rolloutY] parameters control the target positions
  /// of the gradient based on pointer input and/or Roll animations.
  /// The [blendMode] determines how the gradient is blended with the child.
  /// The [useSensor] parameter controls whether pointer input affects the gradient.
  /// The [duration] parameter sets how long position animations will take.
  /// The [curve] parameter defines the animation curve.
  const RolledOutFoil({
    Key? key,
    required this.gradient,
    required this.rolloutX,
    required this.rolloutY,
    required this.child,
    required this.blendMode,
    required this.useSensor,
    required Duration duration,
    Curve curve = Curves.linear,
  }) : super(key: key, duration: duration, curve: curve);

  /// The gradient to display and animate.
  final Gradient gradient;

  /// The horizontal offset factors for the gradient position.
  ///
  /// Usually contains two values:
  /// - The first from Roll animation
  /// - The second from pointer tracking
  final List<double> rolloutX;

  /// The vertical offset factors for the gradient position.
  ///
  /// Usually contains two values:
  /// - The first from Roll animation
  /// - The second from pointer tracking
  final List<double> rolloutY;

  /// The blend mode used to composite the gradient over the child.
  final BlendMode blendMode;

  /// Whether pointer input affects the gradient position.
  final bool useSensor;

  /// The widget to display with the animated gradient effect.
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _RolledOutFoilState();
}

/// State class for [RolledOutFoil] that handles position animations.
///
/// This state class manages the tweens for animating gradient positions
/// based on rollout values from pointer tracking and Roll animations.
class _RolledOutFoilState extends AnimatedWidgetBaseState<RolledOutFoil> {
  /// Tweens for each of the rollout values.
  ///
  /// These tweens handle the animation of gradient position factors:
  /// - _rolloutX1 and _rolloutY1 are for Roll animation values
  /// - _rolloutX2 and _rolloutY2 are for pointer tracking values
  Tween<double>? _rolloutX1, _rolloutY1, _rolloutX2, _rolloutY2;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    // Set up tweens for horizontal Roll animation value
    _rolloutX1 =
        visitor(
              _rolloutX1,
              widget.rolloutX[0],
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;

    // Set up tweens for vertical Roll animation value
    _rolloutY1 =
        visitor(
              _rolloutY1,
              widget.rolloutY[0],
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;

    // Set up tweens for horizontal pointer tracking value
    _rolloutX2 =
        visitor(
              _rolloutX2,
              widget.rolloutX[1],
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;

    // Set up tweens for vertical pointer tracking value
    _rolloutY2 =
        visitor(
              _rolloutY2,
              widget.rolloutY[1],
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    // Get the ancestral Roll to access its gradient transform
    final roll = Roll.of(context);

    // Build the static foil with animated position values
    return StaticFoil(
      gradient: widget.gradient,
      rolloutX: [
        _rolloutX1?.evaluate(animation) ?? 0.0,
        _rolloutX2?.evaluate(animation) ?? 0.0,
      ],
      rolloutY: [
        _rolloutY1?.evaluate(animation) ?? 0.0,
        _rolloutY2?.evaluate(animation) ?? 0.0,
      ],
      blendMode: widget.blendMode,
      useSensor: widget.useSensor,
      transform: roll?.transform,
      child: widget.child,
    );
  }
}
