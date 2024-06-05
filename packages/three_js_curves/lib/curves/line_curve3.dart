import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';

/// A curve representing a 3d line segment.
class LineCurve3 extends Curve{

  /// [v1] – The start point.
  ///
  /// [v2] - The end point.
  LineCurve3([Vector3? v1,Vector3? v2]):super(){
    isLineCurve3 = true;

    this.v1 = v1 ?? Vector3.zero();
    this.v2 = v2 ?? Vector3.zero();
  }

  @override
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final point = Vector3.zero();//optionalTarget;
    if(optionalTarget != null){
      point.setFrom(optionalTarget);
    }

    if ( t == 1 ) {
      point.setFrom(v2);
    } else {
      point.setFrom(v2).sub(v1);
      point.scale(t).add(v1);
    }

    return point;
  }

  // Line curve is linear, so we can overwrite default getPointAt
  @override
  Vector? getPointAt(double u, [Vector? optionalTarget]) {
    return getPoint( u, optionalTarget );
  }
  
  @override
  LineCurve3 copy(Curve source ) {
    super.copy(source);

    v1.setFrom( source.v1 );
    v2.setFrom( source.v2 );

    return this;
  }

  Map<String,dynamic> toJSON () {
    final data = super.toJson();

    data['v1'] = v1.copyIntoArray();
    data['v2'] = v2.copyIntoArray();

    return data;
  }

  @override
  LineCurve3 fromJson(Map<String,dynamic> json ) {
    super.fromJson(json);

    v1.copyFromArray( json['v1'] );
    v2.copyFromArray( json['v2'] );

    return this;
  }
}
