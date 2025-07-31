import 'dart:convert';
import 'package:three_js_math/math/index.dart';

import '../core/index.dart';
import 'camera.dart';
import 'dart:math' as math;

/// Camera that uses
/// [perspective projection](https://en.wikipedia.org/wiki/Perspective_(graphical)).
/// 
/// This projection mode is designed to mimic the way the human eye sees. It
/// is the most common projection mode used for rendering a 3D scene.
/// ```
/// final camera = PerspectiveCamera( 45, width / height, 1, 1000 );
/// scene.add( camera );
/// ```
class PerspectiveCamera extends Camera {

  /// [fov] — Camera frustum vertical field of view.
  /// 
  /// [aspect] — Camera frustum aspect ratio.
  /// 
  /// [near] — Camera frustum near plane.
  /// 
  /// [far] — Camera frustum far plane. 
  /// 
  /// Together these define the camera's
  /// [viewing frustum](https://en.wikipedia.org/wiki/Viewing_frustum).
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

  /// Returns the width of the image on the film. If .aspect is greater than or
  /// equal to one (landscape format), the result equals .filmGauge.
  double getFilmWidth() {
    return filmGauge * math.min(aspect, 1);
  }

  /// Returns the height of the image on the film. If .aspect is less than or
	/// equal to one (portrait format), the result equals .filmGauge.
  double getFilmHeight() {
    return filmGauge / math.max(aspect, 1);
  }

  /// Calculates the focal length from the current .fov and .filmGauge.
	double getFocalLength() {
		final vExtentSlope = math.tan(0.5 * this.fov ).toRad();
		return 0.5 * this.getFilmHeight() / vExtentSlope;
	}

  /// Sets the FOV by focal length in respect to the current
  /// [.filmGauge].
  /// 
  /// By default, the focal length is specified for a 35mm (full frame) camera.
	void setFocalLength(double focalLength){
		// see http://www.bobatkins.com/photography/technical/field_of_view.html
		final vExtentSlope = 0.5 * getFilmHeight() / focalLength;

		fov = (180.0 / math.pi) * 2 * math.atan( vExtentSlope );
		updateProjectionMatrix();
	}

  /// [fullWidth] — full width of multiview setup
  /// 
  /// [fullHeight] — full height of multiview setup
  /// 
  /// [x] — horizontal offset of subcamera
  /// 
  /// [y] — vertical offset of subcamera
  /// 
  /// [width] — width of subcamera
  /// 
  /// [height] — height of subcamera
  ///
  /// Sets an offset in a larger frustum. This is useful for multi-window or
  /// multi-monitor/multi-machine setups.
  ///
  /// For example, if you have 3x2 monitors and each monitor is 1920x1080 and
  /// the monitors are in grid like this:
  ///```
  /// +---+---+---+
  /// | A | B | C |
  /// +---+---+---+
  /// | D | E | F |
  /// +---+---+---+
  ///```
	/// then for each monitor you would call it like this:
  ///
	/// ```
  /// const w = 1920;
  /// const h = 1080;
  /// final fullWidth = w * 3;
  /// final fullHeight = h * 2;
  /// 
  /// // A
  /// camera.setViewOffset( fullWidth, fullHeight, w * 0, h * 0, w, h );
  /// // B
  /// camera.setViewOffset( fullWidth, fullHeight, w * 1, h * 0, w, h );
  /// // C
  /// camera.setViewOffset( fullWidth, fullHeight, w * 2, h * 0, w, h );
  /// // D
  /// camera.setViewOffset( fullWidth, fullHeight, w * 0, h * 1, w, h );
  /// // E
  /// camera.setViewOffset( fullWidth, fullHeight, w * 1, h * 1, w, h );
  /// // F
  /// camera.setViewOffset( fullWidth, fullHeight, w * 2, h * 1, w, h );
  /// ```
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

  /// Removes any offset set by the [setViewOffset] method.
  void clearViewOffset() {
    if (view != null) {
      view!.enabled = false;
    }
    updateProjectionMatrix();
  }

  /// Updates the camera projection matrix. Must be called after any change of parameters.
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

  /// [meta] - object containing metadata such as textures or images in objects'
  /// descendants.
  /// 
  /// Convert the camera to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
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
