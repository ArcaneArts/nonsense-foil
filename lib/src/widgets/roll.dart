// WORK IN PROGRESS
/// Provides `Roll` for defining a large area for a gradient shader
/// to apply to each `Foil` underneath it.
library foil;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/crinkle.dart';
import '../models/scalar.dart';
import '../models/transformation.dart';

/// A widget that provides shared gradient and animation properties to descendant [Foil] widgets.
///
/// The [Roll] widget acts as a coordinator for multiple [Foil] instances,
/// allowing them to share a common gradient and animation characteristics.
/// This creates a cohesive visual effect across multiple elements.
///
/// A [Roll] can provide:
/// 1. A shared [gradient] that descendant [Foil] widgets can use
/// 2. Animation parameters through [crinkle] that affect how foil effects animate
///
/// In the future, this widget will also support creating a single gradient sheet
/// that spans the entire Roll area, with descendant Foils using portions of that
/// shared gradient.
///
/// ![animated by Roll.crinkle](https://raw.githubusercontent.com/Zabadam/foil/master/doc/crinkle_small.gif)
class Roll extends StatefulWidget with Diagnosticable {
  /// Creates a Roll that can provide gradient and animation properties to descendant [Foil] widgets.
  ///
  /// The [gradient] parameter specifies a shared gradient that descendant [Foil]
  /// widgets can use if they don't specify their own.
  ///
  /// The [crinkle] parameter (defaults to [Crinkle.smooth]) provides animation
  /// properties that affect how descendant [Foil] widgets animate their gradients.
  /// This animation works independently from pointer tracking.
  ///
  /// The [child] parameter is the widget below this widget in the tree.
  const Roll({
    Key? key,
    this.gradient,
    this.crinkle = Crinkle.smooth,
    this.child,
  }) : super(key: key);

  /// The gradient to share with descendant [Foil] widgets.
  ///
  /// If a descendant [Foil] doesn't specify its own gradient, it will use this gradient.
  /// If this is null and a [Foil] doesn't specify its own gradient, the [Foil]
  /// will fall back to [Foils.linearLooping].
  final Gradient? gradient;

  /// Animation properties for descendant [Foil] widgets.
  ///
  /// The [crinkle] parameter controls how descendant [Foil] widgets animate
  /// their gradients. This animation works independently from and in addition to
  /// any pointer tracking animation. The default [Crinkle.smooth] provides no animation.
  final Crinkle crinkle;

  /// The widget below this widget in the tree.
  final Widget? child;

  /// Finds and returns the nearest ancestor [RollState] in the widget tree.
  ///
  /// This allows descendant [Foil] widgets to access the [Roll]'s properties
  /// such as its gradient and animation settings. Returns null if no
  /// ancestor [Roll] is found.
  static RollState? of(BuildContext context) =>
      context.findAncestorStateOfType<RollState>();

  @override
  RollState createState() => RollState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Crinkle>('crinkle', crinkle, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<Gradient>('gradient', gradient, defaultValue: null),
      );
  }
}

/// State class for [Roll] that manages animations and provides properties to descendant [Foil] widgets.
///
/// This class manages the animation controller for [Crinkle] animations and
/// provides access to properties such as the gradient and transformation
/// functions needed by descendant [Foil] widgets.
class RollState extends State<Roll> with SingleTickerProviderStateMixin {
  /// Animation controller for crinkle animations.
  ///
  /// This controller is set up with the animation properties specified
  /// in the [Roll.crinkle] and drives the gradient animations for
  /// descendant [Foil] widgets.
  AnimationController? _rollController;

  /// The animation controller as a [ValueListenable].
  ///
  /// Descendant [Foil] widgets listen to this to animate their gradients
  /// based on the [Roll.crinkle] properties.
  ValueListenable? get rollListenable => _rollController;

  /// The gradient to share with descendant [Foil] widgets.
  ///
  /// If a descendant [Foil] doesn't specify its own gradient, it will use this gradient.
  Gradient? get gradient => widget.gradient;

  /// Whether this [Roll] provides animations for descendant [Foil] widgets.
  ///
  /// When true, descendant [Foil] widgets will animate their gradients based on
  /// the [Roll.crinkle] properties, in addition to any pointer tracking animations.
  bool get isAnimated => widget.crinkle.isAnimated;

  /// The scaling factors for gradient animations.
  ///
  /// These factors adjust the intensity of gradient animations independently
  /// on each axis.
  Scalar get scalar => widget.crinkle.scalar;

  /// The transformation function for gradient animations.
  ///
  /// This function controls how the gradient is transformed during animations.
  /// If null, a default [TranslateGradient] will be used.
  TransformGradient? get transform => widget.crinkle.transform;

  /// The current size of this [Roll] widget.
  ///
  /// This is used for positioning calculations when the future shared gradient
  /// sheet functionality is implemented.
  Size get size => (context.findRenderObject() as RenderBox).size;

  /// Whether this [Roll] widget has determined its size.
  ///
  /// Used to ensure size-dependent operations are only performed after layout.
  bool get isSized =>
      (context.findRenderObject() == null)
          ? false
          : (context.findRenderObject() as RenderBox).hasSize;

  /// Calculates the offset of a descendant widget relative to this [Roll].
  ///
  /// This will be used in the future for the shared gradient sheet functionality
  /// to determine which portion of the gradient each descendant [Foil] should use.
  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) => descendant.localToGlobal(
    offset,
    ancestor: context.findRenderObject() as RenderBox,
  );

  @override
  void initState() {
    super.initState();
    _initController();
  }

  /// Initializes the animation controller with [Crinkle] properties.
  ///
  /// Creates an unbounded [AnimationController] that repeats according to
  /// the properties specified in [Roll.crinkle], such as min/max values,
  /// animation period, and whether the animation should reverse direction.
  void _initController() {
    _rollController = AnimationController.unbounded(vsync: this)..repeat(
      // TODO: update these values if changed
      min: widget.crinkle.min,
      max: widget.crinkle.max,
      period: widget.crinkle.period,
      reverse: widget.crinkle.shouldReverse,
    );
  }

  @override
  void dispose() {
    _rollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox();
}
