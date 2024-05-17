
import 'package:three_js_curves/three_js_curves.dart';

Curve? curves(String type,a,b,c,d,e,f){
  switch (type) {
    case 'ArcCurve':
      return ArcCurve(a,b,c,d,e,f);
    case 'CatmullRomCurve3':
      return CatmullRomCurve3(points: a,closed: b, curveType: c, tension: d);
    case 'CubicBezierCurve':
      return CubicBezierCurve(a,b,c,d);
    case 'CubicBezierCurve3':
      return CubicBezierCurve3(a,b,c,d);
    case 'EllipseCurve':
      return EllipseCurve(a,b,c,d,e,f);
    case 'LineCurve':
      return LineCurve(a,b);
    case 'LineCurve3':
      return LineCurve3(a,b);
    case 'QuadraticBezierCurve3':
      return QuadraticBezierCurve3(a,b,c);
    case 'QuadraticBezierCurve':
      return QuadraticBezierCurve(a,b,c);
    case 'SplineCurve':
      return SplineCurve(a);
    default:
      return null;
  }
}