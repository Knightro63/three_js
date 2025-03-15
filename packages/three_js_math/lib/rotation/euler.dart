import 'dart:math' as math;
import '../math/index.dart';
import '../matrix/index.dart';
import '../vector/index.dart';
import '../rotation/index.dart';

enum RotationOrders{
  xyz,
  yzx,
  zxy,
  xzy,
  yxz,
  zyx;

  static RotationOrders fromString(String order){
    for(int i = 0; i < RotationOrders.values.length;i++){
      if(RotationOrders.values[i].name == order.toLowerCase()){
        return RotationOrders.values[i];
      }
    }
    return RotationOrders.xyz;
  }
}

/// A class representing [Euler Angles](http://en.wikipedia.org/wiki/Euler_angles).
/// 
/// Euler angles describe a rotational transformation by rotating an object on
/// its various axes in specified amounts per axis, and a specified axis
/// order.
/// 
/// ```
/// final a = Euler( 0, 1, 1.57, RotationOrders.xyz);
/// final b = Vector3( 1, 0, 1 );
/// b.applyEuler(a);
/// ```
class Euler {
  String type = "Euler";
  
  static const RotationOrders defaultOrder = RotationOrders.xyz;

  late double _x;
  late double _y;
  late double _z;
  late RotationOrders _order;

  Function onChangeCallback = () {};

  /// [x] - (optional) the angle of the x axis in radians. Default is
  /// `0`.
  /// 
  /// [y] - (optional) the angle of the y axis in radians. Default is
  /// `0`.
  /// 
  /// [z] - (optional) the angle of the z axis in radians. Default is
  /// `0`.
  /// 
  /// [order] - (optional) a enum representing the order that the
  /// rotations are applied, defaults to [RotationOrders.xyz].
  Euler([double? x, double? y, double? z, RotationOrders? order]) {
    _x = x ?? 0;
    _y = y ?? 0;
    _z = z ?? 0;
    _order = order ?? defaultOrder;
  }

  double get x => _x;
  set x(double value) {
    _x = value;
    onChangeCallback();
  }

  double get y => _y;
  set y(double value) {
    _y = value;
    onChangeCallback();
  }

  double get z => _z;
  set z(double value) {
    _z = value;
    onChangeCallback();
  }

  RotationOrders get order => _order;
  set order(RotationOrders value) {
    _order = value;
    onChangeCallback();
  }

  /// [x] - the angle of the x axis in radians.
  /// 
  /// [y] - the angle of the y axis in radians.
  /// 
  /// [z] - the angle of the z axis in radians.
  /// 
  /// [order] - (optional) a string representing the order that the
  /// rotations are applied.
  /// 
  /// Sets the angles of this euler transform and optionally the [order].
  Euler set(double x, double y, double z, [RotationOrders? order]) {
    _x = x;
    _y = y;
    _z = z;
    _order = order ?? _order;

    onChangeCallback();

    return this;
  }

  /// Returns a new Euler with the same parameters as this one.
  Euler clone() {
    return Euler(_x, _y, _z, _order);
  }

  /// Copies value of [euler] to this euler.
  Euler copy(Euler euler) {
    _x = euler._x;
    _y = euler._y;
    _z = euler._z;
    _order = euler._order;

    onChangeCallback();

    return this;
  }

  /// [m] - a [Matrix4] of which the upper 3x3 of matrix is a
  /// pure [rotation matrix](https://en.wikipedia.org/wiki/Rotation_matrix)
  /// (i.e. unscaled).
  /// 
  /// [order] - (optional) a string representing the order that the
  /// rotations are applied.
  /// 
  /// Sets the angles of this euler transform from a pure rotation matrix based
  /// on the orientation specified by order.
  Euler setFromRotationMatrix(Matrix4 m, [RotationOrders? order, bool? update]) {
    //final clamp = MathUtils.clamp;

    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

    final te = m.storage;
    double m11 = te[0], m12 = te[4], m13 = te[8];
    double m21 = te[1], m22 = te[5], m23 = te[9];
    double m31 = te[2], m32 = te[6], m33 = te[10];

    order = order ?? _order;

    switch (order) {
      case RotationOrders.xyz:
        _y = math.asin(MathUtils.clamp(m13, -1, 1));

        if (m13.abs() < 0.9999999) {
          _x = math.atan2(-m23, m33);
          _z = math.atan2(-m12, m11);
        } else {
          _x = math.atan2(m32, m22);
          _z = 0;
        }

        break;

      case RotationOrders.yxz:
        _x = math.asin(-MathUtils.clamp(m23, -1, 1));

        if (m23.abs() < 0.9999999) {
          _y = math.atan2(m13, m33);
          _z = math.atan2(m21, m22);
        } else {
          _y = math.atan2(-m31, m11);
          _z = 0;
        }

        break;

      case RotationOrders.zxy:
        _x = math.asin(MathUtils.clamp(m32, -1, 1));

        if (m32.abs() < 0.9999999) {
          _y = math.atan2(-m31, m33);
          _z = math.atan2(-m12, m22);
        } else {
          _y = 0;
          _z = math.atan2(m21, m11);
        }

        break;

      case RotationOrders.zyx:
        _y = math.asin(-MathUtils.clamp(m31, -1, 1));

        if (m31.abs() < 0.9999999) {
          _x = math.atan2(m32, m33);
          _z = math.atan2(m21, m11);
        } else {
          _x = 0;
          _z = math.atan2(-m12, m22);
        }

        break;

      case RotationOrders.yzx:
        _z = math.asin(MathUtils.clamp(m21, -1, 1));

        if (m21.abs() < 0.9999999) {
          _x = math.atan2(-m23, m22);
          _y = math.atan2(-m31, m11);
        } else {
          _x = 0;
          _y = math.atan2(m13, m33);
        }

        break;

      case RotationOrders.xzy:
        _z = math.asin(-MathUtils.clamp(m12, -1, 1));

        if (m12.abs() < 0.9999999) {
          _x = math.atan2(m32, m22);
          _y = math.atan2(m13, m11);
        } else {
          _x = math.atan2(-m23, m33);
          _y = 0;
        }
        break;
    }

    _order = order;

    if (update != false) onChangeCallback();

    return this;
  }

  /// [q] - a normalized quaternion.
  /// 
  /// [order] - (optional) a string representing the order that the
  /// rotations are applied.
  /// 
  /// Sets the angles of this euler transform from a normalized quaternion based
  /// on the orientation specified by [order].
  Euler setFromQuaternion(Quaternion q, [RotationOrders? order, bool update = false]) {
    _matrix.makeRotationFromQuaternion(q);

    return setFromRotationMatrix(_matrix, order, update);
  }

  /// [v] - [Vector3].
  /// 
  /// [order] - (optional) a string representing the order that the
  /// rotations are applied.
  /// 
  /// Set the [x], [y] and [z], and optionally update
  /// the [order].
  Euler setFromVector3(Vector3 v, [RotationOrders? order]) {
    return set(v.x, v.y, v.z, order ?? _order);
  }

  /// Resets the euler angle with a new order by creating a quaternion from this
  /// euler angle and then setting this euler angle with the quaternion and the
  /// new order.
  /// 
  /// <em>*Warning*: this discards revolution information.</em>
  Euler reorder(RotationOrders newOrder) {
    // WARNING: this discards revolution information -bhouston
    _quaternion.setFromEuler(this, false);
    return setFromQuaternion(_quaternion, newOrder, false);
  }

  bool equals(Euler euler) {
    return (euler._x == _x) &&
        (euler._y == _y) &&
        (euler._z == _z) &&
        (euler._order == _order);
  }


  /// [array] of length 3 or 4. The optional 4th argument corresponds
  /// to the [order].
  /// 
  /// Assigns this euler's [x] angle to `array[0]`.
  /// 
  /// Assigns this euler's [y] angle to `array[1]`.
  /// 
  /// Assigns this euler's [z] angle to `array[2]`.
  /// 
  /// Optionally assigns this euler's [order] to `array[3]`.
  Euler fromArray(List<double> array) {
    _x = array[0];
    _y = array[1];
    _z = array[2];
    if (array.length > 3) _order = RotationOrders.values[array[3].toInt()];

    onChangeCallback();

    return this;
  }

  List<num> toList() {
    int orderNo = _order.index;
    return [_x, _y, _z, orderNo];
  }

  /// [array] - (optional) array to store the euler in.
  /// 
  /// [offset] (optional) offset in the array.
  /// 
  /// Returns an array of the form [[x], [y], [z],
  /// [order]].
  List<num> toArray([List<num>? array, int offset = 0]) {
    array ??= List<num>.filled(offset + 4, 0);
    array[offset] = _x;
    array[offset + 1] = _y;
    array[offset + 2] = _z;
    array[offset + 3] = _order.index;

    return array;
  }

  @Deprecated('.toVector3 has been removed. Use Vector3.setFromEuler() instead')
  Vector3 toVector3([Vector3? optionalResult]) {
    if (optionalResult != null) {
      optionalResult.setValues(_x, _y, _z);
      return optionalResult;
    } 
    else {
      return Vector3(_x, _y, _z);
    }
  }

  void onChange(Function callback) {
    onChangeCallback = callback;
  }
}

final _matrix = Matrix4.identity();
final _quaternion = Quaternion.identity();
