import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/// Creates a tube that extrudes along a 3d curve.
/// 
/// ```
/// class CustomSinCurve extends Curve {
///   double scale;
///   CustomSinCurve([this.scale = 1]):super();
///
///   Vector3 getPoint( t, [Vector3? optionalTarget]) {
///     optionalTarget ??= Vector3();
///     final tx = t * 3 - 1.5;
///     final ty = math.sin( 2 * math.pi * t );
///     const tz = 0.0;
///
///     return optionalTarget.setValues(tx, ty, tz).scale(scale);
///   }
/// }
///
/// final path = CustomSinCurve( 10 );
/// final geometry = TubeGeometry( path, 20, 2, 8, false );
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0x00ff00 } );
/// final mesh = Mesh( geometry, material );
/// scene.add( mesh );
/// ```