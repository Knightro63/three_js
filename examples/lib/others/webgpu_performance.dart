import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebgpuPerformance extends StatefulWidget {
  const WebgpuPerformance({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebgpuPerformance> {
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
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 1
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
        ],
      ) 
    );
  }

  late final three.Object3D model;
  final options = { 'static': true };
  late final three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 60, 60, 60 );
    threeJs.scene = three.Scene();

    threeJs.scene.add(three.AmbientLight(0xffffff,4));

    await three.RGBELoader().setPath( 'assets/textures/equirectangular/' ).fromAsset( 'royal_esplanade_1k.hdr').then(( texture ) {
      texture.mapping = three.EquirectangularReflectionMapping;
      threeJs.scene.environment = texture;
    });

    final loader = three.GLTFLoader().setPath( 'assets/models/gltf/Dungon_Warkarma/' );
    await loader.fromAsset( 'dungon_warkarma.gltf').then(( gltf ) {
      model = gltf!.scene;
      threeJs.scene.add( model );
    } );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 2;
    controls.maxDistance = 60;
    controls.target.setValues( 0, 0, - 0.2 );
    controls.update();
  }
}
