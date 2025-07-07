import 'package:three_js_math/three_js_math.dart';
import './p.dart';
class Perlin {
  late num _seed;
  late List<Vector3> _offsetMatrix;
  late num _perm;
  late List<Vector3>  _gradP;
  // _three: { Vector2: any; Vector3: any };

  Perlin([double seedNum = 1]) {
    final _gradientVecs = [
      // 2D Vecs
      Vector3(1, 1, 0),
      Vector3(-1, 1, 0),
      Vector3(1, -1, 0),
      Vector3(-1, -1, 0),
      // + 3D Vecs
      Vector3(1, 0, 1),
      Vector3(-1, 0, 1),
      Vector3(1, 0, -1),
      Vector3(-1, 0, -1),
      Vector3(0, 1, 1),
      Vector3(0, -1, 1),
      Vector3(0, 1, -1),
      Vector3(0, -1, -1),
    ];

    List perm = Array(512);
    List gradP = Array(512);

    seedNum *= 65536;

    int seed = seedNum.floor();
    if (seed < 256) {
      seed |= seed << 8;
    }

    for (int i = 0; i < 256; i++) {
      var v;
      if (i & 1 != 0) {
        v = p[i] ^ (seed & 255);
      } 
      else {
        v = p[i] ^ ((seed >> 8) & 255);
      }

      perm[i] = perm[i + 256] = v;
      gradP[i] = gradP[i + 256] = _gradientVecs[v % 12];
    }

    this._seed = seed;

    this._offsetMatrix = [
      Vector3(0, 0, 0),
      Vector3(0, 0, 1),
      Vector3(0, 1, 0),
      Vector3(0, 1, 1),
      Vector3(1, 0, 0),
      Vector3(1, 0, 1),
      Vector3(1, 1, 0),
      Vector3(1, 1, 1),
    ];

    this._perm = perm;
    this._gradP = gradP;
  }

  double _fade(double t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  double _lerp(double a, double b, double t) {
    return (1 - t) * a + t * b;
  }

  _gradient(Vector posInCell) {
    final perm = this._perm;
    if (posInCell is Vector3) {
      return posInCell.x + perm[posInCell.y + perm[posInCell.z]];
    } 
    else {
      return posInCell.x + perm[posInCell.y];
    }
  }

  double get2(Vector2 input) {
    final List<int> cell = [
      input.x.toInt(),
      input.y.toInt(),
    ];
    input.sub(Vector2(cell[0].toDouble(),cell[1].toDouble()));

    cell[0] &= 255;
    cell[1] &= 255;

    cell[0] &= 255;
    cell[1] &= 255;

    final List<double> gradiantDot = [];
    for (int i = 0; i < 4; i++) {
      final s3 = this._offsetMatrix[i * 2];
      final s = Vector2(s3.x, s3.y);

      final grad3 =
        this._gradP[this._gradient(Vector2().add2(Vector2(cell[0].toDouble(),cell[1].toDouble()), s))];
      final grad2 = Vector2(grad3.x, grad3.y);
      final dist2 = Vector2().sub2(input, s);

      gradiantDot.add(grad2.dot(dist2));
    }

    final u = this._fade(input.x);
    final v = this._fade(input.y);

    final value = this._lerp(
      this._lerp(gradiantDot[0], gradiantDot[2], u),
      this._lerp(gradiantDot[1], gradiantDot[3], u),
      v
    );

    return value;
  }

  double get3(Vector3 input) {
    final List<int> cell = [
      input.x.toInt(),
      input.y.toInt(),
      input.z.toInt()
    ];
    input.sub(Vector3(cell[0].toDouble(),cell[1].toDouble(),cell[2].toDouble()));

    cell[0] &= 255;
    cell[1] &= 255;
    cell[2] &= 255;

    final List<double> gradiantDot = [];
    for (int i = 0; i < 8; i++) {
      final s = this._offsetMatrix[i];

      final grad3 =
        this._gradP[this._gradient(Vector3().add2(Vector3(cell[0].toDouble(),cell[1].toDouble(),cell[2].toDouble()), s))];
      final dist2 = Vector3().sub2(input, s);

      gradiantDot.add(grad3.dot(dist2));
    }

    final u = this._fade(input.x);
    final v = this._fade(input.y);
    final w = this._fade(input.z);

    final value = this._lerp(
      this._lerp(
        this._lerp(gradiantDot[0], gradiantDot[4], u),
        this._lerp(gradiantDot[1], gradiantDot[5], u),
        w
      ),
      this._lerp(
        this._lerp(gradiantDot[2], gradiantDot[6], u),
        this._lerp(gradiantDot[3], gradiantDot[7], u),
        w
      ),
      v
    );

    return value;
  }
}