import 'line_material.dart';
import 'line_segments_geometry.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _start = Vector3();
final _end = Vector3();

final _start4 = Vector4();
final _end4 = Vector4();

final _ssOrigin = Vector4();
final _ssOrigin3 = Vector3();
final _mvMatrix = Matrix4();
final _line = Line3();
final _closestPoint = Vector3();

final _box = BoundingBox();
final _sphere = BoundingSphere();
final _clipToWorldVector = Vector4();

final _vector =  Vector3();

Ray _ray = Ray();
double _lineWidth = 0;

extension on BoundingBox{
  BoundingBox expandByScalar(double scalar ) {
		this.min.addScalar( - scalar );
		this.max.addScalar( scalar );
		return this;
	}
	double distanceToPoint(Vector3 point ) {
		return this.clampPoint( point, _vector ).distanceTo( point );
	}
}
extension on BoundingSphere{
	double distanceToPoint(Vector3 point ) {
		return ( point.distanceTo( this.center ) - this.radius );
	}
}

class LineIntersection extends Intersection{
  Vector3? pointOnLine;

  LineIntersection({
    super.instanceId,
    required super.distance,
    super.distanceToRay,
    super.point,
    super.index,
    super.face,
    super.faceIndex,
    super.object,
    super.uv,
    super.uv2,
    this.pointOnLine
  });
}

// Returns the margin required to expand by in world space given the distance from the camera,
// line width, resolution, and camera projection
double getWorldSpaceHalfWidth(Camera camera, double distance, Vector2 resolution ) {
	// transform into clip space, adjust the x and y values by the pixel width offset, then
	// transform back into world space to get world offset. Note clip space is [-1, 1] so full
	// width does not need to be halved.
	_clipToWorldVector.setValues( 0, 0, - distance, 1.0 ).applyMatrix4( camera.projectionMatrix );
	_clipToWorldVector.scale( 1.0 / _clipToWorldVector.w );
	_clipToWorldVector.x = _lineWidth / resolution.x;
	_clipToWorldVector.y = _lineWidth / resolution.y;
	_clipToWorldVector.applyMatrix4( camera.projectionMatrixInverse );
	_clipToWorldVector.scale( 1.0 / _clipToWorldVector.w );

	return ( math.max( _clipToWorldVector.x, _clipToWorldVector.y ) ).abs();
}

void raycastWorldUnits(LineSegments2 lineSegments,List<Intersection> intersects ) {
	final matrixWorld = lineSegments.matrixWorld;
	final geometry = lineSegments.geometry!;
	final instanceStart = geometry.attributes['instanceStart'];
	final instanceEnd = geometry.attributes['instanceEnd'];
	final segmentCount = math.min<int>( geometry.instanceCount!, instanceStart.count );

	for (int i = 0, l = segmentCount; i < l; i ++ ) {
		_line.start.fromBuffer( instanceStart, i );
		_line.end.fromBuffer( instanceEnd, i );

		_line.applyMatrix4( matrixWorld );

		final pointOnLine = Vector3();
		final point = Vector3();

		_ray.distanceSqToSegment( _line.start, _line.end, point, pointOnLine );
		final isInside = point.distanceTo( pointOnLine ) < _lineWidth * 0.5;

		if ( isInside ) {

			intersects.add( 
        LineIntersection(
          point: point,
          distance: _ray.origin.distanceTo( point ),
          object: lineSegments,
          face: null,
          faceIndex: i,
          uv: null,
          pointOnLine: pointOnLine,
          uv2: null,
        )
      );
		}
	}
}

void raycastScreenSpace(LineSegments2 lineSegments,Camera camera,List<Intersection> intersects ) {
	final projectionMatrix = camera.projectionMatrix;
	final material = lineSegments.material as LineMaterial;
	final resolution = material.resolution;
	final matrixWorld = lineSegments.matrixWorld;

	final geometry = lineSegments.geometry!;
	final instanceStart = geometry.attributes['instanceStart'];
	final instanceEnd = geometry.attributes['instanceEnd'];
	final segmentCount = math.min<int>( geometry.instanceCount!, instanceStart.count );

	final near = - camera.near;

	//

	// pick a point 1 unit out along the ray to avoid the ray origin
	// sitting at the camera origin which will cause "w" to be 0 when
	// applying the projection matrix.
	_ray.at( 1, _ssOrigin );

	// ndc space [ - 1.0, 1.0 ]
	_ssOrigin.w = 1;
	_ssOrigin.applyMatrix4( camera.matrixWorldInverse );
	_ssOrigin.applyMatrix4( projectionMatrix );
	_ssOrigin.scale( 1 / _ssOrigin.w );

	// screen space
	_ssOrigin.x *= resolution.x / 2;
	_ssOrigin.y *= resolution.y / 2;
	_ssOrigin.z = 0;

	_ssOrigin3.setFrom( _ssOrigin );

	_mvMatrix.multiply2(camera.matrixWorldInverse, matrixWorld );

	for ( int i = 0, l = segmentCount; i < l; i ++ ) {

		_start4.fromBuffer( instanceStart, i );
		_end4.fromBuffer( instanceEnd, i );

		_start4.w = 1;
		_end4.w = 1;

		// camera space
		_start4.applyMatrix4( _mvMatrix );
		_end4.applyMatrix4( _mvMatrix );

		// skip the segment if it's entirely behind the camera
		final isBehindCameraNear = _start4.z > near && _end4.z > near;
		if ( isBehindCameraNear ) {

			continue;

		}

		// trim the segment if it extends behind camera near
		if ( _start4.z > near ) {

			final deltaDist = _start4.z - _end4.z;
			final t = ( _start4.z - near ) / deltaDist;
			_start4.lerp( _end4, t );

		} else if ( _end4.z > near ) {

			final deltaDist = _end4.z - _start4.z;
			final t = ( _end4.z - near ) / deltaDist;
			_end4.lerp( _start4, t );

		}

		// clip space
		_start4.applyMatrix4( projectionMatrix );
		_end4.applyMatrix4( projectionMatrix );

		// ndc space [ - 1.0, 1.0 ]
		_start4.scale( 1 / _start4.w );
		_end4.scale( 1 / _end4.w );

		// screen space
		_start4.x *= resolution.x / 2;
		_start4.y *= resolution.y / 2;

		_end4.x *= resolution.x / 2;
		_end4.y *= resolution.y / 2;

		// create 2d segment
		_line.start.setFrom( _start4 );
		_line.start.z = 0;

		_line.end.setFrom( _end4 );
		_line.end.z = 0;

		// get closest point on ray to segment
		final param = _line.closestPointToPointParameter( _ssOrigin3, true );
		_line.at( param, _closestPoint );

		// check if the intersection point is within clip space
		final zPos = ( 1 - param ) * _start4.z + param * _end4.z;
		final isInClipSpace = zPos >= - 1 && zPos <= 1;

		final isInside = _ssOrigin3.distanceTo( _closestPoint ) < _lineWidth * 0.5;

		if ( isInClipSpace && isInside ) {

			_line.start.fromBuffer( instanceStart, i );
			_line.end.fromBuffer( instanceEnd, i );

			_line.start.applyMatrix4( matrixWorld );
			_line.end.applyMatrix4( matrixWorld );

			final pointOnLine = Vector3();
			final point = Vector3();

			_ray.distanceSqToSegment( _line.start, _line.end, point, pointOnLine );

			intersects.add( LineIntersection(
				point: point,
				distance: _ray.origin.distanceTo( point ),
				object: lineSegments,
				face: null,
				faceIndex: i,
				uv: null,
        pointOnLine: pointOnLine,
				uv2: null,
      ));
		}
	}
}

class LineSegments2 extends Mesh {
	LineSegments2.create(super.geometry, super.material){
		this.type = 'LineSegments2';
	}
	factory LineSegments2([LineSegmentsGeometry? geometry, LineMaterial? material]) {
    material ??= LineMaterial.fromMap( { 'color': (math.Random().nextDouble() * 0xffffff).toInt() });
    geometry ??= LineSegmentsGeometry();
    return LineSegments2.create(geometry,material);
	}

	// for backwards-compatibility, but could be a method of LineSegmentsGeometry...

	LineSegments2 computeLineDistances() {
		final geometry = this.geometry!;

		final instanceStart = geometry.attributes['instanceStart'];
		final instanceEnd = geometry.attributes['instanceEnd'];
		final lineDistances = Float32Array( (2 * instanceStart.count).toInt() );

		for ( int i = 0, j = 0, l = instanceStart.count; i < l; i ++, j += 2 ) {
			_start.fromBuffer( instanceStart, i );
			_end.fromBuffer( instanceEnd, i );

			lineDistances[ j ] = ( j == 0 ) ? 0 : lineDistances[ j - 1 ];
			lineDistances[ j + 1 ] = lineDistances[ j ] + _start.distanceTo( _end );
		}

		final instanceDistanceBuffer = InstancedInterleavedBuffer( lineDistances, 2, 1 ); // d0, d1

		geometry.setAttributeFromString( 'instanceDistanceStart', InterleavedBufferAttribute( instanceDistanceBuffer, 1, 0 ) ); // d0
		geometry.setAttributeFromString( 'instanceDistanceEnd', InterleavedBufferAttribute( instanceDistanceBuffer, 1, 1 ) ); // d1

		return this;
	}

	void raycast(Raycaster raycaster,List<Intersection> intersects ) {
    final material = this.material! as LineMaterial;
    
		final worldUnits = material.worldUnits;
		final camera = raycaster.camera;

		if(worldUnits == null) {
			console.error( 'LineSegments2: "Raycaster.camera" needs to be set in order to raycast against LineSegments2 while worldUnits is set to false.' );
		}

		final threshold = ( raycaster.params['Line2'] != null ) ? raycaster.params['Line2'].threshold ?? 0 : 0;

		_ray = raycaster.ray;

		final matrixWorld = this.matrixWorld;
		final geometry = this.geometry!;
		

		_lineWidth = material.linewidth! + threshold;

		// check if we intersect the sphere bounds
		if ( geometry.boundingSphere == null ) {
			geometry.computeBoundingSphere();
		}

		_sphere.setFrom(geometry.boundingSphere!).applyMatrix4( matrixWorld );

		// increase the sphere bounds by the worst case line screen space width
		late double sphereMargin;
		if ( worldUnits == true){
			sphereMargin = _lineWidth * 0.5;
		} 
    else {
			final distanceToSphere = math.max( camera.near, _sphere.distanceToPoint( _ray.origin ) );
			sphereMargin = getWorldSpaceHalfWidth( camera, distanceToSphere, material.resolution );
		}

		_sphere.radius += sphereMargin;

		if ( _ray.intersectsSphere( _sphere ) == false ) {
			return;
		}

		// check if we intersect the box bounds
    if(geometry.boundingBox == null){
		  geometry.computeBoundingBox();
    }
		_box.setFrom( geometry.boundingBox! ).applyMatrix4( matrixWorld );

		// increase the box bounds by the worst case line width
		late double boxMargin;
		if ( worldUnits == true) {
			boxMargin = _lineWidth * 0.5;
		} 
    else {
			final distanceToBox = math.max( camera.near, _box.distanceToPoint( _ray.origin ) );
			boxMargin = getWorldSpaceHalfWidth( camera, distanceToBox, material.resolution );
		}

		_box.expandByScalar( boxMargin );

		if ( _ray.intersectsBox( _box ) == false ) {
			return;
		}

		if ( worldUnits == true) {
			raycastWorldUnits( this, intersects );
		} 
    else {
			raycastScreenSpace( this, camera, intersects );
		}
	}
}
