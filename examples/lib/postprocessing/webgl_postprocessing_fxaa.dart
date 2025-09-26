import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglPostprocessingFXAA extends StatefulWidget {
  const WebglPostprocessingFXAA({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglPostprocessingFXAA> {
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
      setup: setup,      
      settings: three.Settings(
       //autoClear: false,
        toneMapping: three.ReinhardToneMapping,
        //useSourceTexture: true,
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    composer1.dispose();
    composer2.dispose();
    fxaaPass.dispose();
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
        ],
      ) 
    );
  }

  late final EffectComposer composer1;
  late final EffectComposer composer2;
  final FXAAPass fxaaPass = FXAAPass();
  final outputPass = OutputPass();
  late final three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.z = 500;

    threeJs.scene = three.Scene();

    final hemiLight = three.HemisphereLight( 0xffffff, 0x8d8d8d );
    hemiLight.position.setValues( 0, 1000, 0 );
    threeJs.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff, 3 );
    dirLight.position.setValues( - 3000, 1000, - 1000 );
    threeJs.scene.add( dirLight );

    final geometry = three.TetrahedronGeometry( 10 );
    final material = three.MeshStandardMaterial.fromMap( { 'color': 0xf73232, 'flatShading': true } );

    for (int i = 0; i < 100; i ++ ) {
      final mesh = three.Mesh( geometry, material );

      mesh.position.x = math.Random().nextDouble() * 500 - 250;
      mesh.position.y = math.Random().nextDouble() * 500 - 250;
      mesh.position.z = math.Random().nextDouble() * 500 - 250;

      mesh.scale.setScalar( math.Random().nextDouble() * 2 + 1 );

      mesh.rotation.x = math.Random().nextDouble() * math.pi;
      mesh.rotation.y = math.Random().nextDouble() * math.pi;
      mesh.rotation.z = math.Random().nextDouble() * math.pi;

      threeJs.scene.add( mesh );
    }

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey );
    controls.autoRotate = true;

    final renderPass = RenderPass( threeJs.scene, threeJs.camera );
    renderPass.clearAlpha = 0;

    composer1 = EffectComposer( threeJs.renderer!,null, threeJs.texture! );
    composer1.addPass( renderPass );
    //composer1.addPass( outputPass );

    composer2 = EffectComposer( threeJs.renderer!,null, threeJs.texture! );
    composer2.addPass( renderPass );
    //composer2.addPass( outputPass );

    // FXAA is engineered to be applied towards the end of engine post processing after conversion to low dynamic range and conversion to the sRGB color space for display.

    composer2.addPass( fxaaPass );

    threeJs.customRenderer = renderer;
  }

  Future<void> renderer(three.Scene scene, three.Camera camera, three.FlutterAngleTexture texture,[dt]) async{
    final halfWidth = threeJs.width / 2;

    controls.update();
    final currentAutoClear = threeJs.renderer!.autoClear;
    threeJs.renderer!.autoClear = false;
    threeJs.renderer?.setScissorTest( true );

    threeJs.renderer?.setScissor( 0, 0, halfWidth-1, threeJs.height );
    composer1.render();

    threeJs.renderer?.setScissor( halfWidth, 0, halfWidth, threeJs.height );
    composer2.render();

    threeJs.renderer?.setScissorTest( false );
    threeJs.renderer!.autoClear = currentAutoClear;
    await texture.signalNewFrameAvailable();
  }
}
