import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class DebugEnvironment extends Scene {

	DebugEnvironment():super(){
		final geometry = BoxGeometry();
		geometry.deleteAttributeFromString( 'uv' );
		final roomMaterial = MeshStandardMaterial.fromMap( { 'metalness': 0, 'side': BackSide } );
		final room = Mesh( geometry, roomMaterial );
		room.scale.setScalar( 10 );
		add( room );

		final mainLight = PointLight( 0xffffff, 50, 0, 2 );
		add( mainLight );

		final material1 = MeshLambertMaterial.fromMap( { 'color': 0xff0000, 'emissive': 0xffffff, 'emissiveIntensity': 10 } );

		final light1 = Mesh( geometry, material1 );
		light1.position.setValues( - 5, 2, 0 );
		light1.scale.setValues( 0.1, 1, 1 );
		add( light1 );

		final material2 = MeshLambertMaterial.fromMap( { 'color': 0x00ff00, 'emissive': 0xffffff, 'emissiveIntensity': 10 } );

		final light2 = Mesh( geometry, material2 );
		light2.position.setValues( 0, 5, 0 );
		light2.scale.setValues( 1, 0.1, 1 );
		add( light2 );

		final material3 = MeshLambertMaterial.fromMap( { 'color': 0x0000ff, 'emissive': 0xffffff, 'emissiveIntensity': 10 } );

		final light3 = Mesh( geometry, material3 );
		light3.position.setValues( 2, 1, 5 );
		light3.scale.setValues( 1.5, 2, 0.1 );
		add( light3 );

	}
}