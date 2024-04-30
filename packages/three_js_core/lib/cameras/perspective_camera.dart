import 'dart:convert';
import '../core/index.dart';
import 'camera.dart';
import 'dart:math' as math;

class PerspectiveCamera extends Camera {
  PerspectiveCamera([double fov = 50, double aspect = 1, double near = 0.1, double far = 2000]): super() {
    type = "PerspectiveCamera";
    this.fov = fov;
    this.aspect = aspect;
    this.near = near;
    this.far = far;

    updateProjectionMatrix();
  }

  PerspectiveCamera.fromJson(Map<String, dynamic> json, Map<String,dynamic> rootJson):super.fromJson(json,rootJson) {
    fov = json["fov"];
    aspect = json["aspect"];
    near = json["near"];
    far = json["far"];

    updateProjectionMatrix();
  }

  @override
  PerspectiveCamera copy(Object3D source, [bool? recursive]) {
    super.copy(source, recursive);

    PerspectiveCamera source1 = source as PerspectiveCamera;

    fov = source1.fov;
    zoom = source1.zoom;

    near = source1.near;
    far = source1.far;
    focus = source1.focus;

    aspect = source1.aspect;
    view = source1.view == null ? null : json.decode(json.encode(source1.view));

    filmGauge = source1.filmGauge;
    filmOffset = source1.filmOffset;

    return this;
  }

  @override
  PerspectiveCamera clone([bool? recursive = true]) {
    return PerspectiveCamera()..copy(this, recursive);
  }

  double getFilmWidth() {
    return filmGauge * math.min(aspect, 1);
  }

  double getFilmHeight() {
    return filmGauge / math.max(aspect, 1);
  }

	void setFocalLength(double focalLength){

		// see http://www.bobatkins.com/photography/technical/field_of_view.html
		final vExtentSlope = 0.5 * getFilmHeight() / focalLength;

		fov = (180.0 / math.pi) * 2 * math.atan( vExtentSlope );
		updateProjectionMatrix();

	}

  void setViewOffset(double fullWidth, double fullHeight, double x, double y, double width, double height) {
    aspect = fullWidth / fullHeight;

    view ??= CameraView();

    view!.enabled = true;
    view!.fullWidth = fullWidth;
    view!.fullHeight = fullHeight;
    view!.offsetX = x;
    view!.offsetY = y;
    view!.width = width;
    view!.height = height;

    updateProjectionMatrix();
  }

  void clearViewOffset() {
    if (view != null) {
      view!.enabled = false;
    }
    updateProjectionMatrix();
  }

  @override
  void updateProjectionMatrix() {
    final near = this.near;
    double top = near * math.tan((math.pi/180) * 0.5 * fov) / zoom;
    double height = 2 * top;
    double width = aspect * height;
    double left = -0.5 * width;

    if (view != null && view!.enabled) {
      final fullWidth = view!.fullWidth;
      final fullHeight = view!.fullHeight;

      left += view!.offsetX * width / fullWidth;
      top -= view!.offsetY * height / fullHeight;
      width *= view!.width / fullWidth;
      height *= view!.height / fullHeight;
    }

    num skew = filmOffset;
    if (skew != 0) left += near * skew / getFilmWidth();

    projectionMatrix.makePerspective(left, left + width, top, top - height, near, far);
    projectionMatrixInverse.setFrom(projectionMatrix);
    projectionMatrixInverse.invert();
  }

  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> output = super.toJson(meta: meta);
    Map<String, dynamic> object = output["object"];

    object["fov"] = fov;
    object["zoom"] = zoom;

    object["near"] = near;
    object["far"] = far;
    object["focus"] = focus;

    object["aspect"] = aspect;

    if (view != null) object["view"] = json.decode(json.encode(view!.toMap));

    object["filmGauge"] = filmGauge;
    object["filmOffset"] = filmOffset;

    return output;
  }
}
