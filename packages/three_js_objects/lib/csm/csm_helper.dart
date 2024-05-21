import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_objects/csm/csm.dart';

class CSMHelper extends Group {
  late LineSegments frustumLines;
  List<BoundingBoxHelper> cascadeLines = [];
  List<Mesh> cascadePlanes = [];
  List<Group> shadowLines = [];
  CSM csm;

  bool displayFrustum = true;
  bool displayPlanes = true;
  bool displayShadowBounds = true;

	CSMHelper(this.csm ):super() {
		final indices = Uint16Array.from( [ 0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7 ] );
		final positions = Float32Array( 24 );
		final frustumGeometry = BufferGeometry();
		frustumGeometry.setIndex( Uint16BufferAttribute( indices, 1 ) );
		frustumGeometry.setAttributeFromString( 'position', Float32BufferAttribute( positions, 3, false ) );
		final frustumLines = LineSegments( frustumGeometry, LineBasicMaterial() );
		add( frustumLines );

		this.frustumLines = frustumLines;
	}

	void updateVisibility() {
		final displayFrustum = this.displayFrustum;
		final displayPlanes = this.displayPlanes;
		final displayShadowBounds = this.displayShadowBounds;

		final frustumLines = this.frustumLines;
		final cascadeLines = this.cascadeLines;
		final cascadePlanes = this.cascadePlanes;
		final shadowLines = this.shadowLines;
		for (int i = 0, l = cascadeLines.length; i < l; i ++ ) {

			final cascadeLine = cascadeLines[ i ];
			final cascadePlane = cascadePlanes[ i ];
			final shadowLineGroup = shadowLines[ i ];

			cascadeLine.visible = displayFrustum;
			cascadePlane.visible = displayFrustum && displayPlanes;
			shadowLineGroup.visible = displayShadowBounds;

		}

		frustumLines.visible = displayFrustum;
	}

	void update() {
		final csm = this.csm;
		final camera = csm.data.camera;
		final cascades = csm.data.cascades;
		final mainFrustum = csm.mainFrustum;
		final frustums = csm.frustums;
		final lights = csm.lights;

		final frustumLines = this.frustumLines;
		final frustumLinePositions = frustumLines.geometry?.getAttributeFromString( 'position' );
		final cascadeLines = this.cascadeLines;
		final cascadePlanes = this.cascadePlanes;
		final shadowLines = this.shadowLines;

		position.setFrom( camera.position );
		quaternion.setFrom( camera.quaternion );
		scale.setFrom( camera.scale );
		updateMatrixWorld( true );

		while ( cascadeLines.length > cascades ) {
			remove( cascadeLines.removeLast() );
			remove( cascadePlanes.removeLast() );
			remove( shadowLines.removeLast() );
		}

		while ( cascadeLines.length < cascades ) {
			final cascadeLine = BoundingBoxHelper( BoundingBox(), 0xffffff );
			final planeMat = MeshBasicMaterial.fromMap( { 'transparent': true, 'opacity': 0.1, 'depthWrite': false, 'side': DoubleSide } );
			final cascadePlane = Mesh( PlaneGeometry(), planeMat );
			final shadowLineGroup = Group();
			final shadowLine = BoundingBoxHelper( BoundingBox(), 0xffff00 );
			shadowLineGroup.add( shadowLine );

			add( cascadeLine );
			add( cascadePlane );
			add( shadowLineGroup );

			cascadeLines.add( cascadeLine );
			cascadePlanes.add( cascadePlane );
			shadowLines.add( shadowLineGroup );
		}

		for (int i = 0; i < cascades; i ++ ) {

			final frustum = frustums[ i ];
			final light = lights[ i ];
			final shadowCam = light.shadow!.camera!;
			final farVerts = frustum.vertices.far;

			final cascadeLine = cascadeLines[ i ];
			final cascadePlane = cascadePlanes[ i ];
			final shadowLineGroup = shadowLines[ i ];
			final shadowLine = shadowLineGroup.children[ 0 ];

			cascadeLine.box?.min.setFrom( farVerts[ 2 ] );
			cascadeLine.box?.max.setFrom( farVerts[ 0 ] );
			cascadeLine.box?.max.z += 1e-4;

			cascadePlane.position.add2( farVerts[ 0 ], farVerts[ 2 ] );
			cascadePlane.position.scale( 0.5 );
			cascadePlane.scale.sub2( farVerts[ 0 ], farVerts[ 2 ] );
			cascadePlane.scale.z = 1e-4;

			remove( shadowLineGroup );
			shadowLineGroup.position.setFrom( shadowCam.position );
			shadowLineGroup.quaternion.setFrom( shadowCam.quaternion );
			shadowLineGroup.scale.setFrom( shadowCam.scale );
			shadowLineGroup.updateMatrixWorld( true );
			attach( shadowLineGroup );

			(shadowLine as BoundingBoxHelper).box?.min.setValues( shadowCam.bottom, shadowCam.left, - shadowCam.far );
			shadowLine.box?.max.setValues( shadowCam.top, shadowCam.right, - shadowCam.near );
		}

		final nearVerts = mainFrustum.vertices.near;
		final farVerts = mainFrustum.vertices.far;
		frustumLinePositions.setXYZ( 0, farVerts[ 0 ].x, farVerts[ 0 ].y, farVerts[ 0 ].z );
		frustumLinePositions.setXYZ( 1, farVerts[ 3 ].x, farVerts[ 3 ].y, farVerts[ 3 ].z );
		frustumLinePositions.setXYZ( 2, farVerts[ 2 ].x, farVerts[ 2 ].y, farVerts[ 2 ].z );
		frustumLinePositions.setXYZ( 3, farVerts[ 1 ].x, farVerts[ 1 ].y, farVerts[ 1 ].z );

		frustumLinePositions.setXYZ( 4, nearVerts[ 0 ].x, nearVerts[ 0 ].y, nearVerts[ 0 ].z );
		frustumLinePositions.setXYZ( 5, nearVerts[ 3 ].x, nearVerts[ 3 ].y, nearVerts[ 3 ].z );
		frustumLinePositions.setXYZ( 6, nearVerts[ 2 ].x, nearVerts[ 2 ].y, nearVerts[ 2 ].z );
		frustumLinePositions.setXYZ( 7, nearVerts[ 1 ].x, nearVerts[ 1 ].y, nearVerts[ 1 ].z );
		frustumLinePositions.needsUpdate = true;

	}

  @override
	void dispose() {
		final frustumLines = this.frustumLines;
		final cascadeLines = this.cascadeLines;
		final cascadePlanes = this.cascadePlanes;
		final shadowLines = this.shadowLines;

		frustumLines.geometry?.dispose();
		frustumLines.material?.dispose();

		final cascades = csm.data.cascades;

		for (int i = 0; i < cascades; i ++ ) {

			final cascadeLine = cascadeLines[ i ];
			final cascadePlane = cascadePlanes[ i ];
			final shadowLineGroup = shadowLines[ i ];
			final shadowLine = shadowLineGroup.children[ 0 ];

			cascadeLine.dispose(); // Box3Helper

			cascadePlane.geometry?.dispose();
			cascadePlane.material?.dispose();

			shadowLine.dispose(); // Box3Helper
		}
	}
}
