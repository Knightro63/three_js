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

class Euler {
  String type = "Euler";
  
  static const RotationOrders defaultOrder = RotationOrders.xyz;

  late double _x;
  late double _y;
  late double _z;
  late RotationOrders _order;

  Function onChangeCallback = () {};

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

  Euler set(double x, double y, double z, [RotationOrders? order]) {
    _x = x;
    _y = y;
    _z = z;
    _order = order ?? _order;

    onChangeCallback();

    return this;
  }

  Euler clone() {
    return Euler(_x, _y, _z, _order);
  }

  Euler copy(Euler euler) {
    _x = euler._x;
    _y = euler._y;
    _z = euler._z;
    _order = euler._order;

    onChangeCallback();

    return this;
  }

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

      default:
        throw('THREE.Euler: .setFromRotationMatrix() encountered an unknown order: $order');
    }

    _order = order;

    if (update != false) onChangeCallback();

    return this;
  }

  Euler setFromQuaternion(Quaternion q, [RotationOrders? order, bool update = false]) {
    _matrix.makeRotationFromQuaternion(q);

    return setFromRotationMatrix(_matrix, order, update);
  }

  Euler setFromVector3(Vector3 v, [RotationOrders? order]) {
    return set(v.x, v.y, v.z, order ?? _order);
  }

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
