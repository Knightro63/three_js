import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/three_js_math.dart";

class ClippingGroup extends Group {
  bool isClippingGroup = true;
  final List<Plane> clippingPlanes = [];
  bool enabled = true;
  bool clipIntersection = false;
  bool clipShadows = false;

	ClippingGroup():super();
}
