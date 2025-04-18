import 'dart:typed_data';
import 'package:flutter_angle/flutter_angle.dart';
import '../buffer/index.dart';
import '../matrix/matrix3.dart';

abstract class Vector {
  double get x => storage[0];
  set x(double value) => storage[0] = value;

  double get y => storage[1];
  set y(double value) => storage[1] = value;
  
  Float32List storage = Float32List(2);

  Vector([double x = 0, double y = 0]);
  Vector.copy(Vector v){
    throw('notimplimented');
  }
  Vector.zero();

  Vector setValues(double x, double y);
  bool equals(Vector v);
  Vector setFrom(Vector v);
  Vector sub(Vector a);
  Vector add(Vector a);
  Vector setScalar(double scalar);

  num getComponent(int index);
  Vector clone();
  Vector addScaled(Vector v, double s);
  Vector addScalar(double s);
  Vector subScalar(double s);
  double dot(Vector v);
  Vector scale(double scalar);
  Vector divideScalar(double scalar);
  Vector applyMatrix3(Matrix3 m);
  Vector clampScalar(double minVal, double maxVal);

  Vector clampLength<T extends num>(T min, T max);
  Vector floor();
  Vector ceil();
  Vector round();
  double distanceToSquared(Vector v);

  Vector roundToZero();
  Vector negate();
  double get length2 => 0;
  double get length => 0;
  double distanceTo(Vector v);

  double manhattanLength();
  Vector normalize();
  //double angle();
  Vector setLength(double length);
  Vector fromNativeArray(NativeArray array, [int offset = 0]);
  Vector copyFromUnknown(array, [int offset = 0]);
  List<num> toNumArray(List<num> array, [int offset = 0]);
  Vector copyFromArray(List<double> array, [int offset = 0]);
  List<double> copyIntoArray([List<double> array, int offset = 0]);

  List<double> toList();
  Vector fromBuffer(BufferAttribute attribute,int index);
  Vector random();
  Map<String, dynamic> toJson();
}
