import './line.dart';

/// A continuous line that connects back to the start.
/// 
/// This is nearly the same as [Line]; the only difference is that it is
/// rendered using
/// [gl.LINE_LOOP](https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawElements) instead of
/// [gl.LINE_STRIP](https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawElements), 
/// which draws a straight line to the next vertex, and
/// connects the last vertex back to the first.
class LineLoop extends Line {

  /// [geometry] — List of vertices representing points on
  /// the line loop.
  /// 
  /// [material] — Material for the line. Default is
  /// [LineBasicMaterial].
  /// 
  LineLoop(super.geometry, super.material){
    type = 'LineLoop';
  }
}
