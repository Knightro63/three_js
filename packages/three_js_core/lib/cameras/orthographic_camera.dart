import 'dart:convert';
import '../core/index.dart';
import 'camera.dart';

/// Camera that uses
/// [orthographic projection](https://en.wikipedia.org/wiki/Orthographic_projectio).
///
/// In this projection mode, an object's size in the rendered image stays
/// constant regardless of its distance from the camera.
///
/// This can be useful for rendering 2D scenes and UI elements, amongst other
/// things.
/// 
/// ```
/// final camera = OrthographicCamera( width / - 2, width / 2, height / 2, height / - 2, 1, 1000 );
/// scene.add( camera );
/// ```
class OrthographicCamera extends Camera {
  
  /// [left] — Camera frustum left plane.
  /// 
  /// [right] — Camera frustum right plane.
  /// 
  /// [top] — Camera frustum top plane.
  /// 
  /// [bottom] — Camera frustum bottom plane.
  /// 
  /// [near] — Camera frustum near plane.
  /// 
  /// [far] — Camera frustum far plane.
  /// 
  /// Together these define the camera's
  /// [viewing frustum](https://en.wikipedia.org/wiki/Viewing_frustum).
  OrthographicCamera([
    double left = -1,
    double right = 1,
    double top = 1,
    double bottom = -1,
    double near = 0.1,
    double far = 2000
  ]):super() {
    type = 'OrthographicCamera';
    zoom = 1;

    view = null;

    this.left = left;
    this.right = right;
    this.top = top;
    this.bottom = bottom;

    this.near = near;
    this.far = far;

    updateProjectionMatrix();
  }

  @override
  OrthographicCamera copy(Object3D source, [bool? recursive]) {
    super.copy(source, recursive);
    if (source is OrthographicCamera) {
      left = source.left;
      right = source.right;
      top = source.top;
      bottom = source.bottom;
      near = source.near;
      far = source.far;

      zoom = source.zoom;
      view = source.view == null ? null : json.decode(json.encode(source.view));
    }
    return this;
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
  /// Sets an offset in a larger
  /// [viewing frustum](https://en.wikipedia.org/wiki/Viewing_frustum). This
  /// is useful for multi-window or multi-monitor/multi-machine setups. For an
  /// example on how to use it see [setViewOffset].
  void setViewOffset(double fullWidth, double fullHeight, double x, double y, double width, double height) {
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

  /// Removes any offset set by the .setViewOffset method.
  void clearViewOffset() {
    if (view != null) {
      view!.enabled = false;
    }

    updateProjectionMatrix();
  }

  /// Updates the camera projection matrix. Must be called after any change of
  /// parameters.
  @override
  void updateProjectionMatrix() {
    final dx = (this.right - this.left) / (2 * zoom);
    final dy = (this.top - this.bottom) / (2 * zoom);
    final cx = (this.right + this.left) / 2;
    final cy = (this.top + this.bottom) / 2;

    double left = cx - dx;
    double right = cx + dx;
    double top = cy + dy;
    double bottom = cy - dy;

    if (view != null && view!.enabled) {
      final scaleW = (this.right - this.left) / view!.fullWidth / zoom;
      final scaleH = (this.top - this.bottom) / view!.fullHeight / zoom;

      left += scaleW * view!.offsetX;
      right = left + scaleW * view!.width;
      top -= scaleH * view!.offsetY;
      bottom = top - scaleH * view!.height;
    }

    projectionMatrix.makeOrthographic(left, right, top, bottom, near, far);

    projectionMatrixInverse.setFrom(projectionMatrix);
    projectionMatrixInverse.invert();
  }

  /// [meta] -- object containing metadata such as textures or images in objects'
  /// descendants.
  /// Convert the camera to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    final data = super.toJson(meta: meta);

    data["object"]["zoom"] = zoom;
    data["object"]["left"] = left;
    data["object"]["right"] = right;
    data["object"]["top"] = top;
    data["object"]["bottom"] = bottom;
    data["object"]["near"] = near;
    data["object"]["far"] = far;

    if (view != null) {
      data["object"]["view"] = json.decode(json.encode(view!.toMap));
    }

    return data;
  }
}
