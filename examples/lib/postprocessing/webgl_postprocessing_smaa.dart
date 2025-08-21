import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglPostprocessingSMAA extends StatefulWidget {
  const WebglPostprocessingSMAA({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglPostprocessingSMAA> {
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
    smaaPass.dispose();
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

  late final EffectComposer composer;
  late final SMAAPass smaaPass;
  final outputPass = OutputPass();
  late final three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.z = 300;

    threeJs.scene = three.Scene();

    final geometry = three.BoxGeometry( 120, 120, 120 );
    final material1 = three.MeshBasicMaterial.fromMap( { 'color': 0xffffff, 'wireframe': true } );

    final mesh1 = three.Mesh( geometry, material1 );
    mesh1.position.x = - 100;
    threeJs.scene.add( mesh1 );

    final texture = await three.TextureLoader().fromAsset( 'assets/textures/uv_grid_opengl.jpg' );
    texture?.anisotropy = threeJs.renderer!.capabilities.getMaxAnisotropy().toInt();
    texture?.colorSpace = three.SRGBColorSpace;

    final material2 = three.MeshBasicMaterial.fromMap( { 'map': texture } );

    final mesh2 = three.Mesh( geometry, material2 );
    mesh2.position.x = 100;
    threeJs.scene.add( mesh2 );

    // postprocessing

    composer = EffectComposer( threeJs.renderer!, threeJs.renderTarget );
    composer.addPass( RenderPass( threeJs.scene, threeJs.camera ) );

    smaaPass = SMAAPass();
    
    composer.addPass( smaaPass );

    final outputPass = OutputPass();
    composer.addPass( outputPass );


    threeJs.postProcessor = ([dt]){
      for (int i = 0; i < threeJs.scene.children.length; i ++ ) {
        final child = threeJs.scene.children[ i ];
        child.rotation.x += 0.005;
        child.rotation.y += 0.01;
      }

      threeJs.renderer!.setRenderTarget(null);
      composer.render(dt);
      threeJs.renderer!.render(threeJs.scene, threeJs.camera);
    };
  }
}
