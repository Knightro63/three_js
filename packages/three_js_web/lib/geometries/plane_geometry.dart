import '../core/index.dart';
import 'dart:js_interop';

@JS('PlaneGeometry')
class PlaneGeometry extends BufferGeometry {
  external PlaneGeometry([
    double width = 1,
    double height = 1,
    int widthSegments = 1,
    int heightSegments = 1]
  );

  static fromJson(data) {
    return PlaneGeometry(data["width"], data["height"],
        data["widthSegments"], data["heightSegments"]);
  }
}
