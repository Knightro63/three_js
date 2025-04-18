import '../core/index.dart';
import 'dart:js_interop';

@JS('BoxGeometry')
class BoxGeometry extends BufferGeometry {
  external BoxGeometry([
    double width = 1,
    double height = 1,
    double depth = 1,
    int widthSegments = 1,
    int heightSegments = 1,
    int depthSegments = 1
  ]);

  static BoxGeometry fromJson(Map<String,dynamic> data) {
    return BoxGeometry(data["width"], data["height"], data["depth"],
        data["widthSegments"], data["heightSegments"], data["depthSegments"]);
  }
}
