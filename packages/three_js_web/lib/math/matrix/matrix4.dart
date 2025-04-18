import 'dart:typed_data';
import 'index.dart';
import '../vector/index.dart';
import '../rotation/index.dart';
import 'dart:math' as math;
import 'dart:js_interop';

@JS('Matrix4')
class Matrix4 {
  external Matrix4();
  Matrix4.identity() {
    (
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0
    );
  }
  Matrix4.zero() {
    set(
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0
    );
  }
  
  Matrix4 copyMatrixToVector3(Matrix4 m, [int row = 3]) {
    final te = storage, me = m.storage;

    te[row*4] = me[row*4];
    te[row*4+1] = me[row*4+1];
    te[row*4+2] = me[row*4+2];

    return this;
  }

  external Matrix4 set([
    double n11,
    double n12,
    double n13,
    double n14,
    double n21,
    double n22,
    double n23,
    double n24,
    double n31,
    double n32,
    double n33,
    double n34,
    double n41,
    double n42,
    double n43,
    double n44
  ]);
  
  Matrix4 setValues(
    double n11,
    double n12,
    double n13,
    double n14,
    double n21,
    double n22,
    double n23,
    double n24,
    double n31,
    double n32,
    double n33,
    double n34,
    double n41,
    double n42,
    double n43,
    double n44
  ) {
    return set(n11,n21,n31,n41,n21,n22,n23,n24,n31,n32,n33,n34,n41,n42,n43,n44);
  }

  Matrix4 identity() {
    return set(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,0.0, 1.0);
  }

  external Matrix4 clone();
  external Matrix4 setFrom(Matrix4 m);
  external Matrix4 copyPosition(Matrix4 m);
  external Matrix4 setFromMatrix3(Matrix3 m);
  external Matrix4 extractBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis);
  external Matrix4 makeBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis);
  external Matrix4 extractRotation(Matrix4 m);
  external Matrix4 makeRotationFromEuler(Euler euler);

  external Matrix4 makeRotationFromQuaternion(Quaternion q);
  external Matrix4 lookAt(Vector3 eye, Vector3 target, Vector3 up);

  external Matrix4 multiply(Matrix4 m);
  external Matrix4 premultiply(Matrix4 m);
  external Matrix4 multiplyMatrices( a, b );
  Matrix4 multiply2(Matrix4 a, Matrix4 b) {
    return multiplyMatrices( a, b );
  }

  external scale(Vector3 v);

  Matrix4 scale(double s) {
    final te = storage;

    te[0] *= s;
    te[4] *= s;
    te[8] *= s;
    te[12] *= s;
    te[1] *= s;
    te[5] *= s;
    te[9] *= s;
    te[13] *= s;
    te[2] *= s;
    te[6] *= s;
    te[10] *= s;
    te[14] *= s;
    te[3] *= s;
    te[7] *= s;
    te[11] *= s;
    te[15] *= s;

    return this;
  }
  Matrix4 scaleByVector(Vector v) {
    final te = storage;
    final x = v.x; 
    final y = v.y;
    double z = 1;

    if(v is Vector3){
      z = v.z;
    }
    else if(v is Vector4){
      z = v.z;
    }

    te[0] *= x;
    te[4] *= y;
    te[8] *= z;
    te[1] *= x;
    te[5] *= y;
    te[9] *= z;
    te[2] *= x;
    te[6] *= y;
    te[10] *= z;
    te[3] *= x;
    te[7] *= y;
    te[11] *= z;

    return this;
  }

  external double determinant();
  external Matrix4 transpose();
  external Matrix4 setPosition(double x, double y, double z);

  Matrix4 setPositionFromVector3(Vector3 x) {
    return setPosition(x.x, x.y, x.z);
  }

  external Matrix4 invert();
  external double getMaxScaleOnAxis();
  external Matrix4 makeTranslation(double x, double y, double z);
  external Matrix4 makeRotationX(double theta);
  external Matrix4 makeRotationY(double theta);
  external Matrix4 makeRotationZ(double theta);
  external Matrix4 makeRotationAxis(Vector3 axis, double angle);

  external Matrix4 makeScale(double x, double y, double z);
  external Matrix4 makeShear(double xy, double xz, double yx, double yz, double zx, double zy);
  external Matrix4 compose(Vector3 position, Quaternion quaternion, Vector3 scale);

  external Matrix4 decompose(Vector3 position, Quaternion quaternion, Vector3 scale);
  external Matrix4 makePerspective(double left, double right, double top, double bottom, double near, double far);
  external Matrix4 makeOrthographic(double left, double right, double top, double bottom, double near, double far, [int coordinateSystem = 2000]);
  external bool equals(Matrix4 matrix);

  external Matrix4 fromArray( array, [int offset = 0 ]);
  Matrix4 fromNativeArray( array, [int offset = 0]) {
    return fromArray(array,offset);
  }
  Matrix4 copyFromArray(List<double> array, [int offset = 0]) {
    return fromArray(array,offset);
  }
  Matrix4 copyFromUnknown(array, [int offset = 0]) {
    return fromArray(array,offset);
  }

  external List<num> toArray([ array, int offset = 0 ]);
  List<num> copyIntoArray(List<num> array, [int offset = 0]) {
    return toArray(array,offset);
  }

  List<double> toList() {
    return storage.sublist(0);
  }
  @Deprecated('Use matrixInv.copy( matrix ).invert()')
  Matrix4 getInverse(Matrix4 matrix) {
    return setFrom(matrix).invert();
  }
}
