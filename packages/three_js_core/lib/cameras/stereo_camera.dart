import 'package:three_js_math/three_js_math.dart';
import 'camera.dart';
import 'perspective_camera.dart';
import 'dart:math' as math;

final _eyeRight = Matrix4.identity();
final _eyeLeft = Matrix4.identity();
final _projectionMatrix = Matrix4.identity();

/// Dual [page:PerspectiveCamera PerspectiveCamera]s used for effects such as
/// [3D Anaglyph](https://en.wikipedia.org/wiki/Anaglyph_3D) or
/// [Parallax Barrier](https://en.wikipedia.org/wiki/parallax_barrier).
class StereoCamera {
  String type = 'StereoCamera';

  double aspect = 1;

  double eyeSep = 0.064;

  /// Left camera. This is added to [page:Layers layer 1] - objects to be
  /// rendered by the left camera must also be added to this layer.
  late PerspectiveCamera cameraL;
  
  /// Right camera.This is added to [page:Layers layer 2] - objects to be
  /// rendered by the right camera must also be added to this layer.
  late PerspectiveCamera cameraR;

  final Map<String, dynamic> _cache = {};

  StereoCamera() {
    cameraL = PerspectiveCamera();
    cameraL.layers.enable(1);
    cameraL.matrixAutoUpdate = false;

    cameraR = PerspectiveCamera();
    cameraR.layers.enable(2);
    cameraR.matrixAutoUpdate = false;
  }

  /// Update the stereo cameras based on the camera passed in.
  void update(Camera camera) {
    final cache = _cache;

    final needsUpdate = cache["focus"] != camera.focus ||
        cache["fov"] != camera.fov ||
        cache["aspect"] != camera.aspect * aspect ||
        cache["near"] != camera.near ||
        cache["far"] != camera.far ||
        cache["zoom"] != camera.zoom ||
        cache["eyeSep"] != eyeSep;

    if (needsUpdate) {
      cache["focus"] = camera.focus;
      cache["fov"] = camera.fov;
      cache["aspect"] = camera.aspect * aspect;
      cache["near"] = camera.near;
      cache["far"] = camera.far;
      cache["zoom"] = camera.zoom;
      cache["eyeSep"] = eyeSep;

      // Off-axis stereoscopic effect based on
      // http://paulbourke.net/stereographics/stereorender/

      _projectionMatrix.setFrom(camera.projectionMatrix);
      final eyeSepHalf = cache["eyeSep"] / 2;
      final eyeSepOnProjection = eyeSepHalf * cache["near"] / cache["focus"];
      final ymax = (cache["near"] * math.tan((math.pi/180) * cache["fov"] * 0.5)) /cache["zoom"];
      double xmin, xmax;

      // translate xOffset

      _eyeLeft.storage[12] = -eyeSepHalf;
      _eyeRight.storage[12] = eyeSepHalf;

      // for left eye

      xmin = -ymax * cache["aspect"] + eyeSepOnProjection;
      xmax = ymax * cache["aspect"] + eyeSepOnProjection;

      _projectionMatrix.storage[0] = 2 * cache["near"] / (xmax - xmin);
      _projectionMatrix.storage[8] = (xmax + xmin) / (xmax - xmin);

      cameraL.projectionMatrix.setFrom(_projectionMatrix);

      // for right eye

      xmin = -ymax * cache["aspect"] - eyeSepOnProjection;
      xmax = ymax * cache["aspect"] - eyeSepOnProjection;

      _projectionMatrix.storage[0] = 2 * cache["near"] / (xmax - xmin);
      _projectionMatrix.storage[8] = (xmax + xmin) / (xmax - xmin);

      cameraR.projectionMatrix.setFrom(_projectionMatrix);
    }

    cameraL.matrixWorld..setFrom(camera.matrixWorld)..multiply(_eyeLeft);
    cameraR.matrixWorld..setFrom(camera.matrixWorld)..multiply(_eyeRight);
  }
}
