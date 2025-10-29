import '../math/math_util.dart';
import '../matrix/matrix4.dart';
import '../vector/vector3.dart';

/// A geometric line segment represented by a start and end point.
class Line3 {
  final _startP = Vector3();
  final _startEnd = Vector3();
  late Vector3 start;
  late Vector3 end;

  /// [start] - Start of the line segment. Default is `(0, 0,
  /// 0)`.
  /// 
  /// [end] - End of the line segment. Default is `(0, 0, 0)`.
  Line3([Vector3? start, Vector3? end]) {
    this.start = (start != null) ? start : Vector3();
    this.end = (end != null) ? end : Vector3();
  }

  /// [start] - set the [page:.start start point] of the line.
  /// 
  /// [end] - set the [page:.end end point] of the line.
  /// 
  /// Sets the start and end values by copying the provided vectors.
  Line3 setStartEnd(Vector3 start, Vector3 end) {
    this.start.setFrom(start);
    this.end.setFrom(end);

    return this;
  }

  /// Returns a new [Line3] with the same [start] and
  /// [end] vectors as this one.
  Line3 clone() {
    return Line3()..setFrom(this);
  }

  /// Copies the passed line's [start] and [end] vectors
  /// to this line.
  Line3 setFrom(Line3 line) {
    start.setFrom(line.start);
    end.setFrom(line.end);

    return this;
  }

  /// [target] — the result will be copied into this Vector3.
  /// 
  /// Returns the center of the line segment.
  Vector3 getCenter(Vector3 target) {
    return target.add2(start, end).scale(0.5);
  }

  /// [target] — the result will be copied into this Vector3.
  /// 
  /// Returns the delta vector of the line segment ( [end] vector
  /// minus the [start] vector).
  Vector3 delta(Vector3 target) {
    return target.sub2(end, start);
  }

  /// Returns the square of the
  /// [Euclidean distance](https://en.wikipedia.org/wiki/Euclidean_distance)
  /// (straight-line distance) between the line's [start] and
  /// [end] vectors.
  double distanceSq() {
    return start.distanceToSquared(end);
  }

  /// Returns the [Euclidean distance](https://en.wikipedia.org/wiki/Euclidean_distance)
  /// (straight-line distance) between the line's
  /// [start] and [page:.end end] points.
  double distance() {
    return start.distanceTo(end);
  }

  /// [t] - Use values 0-1 to return a position along the line
  /// segment.
  /// 
  /// [target] — the result will be copied into this Vector3.
  /// 
  /// Returns a vector at a certain position along the line. When [t]
  /// = 0, it returns the start vector, and when [t] = 1 it returns
  /// the end vector.
  Vector3 at(double t, Vector3 target) {
    return delta(target).scale(t).add(start);
  }

  /// [point] - the point for which to return a point parameter.
  ///
  /// [clampToLine] - Whether to clamp the result to the range `[0,
  /// 1]`.
  /// 
  /// Returns a point parameter based on the closest point as projected on the
  /// line segment. If [clampToLine] is true, then the returned
  /// value will be between `0` and `1`.
  double closestPointToPointParameter(Vector3 point, bool clampToLine) {
    _startP.sub2(point, start);
    _startEnd.sub2(end, start);

    final startEnd2 = _startEnd.dot(_startEnd);
    final startEndStartP = _startEnd.dot(_startP);

    double t = startEndStartP / startEnd2;

    if (clampToLine) {
      t = MathUtils.clamp(t, 0, 1);
    }

    return t;
  }

  /// [point] - return the closest point on the line to this
  /// point.
  /// 
  /// [clampToLine] - whether to clamp the returned value to the
  /// line segment.
  /// 
  /// [target] — the result will be copied into this Vector3.
  /// 
  /// Returns the closets point on the line. If [clampToLine] is
  /// true, then the returned value will be clamped to the line segment.
  Vector3 closestPointToPoint(Vector3 point, bool clampToLine, Vector3 target) {
    final t = closestPointToPointParameter(point, clampToLine);

    return delta(target).scale(t).add(start);
  }

  /// Applies a matrix transform to the line segment.
  Line3 applyMatrix4(Matrix4 matrix) {
    start.applyMatrix4(matrix);
    end.applyMatrix4(matrix);

    return this;
  }

  /// [line] - [Line3] to compare with this one.
  /// 
  /// Returns true if both line's [start] and [end] points
  /// are equal.
  bool equals(Line3 line) {
    return line.start.equals(start) && line.end.equals(end);
  }
}
