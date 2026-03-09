import 'package:flutter/foundation.dart';

/// A 2D offset where dx and dy represent horizontal and vertical components.
/// Used for anchor positioning of markers and info windows.
@immutable
class Offset {
  const Offset(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  bool operator ==(Object other) =>
      other is Offset && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(dx, dy);
}

/// Text labels for a [Marker] info window.
@immutable
class InfoWindow {
  const InfoWindow({
    this.title,
    this.snippet,
    this.anchor = const Offset(0.5, 0.0),
  });

  /// Text labels specifying that no [InfoWindow] should be displayed.
  static const InfoWindow noText = InfoWindow();

  /// The window's title text.
  final String? title;

  /// The window's snippet text (secondary description below the title).
  final String? snippet;

  /// The anchor point of the InfoWindow with respect to the marker.
  final Offset anchor;

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (snippet != null) 'snippet': snippet,
        'anchor': {'dx': anchor.dx, 'dy': anchor.dy},
      };

  @override
  String toString() => 'InfoWindow(title: $title, snippet: $snippet)';

  @override
  bool operator ==(Object other) =>
      other is InfoWindow &&
      other.title == title &&
      other.snippet == snippet &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(title, snippet, anchor);
}

