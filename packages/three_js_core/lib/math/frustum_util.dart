import '../objects/sprite.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import '../core/object_3d.dart';
import 'package:three_js_math/three_js_math.dart';

final _sphere = BoundingSphere();

extension FrustumUtil on vmath.Frustum{
  bool intersectsObject(Object3D object) {
    final geometry = object.geometry;
    if (geometry == null) return false;

    if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

    _sphere.setFrom(geometry.boundingSphere!);

    _sphere.applyMatrix4(object.matrixWorld);

    return intersectsSphere(_sphere);
  }

  bool intersectsSphere(BoundingSphere sphere) {
    final planes = [plane0,plane1,plane2,plane3,plane4,plane5];
    final center = sphere.center;
    final negRadius = -sphere.radius;

    for (int i = 0; i < 6; i++) {
      final distance = planes[i].distanceToVector3((center as vmath.Vector3));
      if (distance < negRadius) {
        return false;
      }
    }

    return true;
  }

  bool intersectsSprite(Sprite sprite) {
    _sphere.center.setValues(0, 0, 0);
    _sphere.radius = 0.7071067811865476;
    _sphere.applyMatrix4(sprite.matrixWorld);

    return intersectsSphere(_sphere);
  }
}