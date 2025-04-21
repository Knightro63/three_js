import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:example/src/statistics.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglPostprocessingSobel extends StatefulWidget {
  const WebglPostprocessingSobel({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglPostprocessingSobel> {
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
        useSourceTexture: true,
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
    composer.reset(threeJs.renderTarget);
    composer.dispose();
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
  late EffectComposer composer;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 1, 3 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //

    final geometry = TorusKnotGeometry( 1, 0.3, 256, 32 );
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0xffff00 } );

    final mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    final ambientLight = three.AmbientLight( 0xe7e7e7 );
    threeJs.scene.add( ambientLight );

    final pointLight = three.PointLight( 0xffffff, 2 );
    threeJs.camera.add( pointLight );
    threeJs.scene.add( threeJs.camera );

    // postprocessing

    composer = EffectComposer( threeJs.renderer!, threeJs.renderTarget );
    final renderPass = RenderPass( threeJs.scene, threeJs.camera );
    composer.addPass( renderPass );

    // Sobel operator
    final effectSobel = ShaderPass.fromJson( sobelOperatorShader );
    effectSobel.uniforms[ 'resolution' ]['value'].x = threeJs.width * threeJs.dpr;
    effectSobel.uniforms[ 'resolution' ]['value'].y = threeJs.height * threeJs.dpr;
    composer.addPass( effectSobel );

    // final effectGrayScale = ShaderPass.fromJson( luminosityShader );
    // composer.addPass( effectGrayScale );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enableZoom = false;

    threeJs.postProcessor = ([double? dt]){
      composer.render(dt);
    };

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
