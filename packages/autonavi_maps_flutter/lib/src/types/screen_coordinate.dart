/// A 2D pixel coordinate in screen space.
class ScreenCoordinate {
  const ScreenCoordinate({required this.x, required this.y});

  /// The x (horizontal) component of the coordinate.
  final int x;

  /// The y (vertical) component of the coordinate.
  final int y;

  Map<String, int> toJson() => {'x': x, 'y': y};

  factory ScreenCoordinate.fromJson(Map<dynamic, dynamic> json) =>
      ScreenCoordinate(
        x: (json['x'] as num).toInt(),
        y: (json['y'] as num).toInt(),
      );

  @override
  String toString() => 'ScreenCoordinate(x: $x, y: $y)';

  @override
  bool operator ==(Object other) =>
      other is ScreenCoordinate && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
