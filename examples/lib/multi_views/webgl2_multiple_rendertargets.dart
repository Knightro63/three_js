import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class Webgl2MultipleRendertargets extends StatefulWidget {
  const Webgl2MultipleRendertargets({super.key});
  @override
  createState() => _State();
}

class _State extends State<Webgl2MultipleRendertargets> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useOpenGL: useOpenGL
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: panel.render()
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late three.Scene postScene;
  late three.Camera postCamera;

  final Map<String,dynamic> parameters = {
    'samples': 4.0,
    'wireframe': false
  };

  final String gbufferVert = '''
			in vec3 position;
			in vec3 normal;
			in vec2 uv;

			out vec3 vNormal;
			out vec2 vUv;

			uniform mat4 modelViewMatrix;
			uniform mat4 projectionMatrix;
			uniform mat3 normalMatrix;

			void main() {

				vUv = uv;

				// get smooth normals
				vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );

				vec3 transformedNormal = normalMatrix * normal;
				vNormal = normalize( transformedNormal );

				gl_Position = projectionMatrix * mvPosition;

			}
  ''';

  final String gbufferFrag = '''
			precision highp float;
			precision highp int;

			layout(location = 0) out vec4 gColor;
			layout(location = 1) out vec4 gNormal;

			uniform sampler2D tDiffuse;
			uniform vec2 repeat;

			in vec3 vNormal;
			in vec2 vUv;

			void main() {

				// write color to G-Buffer
				gColor = texture( tDiffuse, vUv * repeat );

				// write normals to G-Buffer
				gNormal = vec4( normalize( vNormal ), 0.0 );

			}
  ''';

  final String renderVert = '''
			in vec3 position;
			in vec2 uv;

			out vec2 vUv;

			uniform mat4 modelViewMatrix;
			uniform mat4 projectionMatrix;

			void main() {

				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

			}
  ''';
  final String renderFrag = '''
			precision highp float;
			precision highp int;

			vec4 LinearTosRGB( in vec4 value ) {
				return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
			}

			layout(location = 0) out vec4 pc_FragColor;

			in vec2 vUv;

			uniform sampler2D tDiffuse;
			uniform sampler2D tNormal;

			void main() {

				vec4 diffuse = texture( tDiffuse, vUv );
				vec4 normal = texture( tNormal, vUv );

				pc_FragColor = mix( diffuse, normal, step( 0.5, vUv.x ) );
				pc_FragColor.a = 1.0;

				pc_FragColor = LinearTosRGB( pc_FragColor );

			}
  ''';

  Future<void> setup() async {
    // Create a multi render target with Float buffers

    final renderTarget = three.WebGLRenderTarget(
      (threeJs.width * threeJs.dpr).toInt(),
      (threeJs.height * threeJs.dpr).toInt(),
      three.WebGLRenderTargetOptions({
        'count': 2,
        'minFilter': three.NearestFilter,
        'magFilter': three.NearestFilter
      })
    );

    // Name our G-Buffer attachments for debugging

    renderTarget.textures[0].name = 'diffuse';
    renderTarget.textures[1].name = 'normal';

    // Scene setup

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x222222 );

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 0.1, 50 );
    threeJs.camera.position.z = 4;

    final loader = three.TextureLoader();

    final diffuse = await loader.fromAsset( 'assets/textures/hardwood2_diffuse.jpg');// render );
    diffuse?.wrapS = three.RepeatWrapping;
    diffuse?.wrapT = three.RepeatWrapping;
    diffuse?.colorSpace = three.SRGBColorSpace;

    threeJs.scene.add( three.Mesh(
      TorusKnotGeometry( 1, 0.3, 128, 32 ),
      three.RawShaderMaterial.fromMap( {
        'name': 'G-Buffer Shader',
        'vertexShader': gbufferVert.trim(),
        'fragmentShader': gbufferFrag.trim(),
        'uniforms': {
          'tDiffuse': { 'value': diffuse },
          'repeat': { 'value': three.Vector2( 5, 0.5 ) }
        },
        'glslVersion': three.GLSL3
      } )
    ) );

    // PostProcessing setup

    postScene = three.Scene();
    postCamera = three.OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );

    postScene.add( three.Mesh(
      three.PlaneGeometry( 2,2),
      three.RawShaderMaterial.fromMap( {
        'name': 'Post-FX Shader',
        'vertexShader': renderVert.trim(),
        'fragmentShader': renderFrag.trim(),
        'uniforms': {
          'tDiffuse': { 'value': renderTarget.textures[ 0 ] },
          'tNormal': { 'value': renderTarget.textures[ 1 ] },
        },
        'glslVersion': three.GLSL3
      } )
    ) );
    // Controls

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );

    threeJs.postProcessor = ([dt]){
      renderTarget.samples = parameters['samples'].toInt();

      threeJs.scene.traverse(( child ) {
        if ( child.material != null ) {
          child.material?.wireframe = parameters['wireframe'];
        }
      } );

      threeJs.renderer?.setRenderTarget( null );
      threeJs.renderer?.render( postScene, postCamera );

      threeJs.renderer?.setRenderTarget( renderTarget );
      threeJs.renderer?.render( threeJs.scene, threeJs.camera );
    };

    initGui();
  }

  void initGui(){
    final gui = panel.addFolder('GUI')..open();
    gui.addSlider( parameters, 'samples', 0, 4 ).step( 1 );
    gui.addButton( parameters, 'wireframe' ).onChange((dt){threeJs.render();});
  }
}
