import '../math/math_util.dart';
import '../matrix/matrix4.dart';
import '../vector/vector3.dart';

final _startP = Vector3();
final _startEnd = Vector3();

class Line3 {
  late Vector3 start;
  late Vector3 end;

  Line3([Vector3? start, Vector3? end]) {
    this.start = (start != null) ? start : Vector3();
    this.end = (end != null) ? end : Vector3();
  }

  Line3 setStartEnd(Vector3 start, Vector3 end) {
    this.start.setFrom(start);
    this.end.setFrom(end);

    return this;
  }

  Line3 clone() {
    return Line3().setFrom(this);
  }

  Line3 setFrom(Line3 line) {
    start.setFrom(line.start);
    end.setFrom(line.end);

    return this;
  }

  Vector3 getCenter(Vector3 target) {
    return target.add2(start, end).scale(0.5);
  }

  Vector3 delta(Vector3 target) {
    return target.sub2(end, start);
  }

  num distanceSq() {
    return start.distanceToSquared(end);
  }

  num distance() {
    return start.distanceTo(end);
  }

  Vector3 at(num t, Vector3 target) {
    return delta(target).scale(t).add(start);
  }

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

  Vector3 closestPointToPoint(Vector3 point, bool clampToLine, Vector3 target) {
    final t = closestPointToPointParameter(point, clampToLine);

    return delta(target).scale(t).add(start);
  }

  Line3 applyMatrix4(Matrix4 matrix) {
    start.applyMatrix4(matrix);
    end.applyMatrix4(matrix);

    return this;
  }

  bool equals(Line3 line) {
    return line.start.equals(start) && line.end.equals(end);
  }
}
