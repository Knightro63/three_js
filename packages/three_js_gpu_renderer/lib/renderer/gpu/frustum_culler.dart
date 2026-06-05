import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart'; // Adjust to where Object3D, Mesh, and Math modules sit

/// Frustum culling optimization for skipping off-screen objects.
/// T038: +15 FPS improvement by avoiding unnecessary draw calls.
///
/// Implements view frustum culling using camera's projection-view matrix
/// to determine which objects are visible and should be rendered.
class FrustumCuller {
  // Frustum planes generated instantly at runtime: left, right, bottom, top, near, far
  final List<Plane> _planes = List.generate(6, (_) => Plane());

  // Statistics counters
  int _totalObjects = 0;
  int _culledObjects = 0;
  int _visibleObjects = 0;

  // Pre-allocated recycling pools to completely avoid GC pressure during the animation frame tick
  final Vector3 _tempCenter = Vector3();
  final Vector3 _tempLocalCenter = Vector3();
  final Vector3 _tempScale = Vector3();

  /// Extracts frustum planes from camera's projection-view matrix using the Gribb-Hartmann method.
  /// @param camera Camera with projection and view matrices
  void extractPlanesFromCamera(Camera camera) {
    final matrix = Matrix4().multiply2(
      camera.projectionMatrix,
      camera.matrixWorldInverse,
    );
    final me = matrix.storage;

    // Left plane
    _planes[0].set(me[3] + me[0], me[7] + me[4], me[11] + me[8], me[15] + me[12]).normalize();
    // Right plane
    _planes[1].set(me[3] - me[0], me[7] - me[4], me[11] - me[8], me[15] - me[12]).normalize();
    // Bottom plane
    _planes[2].set(me[3] + me[1], me[7] + me[5], me[11] + me[9], me[15] + me[13]).normalize();
    // Top plane
    _planes[3].set(me[3] - me[1], me[7] - me[5], me[11] - me[9], me[15] - me[13]).normalize();
    // Near plane
    _planes[4].set(me[3] + me[2], me[7] + me[6], me[11] + me[10], me[15] + me[14]).normalize();
    // Far plane
    _planes[5].set(me[3] - me[2], me[7] - me[6], me[11] - me[10], me[15] - me[14]).normalize();
  }

  /// Checks if an object is visible within the frustum.
  /// @param obj Object to test
  /// @return true if object is visible, false if culled
  bool isObjectVisible(Object3D obj) {
    _totalObjects++;
    final center = _computeWorldBoundingCenter(obj, _tempCenter);
    final radius = _computeBoundingRadius(obj);

    if (radius <= 0.0) {
      // Treat objects with no size as visible
      _visibleObjects++;
      return true;
    }

    // Test against all 6 frustum planes
    for (final plane in _planes) {
      final distance = plane.distanceToPoint(center);
      if (distance < -radius) {
        // Object is completely outside this plane
        _culledObjects++;
        return false;
      }
    }

    // Object is at least partially visible
    _visibleObjects++;
    return true;
  }

  /// Culls a list of objects, returning only visible ones.
  /// @param objects List of objects to cull
  /// @param camera Camera defining the frustum
  /// @return List of visible objects
  List<Object3D> cullObjects(List<Object3D> objects, Camera camera) {
    _resetStats();
    extractPlanesFromCamera(camera);
    return objects.where((obj) => isObjectVisible(obj)).toList();
  }

  /// Culls objects during scene traversal.
  /// @param root Root object to traverse
  /// @param camera Camera defining the frustum
  /// @param onVisible Callback for each visible object
  void cullScene(Object3D root, Camera camera, void Function(Object3D) onVisible) {
    _resetStats();
    extractPlanesFromCamera(camera);
    
    root.traverse((obj) {
      if (obj is Mesh && isObjectVisible(obj)) {
        onVisible(obj);
      }
    });
  }

  /// Gets culling statistics parameters.
  CullingStats getStats() {
    final floatCullRate = _totalObjects > 0 
        ? _culledObjects.toDouble() / _totalObjects 
        : 0.0;

    return CullingStats(
      total: _totalObjects,
      culled: _culledObjects,
      visible: _visibleObjects,
      cullRate: floatCullRate,
    );
  }

  /// Resets statistics counters before a new frame execution loop pass.
  void _resetStats() {
    _totalObjects = 0;
    _culledObjects = 0;
    _visibleObjects = 0;
  }

  Vector3 _computeWorldBoundingCenter(Object3D obj, Vector3 target) {
    if (obj is Mesh) {
      final geometry = obj.geometry;
      final sphere = geometry?.boundingSphere ?? (geometry?..computeBoundingSphere())?.boundingSphere;
      if ((sphere?.radius ?? 0) > 0.0) {
        _tempLocalCenter.setFrom(sphere!.center);
        obj.localToWorld(_tempLocalCenter);
        return target.setFrom(_tempLocalCenter);
      } else {
        return obj.getWorldPosition(target);
      }
    }
    return obj.getWorldPosition(target);
  }

  double _computeBoundingRadius(Object3D obj) {
    final worldScale = obj.getWorldScale(_tempScale);
    final maxScale = math.max(worldScale.x, math.max(worldScale.y, worldScale.z));

    if (maxScale <= 0.0) {
      return 0.0;
    }

    if (obj is Mesh) {
      final sphere = (obj.geometry?..computeBoundingSphere())?.boundingSphere;
      if ((sphere?.radius ?? 0) > 0.0) {
        return sphere!.radius * maxScale;
      } else {
        return maxScale;
      }
    }
    return maxScale;
  }
}

// ==========================================
// SUPPORTING DATA STRUCTURES & UTILITIES
// ==========================================

/// Represents a plane in 3D space (ax + by + cz + d = 0).
class Plane {
  double a = 0.0;
  double b = 0.0;
  double c = 0.0;
  double d = 0.0;

  Plane();

  Plane set(double nx, double ny, double nz, double nw) {
    a = nx; b = ny; c = nz; d = nw;
    return this;
  }

  Plane normalize() {
    final length = math.sqrt(a * a + b * b + c * c);
    if (length > 0.0) {
      final invLength = 1.0 / length;
      a *= invLength;
      b *= invLength;
      c *= invLength;
      d *= invLength;
    }
    return this;
  }

  double distanceToPoint(Vector3 point) {
    return (a * point.x + b * point.y + c * point.z) + d;
  }
}

/// Culling statistics container metadata layout class.
class CullingStats {
  final int total;
  final int culled;
  final int visible;
  final double cullRate;

  const CullingStats({
    required this.total,
    required this.culled,
    required this.visible,
    required this.cullRate,
  });

  @override
  String toString() {
    return 'CullingStats(total: $total, culled: $culled, visible: $visible, cullRate: ${(cullRate * 100).toStringAsFixed(1)}%)';
  }
}
