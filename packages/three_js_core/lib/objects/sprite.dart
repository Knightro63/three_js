import 'dart:typed_data';

import '../core/index.dart';
import '../materials/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;
import '../cameras/index.dart';

BufferGeometry? _geometry;

final Vector3 _intersectPoint = Vector3.zero();
final Vector3 _worldScale = Vector3.zero();
final Vector3 _mvPosition = Vector3.zero();

final Vector2 _alignedPosition = Vector2.zero();
final Vector2 _rotatedPosition = Vector2.zero();
final Matrix4 _viewWorldMatrix = Matrix4.identity();

final Vector3 _spritevA = Vector3.zero();
final Vector3 _spritevB = Vector3.zero();
final Vector3 _spritevC = Vector3.zero();

final Vector2 _spriteuvA = Vector2.zero();
final Vector2 _spriteuvB = Vector2.zero();
final Vector2 _spriteuvC = Vector2.zero();

/// A sprite is a plane that always faces towards the camera, generally with a
/// partially transparent texture applied.
///
/// Sprites do not cast shadows, setting 
/// ```
/// castShadow = true
/// ``` 
/// will have no effect.
/// 
/// ```
/// final map = TextureLoader().fromAsset( 'sprite.png' );
/// final material = SpriteMaterial({MaterialProperty.map: map});
///
/// final sprite = Sprite(material);
/// scene.add(sprite);
/// ```
/// 
class Sprite extends Object3D {
  Vector2 center = Vector2(0.5, 0.5);

  bool isSprite = true;

  /// [Material material] - (optional) an instance of
  /// [SpriteMaterial]. Default is a white [SpriteMaterial].
  ///
  /// Creates a new [name].
  Sprite([Material? material]) : super() {
    type = 'Sprite';

    if (_geometry == null) {
      _geometry = BufferGeometry();

      final float32List = Float32List.fromList([
        -0.5,
        -0.5,
        0,
        0,
        0,
        0.5,
        -0.5,
        0,
        1,
        0,
        0.5,
        0.5,
        0,
        1,
        1,
        -0.5,
        0.5,
        0,
        0,
        1
      ]);

      final interleavedBuffer = InterleavedBuffer.fromList(float32List, 5);

      _geometry!.setIndex([0, 1, 2, 0, 2, 3]);
      _geometry!.setAttributeFromString('position',InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
      _geometry!.setAttributeFromString('uv', InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));
    }

    geometry = _geometry;
    this.material = (material != null) ? material : SpriteMaterial(null);
  }

  Sprite.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson) {
    type = 'Sprite';
  }

  /// Get intersections between a casted ray and this sprite.
  /// [Raycaster.intersectObject] will call this method. The raycaster
  /// must be initialized by calling [Raycaster.setFromCamera] before
  /// raycasting against sprites.
  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    _worldScale.setFromMatrixScale(matrixWorld);

    _viewWorldMatrix.setFrom(raycaster.camera.matrixWorld);
    modelViewMatrix.multiply2(
        raycaster.camera.matrixWorldInverse, matrixWorld);

    _mvPosition.setFromMatrixPosition(modelViewMatrix);

    if (raycaster.camera is PerspectiveCamera && material != null && material!.sizeAttenuation == false) {
      _worldScale.scale(-_mvPosition.z);
    }

    final rotation = material?.rotation ?? 0;
    double? sin, cos;

    if (rotation != 0) {
      cos = math.cos(rotation);
      sin = math.sin(rotation);
    }

    final center = this.center;

    transformVertex(_spritevA..setValues(-0.5, -0.5, 0), _mvPosition, center,_worldScale, sin, cos);
    transformVertex(_spritevB..setValues(0.5, -0.5, 0), _mvPosition, center,_worldScale, sin, cos);
    transformVertex(_spritevC..setValues(0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);

    _spriteuvA.setValues(0, 0);
    _spriteuvB.setValues(1, 0);
    _spriteuvC.setValues(1, 1);

    // check first triangle
    Vector3? intersect = raycaster.ray.intersectTriangle(
        _spritevA, _spritevB, _spritevC, false, _intersectPoint);

    if (intersect == null) {
      // check second triangle
      transformVertex(_spritevB..setValues(-0.5, 0.5, 0), _mvPosition, center,_worldScale, sin, cos);
      _spriteuvB.setValues(0, 1);

      intersect = raycaster.ray.intersectTriangle(
          _spritevA, _spritevC, _spritevB, false, _intersectPoint);
      if (intersect == null) {
        return;
      }
    }

    final distance = raycaster.ray.origin.distanceTo(_intersectPoint);

    if (distance < raycaster.near || distance > raycaster.far) return;

    intersects.add(Intersection(
      distance: distance,
      point: _intersectPoint.clone(),
      uv: TriangleUtil.getUV(_intersectPoint, _spritevA, _spritevB,
          _spritevC, _spriteuvA, _spriteuvB, _spriteuvC, Vector2.zero()),
      object: this
    ));
  }

  @override
  Sprite copy(Object3D source, [bool? recursive]) {
    super.copy(source);

    if (source is Sprite) {
      center.setFrom(source.center);
      material = source.material;
    }
    return this;
  }
}

void transformVertex(vertexPosition, Vector3 mvPosition, Vector2 center, scale,
    double? sin, double? cos) {
  // compute position in camera space
  _alignedPosition
      .sub2(vertexPosition, center)
      .addScalar(0.5)
      .multiply(scale);

  // to check if rotation is not zero
  if (sin != null && cos != null) {
    _rotatedPosition.x =
        (cos * _alignedPosition.x) - (sin * _alignedPosition.y);
    _rotatedPosition.y =
        (sin * _alignedPosition.x) + (cos * _alignedPosition.y);
  } else {
    _rotatedPosition.setFrom(_alignedPosition);
  }

  vertexPosition.copy(mvPosition);
  vertexPosition.x += _rotatedPosition.x;
  vertexPosition.y += _rotatedPosition.y;

  // transform to world space
  vertexPosition.applyMatrix4(_viewWorldMatrix);
}
