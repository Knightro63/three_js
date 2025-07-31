import 'package:three_js/three_js.dart' as three;

class GeometryUtils{
  static List<three.Vector3> hilbert3D([three.Vector3? center, double? size, int? iterations,int? v0,int? v1,int? v2,int? v3,int? v4,int? v5,int? v6,int? v7]) {
    // Default Vars
    center ??= three.Vector3(0, 0, 0);
    size ??= 10;

    var half = size / 2;
    iterations ??= 1;
    v0 ??= 0;
    v1 ??= 1;
    v2 ??= 2;
    v3 ??= 3;
    v4 ??= 4;
    v5 ??= 5;
    v6 ??= 6;
    v7 ??= 7;

    var vecS = [
      three.Vector3(center.x - half, center.y + half, center.z - half),
      three.Vector3(center.x - half, center.y + half, center.z + half),
      three.Vector3(center.x - half, center.y - half, center.z + half),
      three.Vector3(center.x - half, center.y - half, center.z - half),
      three.Vector3(center.x + half, center.y - half, center.z - half),
      three.Vector3(center.x + half, center.y - half, center.z + half),
      three.Vector3(center.x + half, center.y + half, center.z + half),
      three.Vector3(center.x + half, center.y + half, center.z - half)
    ];

    var vec = [
      vecS[v0],
      vecS[v1],
      vecS[v2],
      vecS[v3],
      vecS[v4],
      vecS[v5],
      vecS[v6],
      vecS[v7]
    ];

    // Recurse iterations
    if (--iterations >= 0) {
      List<three.Vector3> tmp = [];

      tmp.addAll(hilbert3D(
          vec[0], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1));
      tmp.addAll(hilbert3D(
          vec[1], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3));
      tmp.addAll(hilbert3D(
          vec[2], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3));
      tmp.addAll(hilbert3D(
          vec[3], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5));
      tmp.addAll(hilbert3D(
          vec[4], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5));
      tmp.addAll(hilbert3D(
          vec[5], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7));
      tmp.addAll(hilbert3D(
          vec[6], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7));
      tmp.addAll(hilbert3D(
          vec[7], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7));

      // Return recursive call
      return tmp;
    }

    // Return complete Hilbert Curve.
    return vec;
  }
}