// import 'package:vector_math/vector_math_64.dart';
import 'package:three_js_math/three_js_math.dart';

const distEpsilon = 1e-5;
const angleEpsilon = 1e-4;

class RaySet {
  final List<Ray> _rays = [];

  void addRay(Ray ray) {
    _rays.add(ray);
  }

  Ray? findClosestRay(Ray ray) {
    bool skipRay(Ray r0, Ray r1) {
      final bool distOutOfThreshold = r0.origin.distanceTo(r1.origin) > distEpsilon;
      final bool angleOutOfThreshold = r0.direction.angleTo(r1.direction) > angleEpsilon;
      return angleOutOfThreshold || distOutOfThreshold;
    }

    double scoreRays(Ray r0, Ray r1) {
      final double originDistance = r0.origin.distanceTo(r1.origin);
      final double angleDistance = r0.direction.angleTo(r1.direction);
      return originDistance / distEpsilon + angleDistance / angleEpsilon;
    }

    final rays = _rays;
    Ray inv = Ray();
    inv.copyFrom(ray);
    inv.direction.scale(-1);

    double bestScore = double.infinity;
    Ray? bestRay;

    for (int i = 0, l = rays.length; i < l; i++) {
      var r = rays[i];

      if (skipRay(r, ray) && skipRay(r, inv)) {
        continue;
      }

      final rayScore = scoreRays(r, ray);
      final invScore = scoreRays(r, inv);
      var score = rayScore < invScore ? rayScore : invScore;

      if (score < bestScore) {
        bestScore = score;
        bestRay = r;
      }
    }

    return bestRay;
  }
}
