import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/** Set a PerspectiveCamera's projectionMatrix and quaternion
 * to exactly frame the corners of an arbitrary rectangle.
 * NOTE: This function ignores the standard parameters;
 * do not call updateProjectionMatrix() after this!
 * @param {Vector3} bottomLeftCorner
 * @param {Vector3} bottomRightCorner
 * @param {Vector3} topLeftCorner
 * @param {boolean} estimateViewFrustum */
class CameraUtils{
  static void frameCorners(Camera camera,Vector3 bottomLeftCorner,Vector3 bottomRightCorner,Vector3 topLeftCorner, [bool estimateViewFrustum = false] ) {
    final _va = Vector3(), // from pe to pa
      _vb = Vector3(), // from pe to pb
      _vc = Vector3(), // from pe to pc
      _vr = Vector3(), // right axis of screen
      _vu = Vector3(), // up axis of screen
      _vn = Vector3(), // normal vector of screen
      _vec = Vector3(), // temporary vector
      _quat = Quaternion(); // temporary quaternion
      
    final pa = bottomLeftCorner, pb = bottomRightCorner, pc = topLeftCorner;
    final pe = camera.position; // eye position
    final n = camera.near; // distance of near clipping plane
    final f = camera.far; //distance of far clipping plane

    _vr.setFrom( pb ).sub( pa ).normalize();
    _vu.setFrom( pc ).sub( pa ).normalize();
    _vn.cross2( _vr, _vu ).normalize();

    _va.setFrom( pa ).sub( pe ); // from pe to pa
    _vb.setFrom( pb ).sub( pe ); // from pe to pb
    _vc.setFrom( pc ).sub( pe ); // from pe to pc

    final d = - _va.dot( _vn );	// distance from eye to screen
    final l = _vr.dot( _va ) * n / d; // distance to left screen edge
    final r = _vr.dot( _vb ) * n / d; // distance to right screen edge
    final b = _vu.dot( _va ) * n / d; // distance to bottom screen edge
    final t = _vu.dot( _vc ) * n / d; // distance to top screen edge

    // Set the camera rotation to match the focal plane to the corners' plane
    _quat.setFromUnitVectors( _vec.setValues( 0, 1, 0 ), _vu );
    camera.quaternion.setFromUnitVectors( _vec.setValues( 0, 0, 1 ).applyQuaternion( _quat ), _vn ).multiply( _quat );

    // Set the off-axis projection matrix to match the corners
    camera.projectionMatrix.setValues( 2.0 * n / ( r - l ), 0.0,
      ( r + l ) / ( r - l ), 0.0, 0.0,
      2.0 * n / ( t - b ),
      ( t + b ) / ( t - b ), 0.0, 0.0, 0.0,
      ( f + n ) / ( n - f ),
      2.0 * f * n / ( n - f ), 0.0, 0.0, - 1.0, 0.0 );
    camera.projectionMatrixInverse.setFrom( camera.projectionMatrix ).invert();

    // FoV estimation to fix frustum culling
    if ( estimateViewFrustum ) {

      // Set fieldOfView to a conservative estimate
      // to make frustum tall/wide enough to encompass it
      camera.fov =
        MathUtils.rad2deg / math.min( 1.0, camera.aspect ) *
        math.atan( ( _vec.setFrom( pb ).sub( pa ).length +
                ( _vec.setFrom( pc ).sub( pa ).length ) ) / _va.length );

    }

  }
}
