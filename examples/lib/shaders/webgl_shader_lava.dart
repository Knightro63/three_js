import 'dart:async';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglShaderLava extends StatefulWidget {
  
  const WebglShaderLava({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglShaderLava> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,      settings: three.Settings(
        autoClear: false,
        useSourceTexture: true,
        
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    composer.dispose();
    renderModel.dispose();
    effectBloom.dispose();
    outputPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data)
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  late final RenderPass renderModel;
  final effectBloom = BloomPass( 1.25 );
  late final EffectComposer composer;
  final outputPass = OutputPass();

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 35, threeJs.width/threeJs.height, 1, 3000 );
    threeJs.camera.position.z = 4;

    threeJs.scene = three.Scene();

    final textureLoader = three.TextureLoader();

    final cloudTexture = await textureLoader.fromAsset( 'assets/textures/lava/cloud.png' );
    final lavaTexture = await textureLoader.fromAsset( 'assets/textures/lava/lavatile.jpg' );

    lavaTexture?.colorSpace = three.SRGBColorSpace;

    cloudTexture?.wrapS = three.RepeatWrapping;
    cloudTexture?.wrapT = three.RepeatWrapping;
    lavaTexture?.wrapS = three.RepeatWrapping;
    lavaTexture?.wrapT = three.RepeatWrapping;

    final Map<String,dynamic> uniforms = {
      'fogDensity': { 'value': 0.15 },
      'fogColor': { 'value': three.Vector3( 0, 0, 0 ) },
      'time': { 'value': 1.0 },
      'uvScale': { 'value': three.Vector2( 3.0, 1.0 ) },
      'texture1': { 'value': cloudTexture },
      'texture2': { 'value': lavaTexture }
    };

    const vertexShader = '''
			uniform vec2 uvScale;
			varying vec2 vUv;

			void main()
			{

				vUv = uvScale * uv;
				vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
				gl_Position = projectionMatrix * mvPosition;

			}
    ''';

    const fragmentShader = '''
			uniform float time;

			uniform float fogDensity;
			uniform vec3 fogColor;

			uniform sampler2D texture1;
			uniform sampler2D texture2;

			varying vec2 vUv;

			void main( void ) {

				vec2 position = - 1.0 + 2.0 * vUv;

				vec4 noise = texture2D( texture1, vUv );
				vec2 T1 = vUv + vec2( 1.5, - 1.5 ) * time * 0.02;
				vec2 T2 = vUv + vec2( - 0.5, 2.0 ) * time * 0.01;

				T1.x += noise.x * 2.0;
				T1.y += noise.y * 2.0;
				T2.x -= noise.y * 0.2;
				T2.y += noise.z * 0.2;

				float p = texture2D( texture1, T1 * 2.0 ).a;

				vec4 color = texture2D( texture2, T2 * 2.0 );
				vec4 temp = color * ( vec4( p, p, p, p ) * 2.0 ) + ( color * color - 0.1 );

				if( temp.r > 1.0 ) { temp.bg += clamp( temp.r - 2.0, 0.0, 100.0 ); }
				if( temp.g > 1.0 ) { temp.rb += temp.g - 1.0; }
				if( temp.b > 1.0 ) { temp.rg += temp.b - 1.0; }

				gl_FragColor = temp;

				float depth = gl_FragCoord.z / gl_FragCoord.w;
				const float LOG2 = 1.442695;
				float fogFactor = exp2( - fogDensity * fogDensity * depth * depth * LOG2 );
				fogFactor = 1.0 - clamp( fogFactor, 0.0, 1.0 );

				gl_FragColor = mix( gl_FragColor, vec4( fogColor, gl_FragColor.w ), fogFactor );

			}
    ''';

    const size = 0.65;

    final material = three.ShaderMaterial.fromMap( {
      'uniforms': uniforms,
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader
    } );

    final mesh = three.Mesh( TorusGeometry( size, 0.3, 30, 30 ), material );
    mesh.rotation.x = 0.3;
    threeJs.scene.add( mesh );

    renderModel = RenderPass( threeJs.scene, threeJs.camera );
    composer = EffectComposer( threeJs.renderer!, threeJs.renderTarget);

    composer.addPass( renderModel );
    composer.addPass( effectBloom );
    composer.addPass( outputPass );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);

    threeJs.postProcessor = ([double? dt]){
      threeJs.renderer!.setRenderTarget(null);
      composer.render(dt);
      threeJs.renderer!.render(threeJs.scene, threeJs.camera);
    };

    threeJs.addAnimationEvent((dt){
      controls.update();
      uniforms[ 'time' ]!['value'] += 0.3 * dt;

      mesh.rotation.y += 0.0125 * dt;
      mesh.rotation.x += 0.05 * dt;
    });

  }
}
