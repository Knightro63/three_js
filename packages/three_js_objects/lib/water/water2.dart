import 'dart:async';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';
import './reflector.dart';
import './refractor.dart';

class WaterOptions{
  WaterOptions({
    this.color = 0xffffff,
    this.textureWidth = 512,
    this.textureHeight = 512,
    this.clipBias = 0.0,
    Map<String,dynamic>? shader,
    this.scale = 1,
    this.flowSpeed = 0.03,
    this.reflectivity = 0.02,
    Vector2? flowDirection,
    this.flowMap,
    FutureOr<Texture?>? normalMap0,
    FutureOr<Texture?>? normalMap1
  }){
    this.shader = shader ?? Water.waterShader;
    this.flowDirection = flowDirection ?? Vector2( 1, 0 );

    final textureLoader = TextureLoader();
    this.normalMap0 = normalMap0 ?? textureLoader.fromAsset( 'assets/Water_1_M_Normal.jpg',package: 'three_js_objects');
    this.normalMap1 = normalMap1 ?? textureLoader.fromAsset( 'assets/Water_2_M_Normal.jpg',package: 'three_js_objects');
  }

  WaterOptions.fromMap(Map<String,dynamic> options){
    color = options['color'] ?? 0xFFFFFF;
		textureWidth = options['textureWidth'] ?? 512;
		textureHeight = options['textureHeight'] ?? 512;
		clipBias = options['clipBias'] ?? 0.0;
		flowDirection = options['flowDirection'] ?? Vector2( 1, 0 );
		flowSpeed = options['flowSpeed'] ?? 0.03;
		reflectivity = options['reflectivity'] ?? 0.02;
		scale = options['scale'] ?? 1;
		shader = options['shader'] ?? Water.waterShader;

		final textureLoader = TextureLoader();

		flowMap = options['flowMap'];
    if(options['normalMap0'] == null){
      textureLoader.fromAsset( 'assets/Water_1_M_Normal.jpg',package: 'three_js_objects').then((m){
        normalMap0 = m!;
      });
    }
    else{
      normalMap0 = options['normalMap0'];
    }

    if(options['normalMap1'] == null){
      textureLoader.fromAsset( 'assets/Water_2_M_Normal.jpg',package: 'three_js_objects').then((m){
        normalMap1 = m!;
      });
    }
    else{
      normalMap1 = options['normalMap1'];
    }
  }

  late int color;
  late int textureWidth;
  late int textureHeight;
  late double clipBias;
  late Vector2 flowDirection;
  late double flowSpeed;
  late double reflectivity;
  late double scale;
  late Map<String, dynamic> shader;
  late dynamic flowMap;
  late FutureOr<Texture?> normalMap0;
  late FutureOr<Texture?> normalMap1;
}

/**
 * References:
 *	https://alex.vlachos.com/graphics/Vlachos-SIGGRAPH10-WaterFlow.pdf
 *	http://graphicsrunner.blogspot.de/2010/08/water-using-flow-maps.html
 *
 */

class Water extends Mesh {
  bool isWater = true;
  final cycle = 0.15; // a cycle of a flow map phase
  late double halfCycle;
  late double flowSpeed;
  final textureMatrix = Matrix4();
  final clock = Clock();

	Water(super.geometry, [WaterOptions? options]) {
		type = 'Water';
    options ??= WaterOptions();
    _init(options);
  }
  
  Future<void> _init(WaterOptions options)async{
		final color = Color.fromHex32(options.color);
		final textureWidth = options.textureWidth;
		final textureHeight = options.textureHeight;
		final clipBias = options.clipBias;
		final flowDirection = options.flowDirection;
		flowSpeed = options.flowSpeed;
		final reflectivity = options.reflectivity;
		final scale = options.scale;
		final shader = options.shader;

		final flowMap = options.flowMap;
		final normalMap0 = await options.normalMap0;
		final normalMap1 = await options.normalMap1;

    halfCycle = cycle * 0.5;

		final reflector = Reflector( geometry, {
			'textureWidth': textureWidth,
			'textureHeight': textureHeight,
			'clipBias': clipBias
		} );

		final refractor = Refractor( geometry, {
			'textureWidth': textureWidth,
			'textureHeight': textureHeight,
			'clipBias': clipBias
		} );

		reflector.matrixAutoUpdate = false;
		refractor.matrixAutoUpdate = false;

		// material

		material = ShaderMaterial.fromMap( {
      'name': shader['name'],
			'uniforms': UniformsUtils.merge( [
				uniformsLib[ 'fog' ],
				shader['uniforms']
			] ),
			'vertexShader': shader['vertexShader'],
			'fragmentShader': shader['fragmentShader'],
			'transparent': true,
			'fog': true
		} );

		if ( flowMap != null ) {
			material?.defines?['USE_FLOWMAP'] = '';
			material?.uniforms[ 'tFlowMap' ] = {
				type: 't',
				'value': flowMap
			};
		}
    else {
			material?.uniforms[ 'flowDirection' ] = {
				type: 'v2',
				'value': flowDirection
			};
		}

		// maps

		normalMap0?.wrapS = RepeatWrapping;
		normalMap1?.wrapS = RepeatWrapping;
		normalMap0?.wrapT = RepeatWrapping;
		normalMap1?.wrapT = RepeatWrapping;

		//material?.uniforms[ 'tReflectionMap' ]['value'] = reflector.getRenderTarget().texture;
		material?.uniforms[ 'tRefractionMap' ]['value'] = refractor.getRenderTarget().texture;
		material?.uniforms[ 'tNormalMap0' ]['value'] = normalMap0;
		material?.uniforms[ 'tNormalMap1' ]['value'] = normalMap1;

		// water

		material?.uniforms[ 'color' ]['value'] = color;
		material?.uniforms[ 'reflectivity' ]['value'] = reflectivity;
		material?.uniforms[ 'textureMatrix' ]['value'] = textureMatrix;

		// inital values

		material?.uniforms[ 'config' ]['value'].x = 0.0; // flowMapOffset0
		material?.uniforms[ 'config' ]['value'].y = halfCycle; // flowMapOffset1
		material?.uniforms[ 'config' ]['value'].z = halfCycle; // halfCycle
		material?.uniforms[ 'config' ]['value'].w = scale*1.0; // scale

    onBeforeRender = ({
      WebGLRenderer? renderer,
      RenderTarget? renderTarget,
      Object3D? mesh,
      Scene? scene,
      Camera? camera,
      BufferGeometry? geometry,
      Material? material,
      Map<String, dynamic>? group
    }){
      updateTextureMatrix( camera! );
      updateFlow();

      visible = true;

      reflector.matrixWorld.setFrom(matrixWorld );
      refractor.matrixWorld.setFrom(matrixWorld );

      reflector.onBeforeRender!(renderer:renderer, scene:scene, camera:camera, renderTarget: renderTarget);
      refractor.onBeforeRender!(renderer:renderer, scene:scene, camera:camera);

      visible = true;
    };
  }
  void updateTextureMatrix(Camera camera ) {
    textureMatrix.setValues(
      0.5, 0.0, 0.0, 0.5,
      0.0, 0.5, 0.0, 0.5,
      0.0, 0.0, 0.5, 0.5,
      0.0, 0.0, 0.0, 1.0
    );

    textureMatrix.multiply( camera.projectionMatrix );
    textureMatrix.multiply( camera.matrixWorldInverse );
    textureMatrix.multiply( matrixWorld );
  }

  void updateFlow() {
    final delta = clock.getDelta();
    final config = material?.uniforms[ 'config' ];

    config['value'].x += flowSpeed * delta; // flowMapOffset0
    config['value'].y = config['value'].x + halfCycle; // flowMapOffset1

    // Important: The distance between offsets should be always the value of "halfCycle".
    // Moreover, both offsets should be in the range of [ 0, cycle ].
    // This approach ensures a smooth water flow and avoids "reset" effects.

    if ( config['value'].x >= cycle ) {
      config['value'].x = 0.0;
      config['value'].y = halfCycle;
    } else if ( config['value'].y >= cycle ) {
      config['value'].y = config['value'].y - cycle;
    }
  }

  static Map<String,dynamic> waterShader = {
    'uniforms': {
      'color': {
        'type': 'c',
        'value': null
      },
      'reflectivity': {
        'type': 'f',
        'value': 0
      },
      'tReflectionMap': {
        'type': 't',
        'value': null
      },
      'tRefractionMap': {
        'type': 't',
        'value': null
      },
      'tNormalMap0': {
        'type': 't',
        'value': null
      },
      'tNormalMap1': {
        'type': 't',
        'value': null
      },
      'textureMatrix': {
        'type': 'm4',
        'value': null
      },
      'config': {
        'type': 'v4',
        'value': Vector4.identity()
      }
    },

    'vertexShader': '''
      #include <common>
      #include <fog_pars_vertex>
      #include <logdepthbuf_pars_vertex>

      uniform mat4 textureMatrix;

      varying vec4 vCoord;
      varying vec2 vUv;
      varying vec3 vToEye;

      void main() {

        vUv = uv;
        vCoord = textureMatrix * vec4( position, 1.0 );

        vec4 worldPosition = modelMatrix * vec4( position, 1.0 );
        vToEye = cameraPosition - worldPosition.xyz;

        vec4 mvPosition =  viewMatrix * worldPosition; // used in fog_vertex
        gl_Position = projectionMatrix * mvPosition;

        #include <logdepthbuf_vertex>
        #include <fog_vertex>

      }''',

    'fragmentShader':'''
      #include <common>
      #include <fog_pars_fragment>
      #include <logdepthbuf_pars_fragment>

      uniform sampler2D tReflectionMap;
      uniform sampler2D tRefractionMap;
      uniform sampler2D tNormalMap0;
      uniform sampler2D tNormalMap1;

      #ifdef USE_FLOWMAP
        uniform sampler2D tFlowMap;
      #else
        uniform vec2 flowDirection;
      #endif

      uniform vec3 color;
      uniform float reflectivity;
      uniform vec4 config;

      varying vec4 vCoord;
      varying vec2 vUv;
      varying vec3 vToEye;

      void main() {

        #include <logdepthbuf_fragment>

        float flowMapOffset0 = config.x;
        float flowMapOffset1 = config.y;
        float halfCycle = config.z;
        float scale = config.w;

        vec3 toEye = normalize( vToEye );

        // determine flow direction
        vec2 flow;
        #ifdef USE_FLOWMAP
          flow = texture2D( tFlowMap, vUv ).rg * 2.0 - 1.0;
        #else
          flow = flowDirection;
        #endif
        flow.x *= - 1.0;

        // sample normal maps (distort uvs with flowdata)
        vec4 normalColor0 = texture2D( tNormalMap0, ( vUv * scale ) + flow * flowMapOffset0 );
        vec4 normalColor1 = texture2D( tNormalMap1, ( vUv * scale ) + flow * flowMapOffset1 );

        // linear interpolate to get the final normal color
        float flowLerp = abs( halfCycle - flowMapOffset0 ) / halfCycle;
        vec4 normalColor = mix( normalColor0, normalColor1, flowLerp );

        // calculate normal vector
        vec3 normal = normalize( vec3( normalColor.r * 2.0 - 1.0, normalColor.b,  normalColor.g * 2.0 - 1.0 ) );

        // calculate the fresnel term to blend reflection and refraction maps
        float theta = max( dot( toEye, normal ), 0.0 );
        float reflectance = reflectivity + ( 1.0 - reflectivity ) * pow( ( 1.0 - theta ), 5.0 );

        // calculate final uv coords
        vec3 coord = vCoord.xyz / vCoord.w;
        vec2 uv = coord.xy + coord.z * normal.xz * 0.05;

        vec4 reflectColor = texture2D( tReflectionMap, vec2( 1.0 - uv.x, uv.y ) );
        vec4 refractColor = texture2D( tRefractionMap, uv );

        // multiply water color with the mix of both textures
        gl_FragColor = vec4( color, 1.0 ) * mix( refractColor, reflectColor, reflectance );

        #include <tonemapping_fragment>
        #include <colorspace_fragment>
        #include <fog_fragment>

      }'''
  };
}