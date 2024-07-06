import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_modifers/simplify_modifer.dart';

class WebglModifierSimplifier extends StatefulWidget {
  
  const WebglModifierSimplifier({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglModifierSimplifier> {
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
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    controls.dispose();
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.z = 15;

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enablePan = false;
    controls.enableZoom = false;

    threeJs.scene.add( three.AmbientLight( 0xffffff, 0.5 ) );

    final light = three.PointLight( 0xffffff, 0.4 );
    threeJs.camera.add( light );
    threeJs.scene.add( threeJs.camera );

    await three.GLTFLoader().fromAsset( 'assets/models/gltf/LeePerrySmith/LeePerrySmith.glb').then(( gltf ) {
      final mesh = gltf!.scene.children[ 0 ];
      mesh.position.x = - 3;
      mesh.rotation.y = math.pi / 2;
      threeJs.scene.add( mesh );

      final modifier = SimplifyModifier();

      final simplified = mesh.clone();
      simplified.material = simplified.material?.clone();
      simplified.material?.flatShading = true;
      final count = 12;//( simplified.geometry?.attributes['position'].count * 0.25 ).floor();
      simplified.geometry = modifier.modify( simplified.geometry!, count );

      simplified.position.x = 3;
      simplified.rotation.y = - math.pi / 2;
      threeJs.scene.add( simplified );
    } );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
