import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class Lensflare extends Mesh {
  late void Function() dispose1;
  late void Function(dynamic) addElement;

  static BufferGeometry Geometry = _geometry();

  Lensflare.create(super.geometry,super.material){
    type = 'Lensflare';
    frustumCulled = false;
    renderOrder = double.maxFinite.toInt();
  	final positionScreen = Vector3();
		final positionView = Vector3();

		// textures

		final tempMap = FramebufferTexture( 16, 16 );
		final occlusionMap = FramebufferTexture( 16, 16 );

		int currentType = UnsignedByteType;

		// material

		final geometry = Lensflare.Geometry;

		final material1a = RawShaderMaterial.fromMap( {
			'uniforms': {
				'scale': <String,dynamic>{ 'value': null },
				'screenPosition': <String,dynamic>{ 'value': null }
			},
			'vertexShader': /* glsl */'''

				precision highp float;

				uniform vec3 screenPosition;
				uniform vec2 scale;

				attribute vec3 position;

				void main() {

					gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );

				}''',

			'fragmentShader': /* glsl */'''

				precision highp float;

				void main() {

					gl_FragColor = vec4( 1.0, 0.0, 1.0, 1.0 );

				}''',
			'depthTest': true,
			'depthWrite': false,
			'transparent': false
		} );

		final material1b = RawShaderMaterial.fromMap( {
			'uniforms': {
				'map': <String,dynamic>{ 'value': tempMap },
				'scale': <String,dynamic>{ 'value': null },
				'screenPosition': <String,dynamic>{ 'value': null }
			},
			'vertexShader': /* glsl */'''

				precision highp float;

				uniform vec3 screenPosition;
				uniform vec2 scale;

				attribute vec3 position;
				attribute vec2 uv;

				varying vec2 vUV;

				void main() {

					vUV = uv;

					gl_Position = vec4( position.xy * scale + screenPosition.xy, screenPosition.z, 1.0 );

				}''',

			'fragmentShader': /* glsl */'''

				precision highp float;

				uniform sampler2D map;

				varying vec2 vUV;

				void main() {

					gl_FragColor = texture2D( map, vUV );

				}''',
			'depthTest': false,
			'depthWrite': false,
			'transparent': false
		} );

		// the following object is used for occlusionMap generation

		final mesh1 = Mesh( geometry, material1a );

		//

		final List elements = [];

		final shader = LensflareElement.shader;

		final material2 = RawShaderMaterial.fromMap( {
			'name': shader['name'],
			'uniforms': {
				'map': <String,dynamic>{ 'value': null },
				'occlusionMap': <String,dynamic>{ 'value': occlusionMap },
				'color': <String,dynamic>{ 'value': Color.fromHex32( 0xffffff ) },
				'scale': <String,dynamic>{ 'value': Vector2() },
				'screenPosition': <String,dynamic>{ 'value': Vector3() }
			},
			'vertexShader': shader['vertexShader'],
			'fragmentShader': shader['fragmentShader'],
			'blending': AdditiveBlending,
			'transparent': true,
			'depthWrite': false
		} );

		final mesh2 = Mesh( geometry, material2 );

		addElement = ( element ) {
			elements.add( element );
		};

		//

		final scale = Vector2();
		final screenPositionPixels = Vector2();
		final validArea = BoundingBox();
		final viewport = Vector4();

		onBeforeRender = ({
      WebGLRenderer? renderer,
      RenderTarget? renderTarget,
      Object3D? mesh,
      Scene? scene,
      Camera? camera,
      BufferGeometry? geometry,
      Material? material,
      Map<String, dynamic>? group
    }) {
			renderer?.getCurrentViewport( viewport );

			final renderTarget = renderer!.getRenderTarget();
			final type = ( renderTarget != null ) ? renderTarget.texture.type : UnsignedByteType;

			if ( currentType != type ) {

				tempMap.dispose();
				occlusionMap.dispose();

				tempMap.type = occlusionMap.type = type;

				currentType = type;

			}

			final invAspect = viewport.w / viewport.z;
			final halfViewportWidth = viewport.z / 2.0;
			final halfViewportHeight = viewport.w / 2.0;

			double size = 16 / viewport.w;
			scale.setValues( size * invAspect, size );

			validArea.min.setValues( viewport.x, viewport.y );
			validArea.max.setValues( viewport.x + ( viewport.z - 16 ), viewport.y + ( viewport.w - 16 ) );

			// calculate position in screen space

			positionView.setFromMatrixPosition(matrixWorld );
			positionView.applyMatrix4( camera!.matrixWorldInverse );

			if ( positionView.z > 0 ) return; // lensflare is behind the camera

			positionScreen.setFrom( positionView ).applyMatrix4( camera.projectionMatrix );

			// horizontal and vertical coordinate of the lower left corner of the pixels to copy

			screenPositionPixels.x = viewport.x + ( positionScreen.x * halfViewportWidth ) + halfViewportWidth - 8;
			screenPositionPixels.y = viewport.y + ( positionScreen.y * halfViewportHeight ) + halfViewportHeight - 8;

			// screen cull

			if ( validArea.containsPoint(screenPositionPixels ) ) {

				// save current RGB to temp texture

				renderer.copyFramebufferToTexture( screenPositionPixels, tempMap );

				// render pink quad

				Map<String, dynamic> uniforms = material1a.uniforms;
				uniforms['scale'] = <String, dynamic>{'value' : scale};
				uniforms['screenPosition'] = <String, dynamic>{'value': positionScreen};

				renderer.renderBufferDirect( camera, null, geometry!, material1a, mesh1, null );

				// copy result to occlusionMap

				renderer.copyFramebufferToTexture( screenPositionPixels, occlusionMap );

				// restore graphics

				uniforms = material1b.uniforms;
				uniforms['scale'] = <String, dynamic>{'value' : scale};
				uniforms['screenPosition'] = <String, dynamic>{'value': positionScreen};

				renderer.renderBufferDirect( camera, null, geometry, material1b, mesh1, null );

				// render elements

				final vecX = - positionScreen.x * 2;
				final vecY = - positionScreen.y * 2;

				for (int i = 0, l = elements.length; i < l; i ++ ) {
					final element = elements[i];
					final uniforms = material2.uniforms;

					uniforms[ 'color' ]['value'].setFrom( element.color );
					uniforms[ 'map' ]['value'] = element.texture;
					uniforms[ 'screenPosition' ]['value'].x = positionScreen.x + vecX * element.distance;
					uniforms[ 'screenPosition' ]['value'].y = positionScreen.y + vecY * element.distance;

					size = element.size / viewport.w;
					final invAspect = viewport.w / viewport.z;

					uniforms[ 'scale' ]['value'].setValues( size * invAspect, size );

					material2.uniformsNeedUpdate = true;

					renderer.renderBufferDirect( camera, null, geometry, material2, mesh2, null );
				}
			}
		};

		dispose1 = () {
			material1a.dispose();
			material1b.dispose();
			material2.dispose();

			tempMap.dispose();
			occlusionMap.dispose();

			for (int i = 0, l = elements.length; i < l; i ++ ) {
				elements[i].texture.dispose();
			}
		};
  }

	factory Lensflare() {
    return Lensflare.create(Lensflare.Geometry, MeshPhongMaterial.fromMap( { 'opacity': 0, 'transparent': true } ));
	}

  @override
  void dispose(){
    dispose1();
  }
}

class LensflareElement {
  Texture texture;
  double size;
  double distance;
  late Color color;

  static Map<String,dynamic> shader = _shader;

	LensflareElement(this.texture, [this.size = 1, this.distance = 0, int color = 0xffffff]) {
		this.color = Color.fromHex32( color);
	}
}

const _shader = {
	'name': 'LensflareElementShader',

	'uniforms': {
		'map': { 'value': null },
		'occlusionMap': { 'value': null },
		'color': { 'value': null },
		'scale': { 'value': null },
		'screenPosition': { 'value': null }
	},

	'vertexShader': /* glsl */'''

		precision highp float;

		uniform vec3 screenPosition;
		uniform vec2 scale;

		uniform sampler2D occlusionMap;

		attribute vec3 position;
		attribute vec2 uv;

		varying vec2 vUV;
		varying float vVisibility;

		void main() {

			vUV = uv;

			vec2 pos = position.xy;

			vec4 visibility = texture2D( occlusionMap, vec2( 0.1, 0.1 ) );
			visibility += texture2D( occlusionMap, vec2( 0.5, 0.1 ) );
			visibility += texture2D( occlusionMap, vec2( 0.9, 0.1 ) );
			visibility += texture2D( occlusionMap, vec2( 0.9, 0.5 ) );
			visibility += texture2D( occlusionMap, vec2( 0.9, 0.9 ) );
			visibility += texture2D( occlusionMap, vec2( 0.5, 0.9 ) );
			visibility += texture2D( occlusionMap, vec2( 0.1, 0.9 ) );
			visibility += texture2D( occlusionMap, vec2( 0.1, 0.5 ) );
			visibility += texture2D( occlusionMap, vec2( 0.5, 0.5 ) );

			vVisibility =        visibility.r / 9.0;
			vVisibility *= 1.0 - visibility.g / 9.0;
			vVisibility *=       visibility.b / 9.0;

			gl_Position = vec4( ( pos * scale + screenPosition.xy ).xy, screenPosition.z, 1.0 );

		}''',

	'fragmentShader': /* glsl */'''

		precision highp float;

		uniform sampler2D map;
		uniform vec3 color;

		varying vec2 vUV;
		varying float vVisibility;

		void main() {

			vec4 texture = texture2D( map, vUV );
			texture.a *= vVisibility;
			gl_FragColor = texture;
			gl_FragColor.rgb *= color;

		}'''

};

BufferGeometry _geometry(){

	final geometry = BufferGeometry();

	final float32Array = Float32List.fromList( [
		- 1, - 1, 0, 0, 0,
		1, - 1, 0, 1, 0,
		1, 1, 0, 1, 1,
		- 1, 1, 0, 0, 1
	] );

	final interleavedBuffer = InterleavedBuffer.fromList( float32Array, 5 );

	geometry.setIndex( [ 0, 1, 2,	0, 2, 3 ] );
	geometry.setAttributeFromString( 'position', InterleavedBufferAttribute( interleavedBuffer, 3, 0, false ) );
	geometry.setAttributeFromString( 'uv', InterleavedBufferAttribute( interleavedBuffer, 2, 3, false ) );

	return geometry;
}
