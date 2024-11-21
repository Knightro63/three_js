import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglPostprocessingUnrealBloomSelective extends StatefulWidget {
  const WebglPostprocessingUnrealBloomSelective({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglPostprocessingUnrealBloomSelective> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late final Gui gui;

  @override
  void initState() {
    gui = Gui((){setState(() {});});
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
        animate: false,
        useSourceTexture: true,
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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
              child: gui.render()
            )
          )
        ],
      ) 
    );
  }

  late final EffectComposer bloomComposer;
  late final UnrealBloomPass bloomPass;
  late final RenderPass renderScene;
  late final three.OrbitControls controls;
  late final three.AnimationMixer mixer;
  late final EffectComposer finalComposer;

  int BLOOM_SCENE = 1;
	final three.Layers bloomLayer = three.Layers();

  final three.Raycaster raycaster = three.Raycaster();
  final three.Vector2 mouse = three.Vector2();

  final darkMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x000000 } );
  final Map<String,three.Material?> materials = {};

  final Map<String,double> params = {
    'threshold': 0,
    'strength': 1,
    'radius': 0,
    'exposure': 1
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 200 );
    threeJs.camera.position.setValues( 0, 0, 20 );
    threeJs.camera.lookAt(three.Vector3(0, 0, 0 ));

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.maxPolarAngle = math.pi * 0.5;
    controls.minDistance = 1;
    controls.maxDistance = 100;
    controls.addEventListener( 'change', render );

    renderScene = RenderPass( threeJs.scene, threeJs.camera );

    bloomPass = UnrealBloomPass( three.Vector2( threeJs.width, threeJs.height ), 1.5, 0.4, 0.85 );
    bloomPass.threshold = params['threshold']!;
    bloomPass.strength = params['strength']!;
    bloomPass.radius = params['radius']!;

    bloomComposer = EffectComposer( threeJs.renderer! );
    bloomComposer.renderToScreen = false;
    bloomComposer.addPass( renderScene );
    bloomComposer.addPass( bloomPass );

    final mixPass = ShaderPass(
      three.ShaderMaterial.fromMap( {
        'uniforms': {
          'baseTexture': <String,dynamic>{ 'value': null },
          'bloomTexture': <String,dynamic>{ 'value': bloomComposer.renderTarget2.texture }
        },
        'vertexShader': '''
          varying vec2 vUv;

          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
          }
        ''',
        'fragmentShader': '''
          uniform sampler2D baseTexture;
          uniform sampler2D bloomTexture;

          varying vec2 vUv;

          void main() {
            gl_FragColor = ( texture2D( baseTexture, vUv ) + vec4( 1.0 ) * texture2D( bloomTexture, vUv ) );
          }
        ''',
        'defines': <String,dynamic>{}
      } ), 'baseTexture'
    );
    mixPass.needsSwap = true;

    final outputPass = OutputPass();

    finalComposer = EffectComposer( threeJs.renderer!, threeJs.renderTarget );
    finalComposer.addPass( renderScene );
    finalComposer.addPass( mixPass );
    bloomComposer.addPass( outputPass );

    threeJs.postProcessor = ([double? dt]){
      render();
    };
    threeJs.domElement.addEventListener(three.PeripheralType.pointerdown, onPointerDown );

    final bloomFolder = gui.addFolder( 'bloom'.toUpperCase() );

    bloomFolder.addSlider( params, 'threshold', 0.0, 1.0 )..step(0.1)..onChange( ( value ) {
      bloomPass.threshold = value;
      threeJs.render();
    } );

    bloomFolder.addSlider( params, 'strength', 0.0, 3.0)..step(0.1)..onChange( ( value ) {
      bloomPass.strength = value;
      threeJs.render();
    } );

    bloomFolder.addSlider( params, 'radius', 0.0, 1.0 )..step( 0.01 )..onChange( ( value ) {
      bloomPass.radius =  value;
      threeJs.render();
    } );

    final toneMappingFolder = gui.addFolder( 'tone mapping'.toUpperCase() );

    toneMappingFolder.addSlider( params, 'exposure', 0.1, 2 )..step(0.1)..onChange( ( value ) {
      threeJs.renderer!.toneMappingExposure = math.pow( value, 4.0 ).toDouble();
      threeJs.render();
    } );
  }

  void onPointerDown( event ) {
    mouse.x = ( event.clientX / threeJs.width ) * 2 - 1;
    mouse.y = - ( event.clientY / threeJs.height ) * 2 + 1;

    raycaster.setFromCamera( mouse, threeJs.camera );
    final intersects = raycaster.intersectObjects( threeJs.scene.children, false );
    if ( intersects.isNotEmpty) {
      final object = intersects[ 0 ].object;
      object!.layers.toggle( BLOOM_SCENE );
      threeJs.render();
    }
  }

  void darkenNonBloomed( obj ) {
    if ( obj is three.Mesh && bloomLayer.test( obj.layers ) == false ) {
      materials[obj.uuid] = obj.material;
      obj.material = darkMaterial;
    }
  }

  void restoreMaterial(three.Object3D obj ) {
    if (materials[ obj.uuid ] != null) {
      obj.material = materials[ obj.uuid ];
      materials.remove(obj.uuid);
    }
  }

  void disposeMaterial(three.Object3D obj ) {
    obj.material?.dispose();
  }

  void render() {
    threeJs.scene.traverse( darkenNonBloomed );
    bloomComposer.render(null);
    threeJs.scene.traverse( restoreMaterial );

    // render the entire scene, then render bloom scene on top
    finalComposer.render(null);
  }
}