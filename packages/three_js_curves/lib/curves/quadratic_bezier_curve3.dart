import '../core/curve.dart';
import '../core/interpolations.dart';
import 'package:three_js_math/three_js_math.dart';
class QuadraticBezierCurve3 extends Curve{
  bool isQuadraticBezierCurve3 = true;

  QuadraticBezierCurve3([Vector3? v0, Vector3? v1, Vector3? v2]):super(){
    this.v0 = v0 ?? Vector3.zero();
    this.v1 = v1 ?? Vector3.zero();
    this.v2 = v2 ?? Vector3.zero();
  }

  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final point = Vector3.zero();

    if(optionalTarget != null){
      point.setFrom(optionalTarget);
    }

    final v0 = this.v0 as Vector3; 
    final v1 = this.v1 as Vector3; 
    final v2 = this.v2 as Vector3;

    point.setValues(
      PathInterpolations.quadraticBezier( t, v0.x, v1.x, v2.x ),
      PathInterpolations.quadraticBezier( t, v0.y, v1.y, v2.y ),
      PathInterpolations.quadraticBezier( t, v0.z, v1.z, v2.z )
    );

    return point;
  }

  @override
  QuadraticBezierCurve3 copy(Curve source){
    super.copy(source);

    v0.setFrom( source.v0 );
    v1.setFrom( source.v1 );
    v2.setFrom( source.v2 );

    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    final data = super.toJson();

    data['v0'] = v0.copyIntoArray();
    data['v1'] = v1.copyIntoArray();
    data['v2'] = v2.copyIntoArray();

    return data;
  }

  @override
  QuadraticBezierCurve3 fromJson(Map<String,dynamic> json ) {
    super.fromJson(json);
    v0.copyFromArray( json['v0'] );
    v1.copyFromArray( json['v1'] );
    v2.copyFromArray( json['v2'] );

    return this;
  }
}
