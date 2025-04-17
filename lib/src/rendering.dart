library foil;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nonsense_foil/nonsense_foil.dart';
import 'package:nonsense_spectrum/nonsense_spectrum.dart';

class StaticFoil extends SingleChildRenderObjectWidget {
  const StaticFoil({
    Key? key,
    required this.gradient,
    required this.rolloutX,
    required this.rolloutY,
    required this.blendMode,
    required this.useSensor,
    this.transform,
    Widget? child,
  }) : super(key: key, child: child);
  final Gradient gradient;
  final List<double> rolloutX, rolloutY;
  final BlendMode blendMode;
  final bool useSensor;
  final TransformGradient? transform;

  @override
  FoilShader createRenderObject(BuildContext context) {
    assert(
      debugCheckHasDirectionality(
        context,
        why: 'in order for GradientTransform to consider directionality',
      ),
    );
    return FoilShader(
      gradient,
      rolloutX,
      rolloutY,
      blendMode,
      useSensor,
      transform,
      Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, FoilShader renderObject) =>
      renderObject
        ..gradient = gradient
        ..rolloutX = rolloutX
        ..rolloutY = rolloutY
        ..blendMode = blendMode
        ..useSensor = useSensor
        ..transform = transform
        ..directionality = Directionality.maybeOf(context);
}

class FoilShader extends RenderLimitedBox {
  FoilShader(
    this._gradient,
    this._rolloutX,
    this._rolloutY,
    this._blendMode,
    this._useSensor,
    this._transform,
    this._directionality,
  );

  Gradient _gradient;
  List<double> _rolloutX, _rolloutY;
  BlendMode _blendMode;
  bool _useSensor;
  TransformGradient? _transform;
  TextDirection? _directionality;

  set gradient(Gradient gradient) {
    if (_gradient == gradient) return;
    _gradient = gradient;
    markNeedsPaint();
  }

  set rolloutX(List<double> rollout) {
    if (_rolloutX == rollout) return;
    _rolloutX = rollout;
    markNeedsPaint();
  }

  set rolloutY(List<double> rollout) {
    if (_rolloutY == rollout) return;
    _rolloutY = rollout;
    markNeedsPaint();
  }

  set blendMode(BlendMode blendMode) {
    if (_blendMode == blendMode) return;
    _blendMode = blendMode;
    markNeedsPaint();
  }

  set useSensor(bool useSensor) {
    if (_useSensor == useSensor) return;
    _useSensor = useSensor;
    markNeedsPaint();
  }

  set transform(TransformGradient? transform) {
    if (_transform == transform) return;
    _transform = transform;
    markNeedsPaint();
  }

  set directionality(TextDirection? directionality) {
    if (_directionality == directionality) return;
    _directionality = directionality;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);
      final width = child!.size.width;
      final height = child!.size.height;

      /// TODO: Rethink `Gradient.copyWith`
      final gradient =
          (_rolloutX[0] != 0 || _rolloutY[0] != 0)
              ? _gradient.copyWith(
                transform:
                    _transform?.call(_rolloutX[0], _rolloutY[0]) ??
                    TranslateGradient(
                      percentX: _rolloutX[0],
                      percentY: _rolloutY[0],
                    ),
              )
              : _gradient;

      final rect = Rect.fromLTWH(
        (_useSensor ? width * _rolloutX[1] : 0.0),
        (_useSensor ? height * _rolloutY[1] : 0.0),
        width,
        height,
      );

      layer ??= ShaderMaskLayer();
      layer!
        ..shader = gradient.createShader(rect, textDirection: _directionality)
        ..maskRect = offset & size
        ..blendMode = _blendMode;
      context.pushLayer(layer!, super.paint, offset);
    } else {
      layer = null;
    }
  }
}
