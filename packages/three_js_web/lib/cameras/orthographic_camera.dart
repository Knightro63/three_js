@JS('THREE')
import '../core/index.dart';
import 'camera.dart';
import 'dart:js_interop';

@JS('OrthographicCamera')
class OrthographicCamera extends Camera {
  external OrthographicCamera([
    double left = -1,
    double right = 1,
    double top = 1,
    double bottom = -1,
    double near = 0.1,
    double far = 2000
  ]);

  @override
  external OrthographicCamera copy(Object3D source, [bool? recursive]);
  external void setViewOffset(double fullWidth, double fullHeight, double x, double y, double width, double height);
  external void clearViewOffset();

  @override
  external void updateProjectionMatrix();

  Map<String, dynamic> toJson({Object3dMeta? meta}){
    return toJSON(meta?.toJson());
  }

  external Map<String, dynamic> toJSON(Map? meta);
}
