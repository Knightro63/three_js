import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';

class CameraView{
  CameraView.fromJson(Map<String,dynamic> json, [Map<String,dynamic>? rootJson]){
    enabled = json['enabled'] ?? true;
    fullWidth = (json['fullWidth'] ?? 1).toDouble();
    fullHeight = (json['fullHeight'] ?? 1).toDouble();
    offsetX = (json['offsetX'] ?? 0).toDouble();
    offsetY = (json['offsetY'] ?? 0).toDouble();
    width = (json['width'] ?? 1).toDouble();
    height = (json['height'] ?? 1).toDouble();
  }

  CameraView({
    this.enabled = true,
    this.fullWidth = 1,
    this.fullHeight = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.width = 1,
    this.height = 1,
  });

  bool enabled = true;
  double fullWidth = 1;
  double fullHeight = 1;
  double offsetX = 0;
  double offsetY = 0;
  double width = 1;
  double height = 1;

  Map<String,dynamic> get toMap => {
    'enabled': enabled,
    'fullWidth': fullWidth,
    'fullHeight': fullHeight,
    'offsetX': offsetX,
    'offsetY':offsetY,
    'width':width,
    'height':height
  };


}

/// Abstract base class for cameras. This class should always be inherited
/// when you build a new camera.
class Camera extends Object3D {
  Matrix4 matrixWorldInverse = Matrix4.identity();

  Matrix4 projectionMatrix = Matrix4.identity();
  Matrix4 projectionMatrixInverse = Matrix4.identity();

  double fov = 50;
  double zoom = 1.0;
  double near = 0.1;
  double far = 2000;
  double focus = 10;
  double aspect = 1;
  double filmGauge = 35; // width of the film (default in millimeters)
  double filmOffset = 0; // horizontal film offset (same unit as gauge)

  //OrthographicCamera
  double left = -1;
  double right = 1;
  double top = 1;
  double bottom = -1;

  CameraView? view;//Map<String, dynamic>? view;
  Vector4? viewport;
  int coordinateSystem = 2000;

  /// Creates a new [name]. Note that this class is not intended to be called
  /// directly; you probably want a [PerspectiveCamera] or
  /// [OrthographicCamera] instead.
  Camera():super(){
    type = "Camera";
  }

  Camera.fromJson(Map<String,dynamic> json, [Map<String,dynamic>? rootJson]):super.fromJson(json, rootJson){
    type = "Camera";
  }

  void updateProjectionMatrix() {
    throw(" Camera.updateProjectionMatrix not implimented.");
  }

  /// Copy the properties from the source camera into this one.
  @override
  Camera copy(Object3D source, [bool? recursive]) {
    super.copy(source, recursive);
    Camera source1 = source as Camera;

    matrixWorldInverse.setFrom(source1.matrixWorldInverse);
    projectionMatrix.setFrom(source1.projectionMatrix);
    projectionMatrixInverse.setFrom(source1.projectionMatrixInverse);

    return this;
  }

  /// [target] — the result will be copied into this Vector3.
  ///
  /// 
  /// Returns a [Vector3] representing the world space direction in which
  /// the camera is looking. (Note: A camera looks down its local, negative
  /// z-axis).
  @override
  Vector3 getWorldDirection(Vector3 target) {
    updateWorldMatrix(true, false);
    final e = matrixWorld.storage;
    target.setValues(-e[8], -e[9], -e[10]);
    target.normalize();
    return target;
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    super.updateMatrixWorld(force);
    matrixWorldInverse.setFrom(matrixWorld);
    matrixWorldInverse.invert();
  }

  @override
  void updateWorldMatrix(bool updateParents, bool updateChildren) {
    super.updateWorldMatrix(updateParents, updateChildren);
    matrixWorldInverse.setFrom(matrixWorld);
    matrixWorldInverse.invert();
  }

  /// Return a new camera with the same properties as this one.
  @override
  Camera clone([bool? recursive = true]) {
    return Camera()..copy(this);
  }

  @override
  Map<String,dynamic> toJson({Object3dMeta? meta}){
    return {
      'fov': fov,
      'zoom': zoom,
      'near': near,
      'far': far,
      'focus': focus,
      'aspect': aspect,
      'filmGauge': filmGauge,
      'filmOffset': filmOffset,
      'left': left,
      'right': right,
      'top': top,
      'bottom': bottom,
      'view': view?.toMap,
      'coordinateSystem': coordinateSystem,
      'viewport': viewport?.toList(),
      'matrixWorldInverse': matrixWorldInverse.storage,
      'projectionMatrix': projectionMatrix.storage,
      'projectionMatrixInverse': projectionMatrixInverse.storage
    }..addAll(super.toJson(meta: meta));
  }

  @override
  dynamic getProperty(String propertyName, [int? offset]) {
    if(propertyName == 'fov'){
      return fov;
    }
    else if(propertyName == 'zoom'){
      return zoom;
    }
    else if(propertyName == 'near'){
      return near;
    }
    else if(propertyName == 'far'){
      return far;
    }
    else if(propertyName == 'focus'){
      return focus;
    }
    else if(propertyName == 'aspect'){
      return aspect;
    }
    else if(propertyName == 'filmGauge'){
      return filmGauge;
    }
    else if(propertyName == 'left'){
      return left;
    }
    else if(propertyName == 'right'){
      return right;
    }
    else if(propertyName == 'top'){
      return top;
    }
    else if(propertyName == 'bottom'){
      return bottom;
    }
    else if(propertyName == view){
      return view;
    }
    else if(propertyName == 'coordinateSystem'){
      return coordinateSystem;
    }
    else if(propertyName == 'viewport'){
      return viewport;
    }
    else if(propertyName == 'matrixWorldInverse'){
      return matrixWorldInverse;
    }
    else if(propertyName == 'projectionMatrix'){
      return projectionMatrix;
    }
    else if(propertyName == 'projectionMatrixInverse'){
      return projectionMatrixInverse;
    }
    return super.getProperty(propertyName, offset);
  }

  @override
  Camera setProperty(String propertyName, dynamic value, [int? offset]){
    if(propertyName == 'fov'){
      fov = value.toDouble();
    }
    else if(propertyName == 'zoom'){
      zoom = value.toDouble();
    }
    else if(propertyName == 'near'){
      near = value.toDouble();
    }
    else if(propertyName == 'far'){
      far = value.toDouble();
    }
    else if(propertyName == 'focus'){
      focus = value.toDouble();
    }
    else if(propertyName == 'aspect'){
      aspect = value.toDouble();
    }
    else if(propertyName == 'filmGauge'){
      filmGauge = value.toDouble();
    }
    else if(propertyName == 'left'){
      left = value.toDouble();
    }
    else if(propertyName == 'right'){
      right = value.toDouble();
    }
    else if(propertyName == 'top'){
      top = value.toDouble();
    }
    else if(propertyName == 'bottom'){
      bottom = value.toDouble();
    }
    else if(propertyName == view){
      if(value is Map<String,dynamic>){
        view = CameraView.fromJson(value);
        return this;
      }
      view = value;
    }
    else if(propertyName == 'coordinateSystem'){
      coordinateSystem = value.toInt();
    }
    else if(propertyName == 'viewport'){
      if(value is List){
        viewport = Vector4().copyFromUnknown(value);
        return this;
      }
      viewport = value;
    }
    else if(propertyName == 'matrixWorldInverse'){
      if(value is List){
        matrixWorldInverse = Matrix4().copyFromUnknown(value);
        return this;
      }
      matrixWorldInverse = value;
    }
    else if(propertyName == 'projectionMatrix'){
      if(value is List){
        projectionMatrix = Matrix4().copyFromUnknown(value);
        return this;
      }
      projectionMatrix = value;
    }
    else if(propertyName == 'projectionMatrixInverse'){
      if(value is List){
        projectionMatrixInverse = Matrix4().copyFromUnknown(value);
        return this;
      }
      projectionMatrixInverse = value;
    }
    else{
      super.setProperty(propertyName, value);
    }
    return this;
  }
}
