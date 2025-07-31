import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class TubePainter{
	int BUFFER_SIZE = 1000000 * 3;
  int count = 0;
	late final Float32BufferAttribute positions;
	late final Float32BufferAttribute normals;
	late final Float32BufferAttribute colors;
	final BufferGeometry geometry = new BufferGeometry();

	final material = MeshStandardMaterial.fromMap( {
		'vertexColors': true
	});

	late final Mesh mesh;
	final vector1 = new Vector3();
	final vector2 = new Vector3();
	final vector3 = new Vector3();
	final vector4 = new Vector3();

	final color = new Color.fromHex32( 0xffffff );
	double size = 1;

	final up = new Vector3( 0, 1, 0 );
	final point1 = new Vector3();
	final point2 = new Vector3();
	final matrix1 = new Matrix4();
	final matrix2 = new Matrix4();

  TubePainter(){
    positions = Float32BufferAttribute( new Float32Array( BUFFER_SIZE ), 3 );
    positions.usage = DynamicDrawUsage;

    normals = Float32BufferAttribute( new Float32Array( BUFFER_SIZE ), 3 );
    normals.usage = DynamicDrawUsage;

    colors = Float32BufferAttribute( new Float32Array( BUFFER_SIZE ), 3 );
    colors.usage = DynamicDrawUsage;

    geometry.setAttributeFromString( 'position', positions );
    geometry.setAttributeFromString( 'normal', normals );
    geometry.setAttributeFromString( 'color', colors );
    geometry.drawRange['count'] = 0;

    mesh = new Mesh( geometry, material );
    mesh.frustumCulled = false;
  }

	List<Vector3> getPoints(double size ) {
		const PI2 = math.pi * 2;
		const sides = 10;
		final List<Vector3> array = [];
		final radius = 0.01 * size;

		for (int i = 0; i < sides; i ++ ) {
			final angle = ( i / sides ) * PI2;
			array.add( new Vector3( math.sin( angle ) * radius, math.cos( angle ) * radius, 0 ) );
		}

		return array;
	}

	void stroke(Vector3 position1,Vector3 position2,Matrix4 matrix1,Matrix4 matrix2 ) {
		if ( position1.distanceToSquared( position2 ) == 0 ) return;
		int count = geometry.drawRange['count']!;

		final points = getPoints( size );

		for (int i = 0, il = points.length; i < il; i ++ ) {
			final vertex1 = points[ i ];
			final vertex2 = points[ ( i + 1 ) % il ];

			// positions

			vector1.setFrom( vertex1 ).applyMatrix4( matrix2 ).add( position2 );
			vector2.setFrom( vertex2 ).applyMatrix4( matrix2 ).add( position2 );
			vector3.setFrom( vertex2 ).applyMatrix4( matrix1 ).add( position1 );
			vector4.setFrom( vertex1 ).applyMatrix4( matrix1 ).add( position1 );

			vector1.copyIntoNativeArray( positions.array, ( count + 0 ) * 3 );
			vector2.copyIntoNativeArray( positions.array, ( count + 1 ) * 3 );
			vector4.copyIntoNativeArray( positions.array, ( count + 2 ) * 3 );

			vector2.copyIntoNativeArray( positions.array, ( count + 3 ) * 3 );
			vector3.copyIntoNativeArray( positions.array, ( count + 4 ) * 3 );
			vector4.copyIntoNativeArray( positions.array, ( count + 5 ) * 3 );

			// normals

			vector1.setFrom( vertex1 ).applyMatrix4( matrix2 ).normalize();
			vector2.setFrom( vertex2 ).applyMatrix4( matrix2 ).normalize();
			vector3.setFrom( vertex2 ).applyMatrix4( matrix1 ).normalize();
			vector4.setFrom( vertex1 ).applyMatrix4( matrix1 ).normalize();

			vector1.copyIntoNativeArray( normals.array, ( count + 0 ) * 3 );
			vector2.copyIntoNativeArray( normals.array, ( count + 1 ) * 3 );
			vector4.copyIntoNativeArray( normals.array, ( count + 2 ) * 3 );

			vector2.copyIntoNativeArray( normals.array, ( count + 3 ) * 3 );
			vector3.copyIntoNativeArray( normals.array, ( count + 4 ) * 3 );
			vector4.copyIntoNativeArray( normals.array, ( count + 5 ) * 3 );

			// colors
			color.copyIntoArray( colors.array, ( count + 0 ) * 3 );
			color.copyIntoArray( colors.array, ( count + 1 ) * 3 );
			color.copyIntoArray( colors.array, ( count + 2 ) * 3 );

			color.copyIntoArray( colors.array, ( count + 3 ) * 3 );
			color.copyIntoArray( colors.array, ( count + 4 ) * 3 );
			color.copyIntoArray( colors.array, ( count + 5 ) * 3 );

			count += 6;
		}

		geometry.drawRange['count'] = count;
	}

	void moveTo(Vector3 position ) {
		point1.setFrom( position );
		matrix1.lookAt( point2, point1, up );
		point2.setFrom( position );
		matrix2.setFrom( matrix1 );
	}

	void lineTo(Vector3 position ) {
		point1.setFrom( position );
		matrix1.lookAt( point2, point1, up );
		stroke( point1, point2, matrix1, matrix2 );
		point2.setFrom( point1 );
		matrix2.setFrom( matrix1 );
	}

	void setSize(double value ) {
		size = value;
	}

	void update() {
		final start = count;
		final end = geometry.drawRange['count']!;

		if ( start == end ) return;

		positions.updateRange!['offset'] = start * 3;
		positions.updateRange!['count'] = ( end - start ) * 3;
		positions.needsUpdate = true;

		normals.updateRange!['offset'] = start * 3;
		normals.updateRange!['count'] = ( end - start ) * 3;
		normals.needsUpdate = true;

		colors.updateRange!['offset'] = start * 3;
		colors.updateRange!['count'] = ( end - start ) * 3;
		colors.needsUpdate = true;

		count = geometry.drawRange['count']!;
	}
}
