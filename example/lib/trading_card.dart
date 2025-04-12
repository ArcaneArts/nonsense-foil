/// Provides a `TradingCard` widget that reacts to pointer movement.
///
/// Uses [Transform] to create a parallax-like effect when the pointer moves over the card.
library foil_demo;

import 'package:nonsense_foil/nonsense_foil.dart';

/// Creates a `TradingCard` widget that reacts to pointer movement.
///
/// This implementation uses a custom pointer tracking approach with Transform
/// to create a parallax effect similar to what was previously done with
/// the xl package, but aligned with the new pointer-based tracking system.
class TradingCard extends StatefulWidget {
  /// Creates a `TradingCard` widget that reacts to pointer movement.
  const TradingCard({
    Key? key,
    required this.card,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(75.0),
  }) : super(key: key);

  /// A `String` representing a url leading to an image.
  final String card;

  /// Constrain the dimensions of this `TradingCard`.
  final double? width, height;

  /// Pad this `TradingCard` so a `Foil` that wraps it may have extra room
  /// in the gradient shader to accommodate this widget's transform as it animates.
  final EdgeInsets padding;

  @override
  State<TradingCard> createState() => _TradingCardState();
}

class _TradingCardState extends State<TradingCard> {
  // Values for transform
  double _offsetX = 0;
  double _offsetY = 0;
  double _rotateX = 0;
  double _rotateY = 0;

  // Constants for animation
  final double _maxRotation = 0.05;
  final double _maxOffset = 15.0;

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      widget.card,
      frameBuilder: (_, child, currentFrame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: currentFrame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
          child: child,
        );
      },
    );

    return Padding(
      padding: widget.padding,
      child: PointerTracker(
        disabled: false,
        scalar: const Scalar(horizontal: 1.0, vertical: 1.0),
        useRelativePosition: false,
        onPositionChange: (x, y) {
          setState(() {
            // Map normalized values (-1.0 to 1.0) to appropriate ranges
            _offsetX = x * _maxOffset;
            _offsetY = y * _maxOffset;
            _rotateX = -y * _maxRotation; // Invert Y for natural rotation
            _rotateY = x * _maxRotation;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width ?? MediaQuery.of(context).size.width,
          height: widget.height ?? MediaQuery.of(context).size.height,
          child: Transform(
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateX(_rotateX)
                  ..rotateY(_rotateY)
                  ..translate(_offsetX, _offsetY),
            alignment: Alignment.center,
            child: Center(child: image),
          ),
        ),
      ),
    );
  }
}
