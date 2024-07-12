import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';
import 'package:three_js_controls/three_js_controls.dart';
import 'package:three_js_modifers/three_js_modifers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglModifierSimplifier(),
    );
  }
}

class WebglModifierSimplifier extends StatefulWidget {
  const WebglModifierSimplifier({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglModifierSimplifier> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    threeJs.dispose();
    //loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  late OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.z = 15;

    controls = OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enablePan = false;
    controls.enableZoom = false;

    threeJs.scene.add( three.AmbientLight( 0xffffff, 0.5 ) );

    final light = three.PointLight( 0xffffff, 0.4 );
    threeJs.camera.add( light );
    threeJs.scene.add( threeJs.camera );

    await GLTFLoader().fromAsset( 'assets/LeePerrySmith/LeePerrySmith.glb').then(( gltf ) {
      final mesh = gltf!.scene.children[ 0 ];
      mesh.position.x = - 3;
      mesh.rotation.y = math.pi / 2;
      threeJs.scene.add( mesh );

      final simplified = mesh.clone();
      simplified.material = simplified.material?.clone();
      simplified.material?.flatShading = true;
      final count = ( simplified.geometry?.attributes['position'].count * 0.25 ).floor();
      simplified.geometry = SimplifyModifier.modify( simplified.geometry!, count );

      simplified.position.x = 3;
      simplified.rotation.y = - math.pi / 2;
      threeJs.scene.add( simplified );
    } );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
