import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglPostprocessingUnrealBloom extends StatefulWidget {
  const WebglPostprocessingUnrealBloom({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglPostprocessingUnrealBloom> {
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
      setup: setup,      settings: three.Settings(
       //autoClear: false,
        toneMapping: three.ReinhardToneMapping,
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
    composer.dispose();
    renderScene.dispose();
    bloomPass.dispose();
    outputPass.dispose();
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

  late final EffectComposer composer;
  late final RenderPass renderScene;
  late final UnrealBloomPass bloomPass;
  final outputPass = OutputPass();

  late final three.OrbitControls controls;
  late final three.AnimationMixer mixer;

  final Map<String,double> params = {
    'threshold': 0.0,
    'strength': 1.0,
    'radius': 0.0,
    'exposure': 1.0
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 100 );
    threeJs.camera.position.setValues( - 5, 2.5, - 3.5 );
    threeJs.scene.add( threeJs.camera );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.maxPolarAngle = math.pi * 0.5;
    controls.minDistance = 3;
    controls.maxDistance = 8;

    threeJs.scene.add( three.AmbientLight( 0xcccccc ) );

    final pointLight = three.PointLight( 0xffffff, 1.0 );
    threeJs.camera.add( pointLight );

    renderScene = RenderPass( threeJs.scene, threeJs.camera );

    bloomPass = UnrealBloomPass( three.Vector2( threeJs.width, threeJs.height ), 1.5, 0.4, 0.85 );
    bloomPass.threshold = params['threshold']!;
    bloomPass.strength = params['strength']!;
    bloomPass.radius = params['radius']!;

    composer = EffectComposer( threeJs.renderer!,threeJs.renderTarget);
    composer.addPass( renderScene );
    composer.addPass( bloomPass );
    composer.addPass( outputPass );

    final gltf = await three.GLTFLoader().fromAsset( 'assets/models/gltf/PrimaryIonDrive.glb');
    final model = gltf!.scene;

    threeJs.scene.add( model );

    mixer = three.AnimationMixer( model );
    final clip = gltf.animations![ 0 ];
    mixer.clipAction( clip.optimize() )!.play();

    threeJs.postProcessor = ([double? dt]){
      threeJs.renderer!.setRenderTarget(null);
      composer.render(dt);
      threeJs.renderer!.render(threeJs.scene, threeJs.camera);
    };
    threeJs.addAnimationEvent((dt){
      animate(dt);
    });

    final bloomFolder = gui.addFolder( 'BLOOM' );

    bloomFolder.addSlider( params, 'threshold', 0.0, 1.0 )..step(0.1)..onChange(( value ) {
      bloomPass.threshold = value;
    });

    bloomFolder.addSlider( params, 'strength', 0.0, 3.5 )..step(0.1)..onChange(( value ) {
      bloomPass.strength =  value;
    });

    bloomFolder.addSlider( params, 'radius', 0.0, 1.0 )..step( 0.01 )..onChange(( value ) {
      bloomPass.radius = value;
    });

    final toneMappingFolder = gui.addFolder( 'tone mapping'.toUpperCase() );

    toneMappingFolder.addSlider( params, 'exposure', 0.1, 2.0 )..step(0.1)..onChange(( value ) {
      threeJs.renderer!.toneMappingExposure = math.pow( value, 4.0 ).toDouble();
    });
  }

  void animate(double delta) {
    mixer.update( delta );
  }
}
