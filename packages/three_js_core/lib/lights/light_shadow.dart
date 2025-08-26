import 'package:three_js_core/others/console.dart';

import '../cameras/index.dart';
import 'package:three_js_math/three_js_math.dart';
import '../math/frustum.dart';
import '../renderers/index.dart';
import 'light.dart';

/// Serves as a base class for the other shadow classes.
class LightShadow {
  Camera? camera;

  double bias = 0;
  double normalBias = 0;
  double radius = 1;
  double blurSamples = 8;
  double intensity = 1;

  Vector2 mapSize = Vector2(512, 512);

  RenderTarget? map;
  RenderTarget? mapPass;
  Matrix4 matrix = Matrix4.identity();

  bool autoUpdate = true;
  bool needsUpdate = false;

  final Frustum frustum = Frustum();
  final frameExtents = Vector2(1, 1);
  int viewportCount = 1;
  final List<Vector4> viewports = [Vector4(0, 0, 1, 1)];

  final Matrix4 projScreenMatrix = Matrix4.identity();
  final Vector3 lightPositionWorld = Vector3.zero();
  final Vector3 lookTarget = Vector3.zero();

  late double focus;

  /// [camera] - the light's view of the world.
  /// 
  /// Create a new [name]. This is not intended to be called directly - it is
  /// used as a base class by other light shadows.
  LightShadow([this.camera]);

  LightShadow.fromJson(Map<String, dynamic> json, Map<String,dynamic> rootJson);

  /// Used internally by the renderer to get the number of viewports that need
  /// to be rendered for this shadow.
  int getViewportCount() {
    return viewportCount;
  }

  /// Gets the shadow cameras frustum. Used internally by the renderer to cull
  /// objects.
  Frustum getFrustum() {
    return frustum;
  }
  
  /// Update the matrices for the camera and shadow, used internally by the
  /// renderer.
  /// 
  /// [light] - the light for which the shadow is being rendered.
  void updateMatrices(Light light, {int viewportIndex = 0}) {
    final shadowCamera = camera;
    final shadowMatrix = matrix;

    final lightPositionWorld = this.lightPositionWorld;

    lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
    shadowCamera!.position.setFrom(lightPositionWorld);

    lookTarget.setFromMatrixPosition(light.target!.matrixWorld);
    shadowCamera.lookAt(lookTarget);
    shadowCamera.updateMatrixWorld(false);

    projScreenMatrix.multiply2(shadowCamera.projectionMatrix, shadowCamera.matrixWorldInverse);
    frustum.setFromMatrix(projScreenMatrix);

    shadowMatrix.setValues(0.5, 0.0, 0.0, 0.5, 0.0, 0.5, 0.0, 0.5, 0.0, 0.0, 0.5, 0.5,0.0, 0.0, 0.0, 1.0);

    shadowMatrix.multiply(shadowCamera.projectionMatrix);
    shadowMatrix.multiply(shadowCamera.matrixWorldInverse);
  }

  Vector4 getViewport(int viewportIndex) {
    return viewports[viewportIndex];
  }

  /// Used internally by the renderer to extend the shadow map to contain all
  /// viewports
  Vector2 getFrameExtents() {
    return frameExtents;
  }

  /// Copies value of all the properties from the [source] to
  /// this Light.
  LightShadow copy(LightShadow source) {
    camera = source.camera?.clone();
    intensity = source.intensity;
    bias = source.bias;
    radius = source.radius;
    mapSize.setFrom(source.mapSize);

    return this;
  }

  /// Creates a new LightShadow with the same properties as this one.
  LightShadow clone() {
    return LightShadow().copy(this);
  }

  /// Serialize this LightShadow.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> object = {};

    if (intensity != 1 ) object['intensity'] = intensity;
    if (bias != 0) object["bias"] = bias;
    if (normalBias != 0) object["normalBias"] = normalBias;
    if (radius != 1) object["radius"] = radius;
    if (mapSize.x != 512 || mapSize.y != 512) {
      object["mapSize"] = mapSize.storage;
    }

    object["camera"] = camera!.toJson()["object"];

    return object;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  void dispose() {
    if (map != null) {
      map!.dispose();
    }

    if (mapPass != null) {
      mapPass!.dispose();
    }
  }

  dynamic getProperty(String propertyName) {
    if (propertyName == "camera") {
      return camera;
    } else if (propertyName == "bias") {
      return bias;
    } else if (propertyName == "normalBias") {
      return normalBias;
    } else if (propertyName == "radius") {
      return radius;
    } else if (propertyName == "blurSamples") {
      return blurSamples;
    } else if (propertyName == "intensity") {
      return intensity;
    } else if (propertyName == "mapSize") {
      return mapSize;
    } else if (propertyName == "map") {
      return map;
    } else if (propertyName == "mapPass") {
      return mapPass;
    } else if (propertyName == "matrix") {
      return matrix;
    } else if (propertyName == "autoUpdate") {
      return autoUpdate;
    } else if (propertyName == "needsUpdate") {
      return needsUpdate;
    } else if (propertyName == "viewportCount") {
      return viewportCount;
    } else if (propertyName == "focus") {
      return focus;
    }

    console.error("LightShadow.getProperty type: $runtimeType propertyName: $propertyName is not support ");
    return null;
  }

  LightShadow setProperty(String propertyName, dynamic newValue) {
    if (propertyName == "camera") {
      camera = newValue;
    } else if (propertyName == "bias") {
      bias = newValue;
    } else if (propertyName == "normalBias") {
      normalBias = newValue;
    } else if (propertyName == "radius") {
      radius = newValue;
    } else if (propertyName == "blurSamples") {
      blurSamples = newValue;
    } else if (propertyName == "intensity") {
      intensity = newValue;
    } else if (propertyName == "mapSize") {
      mapSize = newValue;
    } else if (propertyName == "map") {
      map = newValue;
    } else if (propertyName == "mapPass") {
      mapPass = newValue;
    } else if (propertyName == "matrix") {
      matrix = newValue;
    } else if (propertyName == "autoUpdate") {
      autoUpdate = newValue;
    } else if (propertyName == "needsUpdate") {
      needsUpdate = newValue;
    } else if (propertyName == "viewportCount") {
      viewportCount = newValue;
    } else if (propertyName == "focus") {
      focus = newValue;
    }

    return this;
  }

  dynamic operator [] (key) => getProperty(key);
  void operator []=(String key, dynamic value) => setProperty(key, value);
}
