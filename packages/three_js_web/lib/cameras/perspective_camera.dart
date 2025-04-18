@JS('THREE')
import '../core/index.dart';
import 'camera.dart';
import 'dart:js_interop';

@JS('PerspectiveCamera')
class PerspectiveCamera extends Camera {
  external PerspectiveCamera([double fov = 50, double aspect = 1, double near = 0.1, double far = 2000]);
  PerspectiveCamera.fromJson(Map<String, dynamic> json, Map<String,dynamic> rootJson){
    fov = json["fov"];
    aspect = json["aspect"];
    near = json["near"];
    far = json["far"];

    PerspectiveCamera(fov,aspect,near,far);
  }

  @override
  external PerspectiveCamera copy(Object3D source, [bool? recursive]);
  @override
  external PerspectiveCamera clone([bool? recursive = true]);

  /// Returns the width of the image on the film. If .aspect is greater than or
  /// equal to one (landscape format), the result equals .filmGauge.
  external double getFilmWidth();
  external double getFilmHeight();
	external void setFocalLength(double focalLength);

  external void setViewOffset(double fullWidth, double fullHeight, double x, double y, double width, double height);
  external void clearViewOffset();

  @override
  external void updateProjectionMatrix();

  Map<String, dynamic> toJson({Object3dMeta? meta}){
    return toJSON(meta?.toJson());
  }

  external Map<String, dynamic> toJSON(Map? meta);
}
