import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglVideoTexture extends StatefulWidget {
  const WebglVideoTexture({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglVideoTexture> {
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x202020 );

    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 0, 2.5 );
    threeJs.camera.lookAt( threeJs.scene.position );
    threeJs.scene.add( threeJs.camera );

    controls = three.OrbitControls( threeJs.camera,threeJs.globalKey );
    final texture = three.VideoTexture();
    // PlaneGeometry UVs assume flipY=true, which compressed textures don't support.
    final geometry = three.PlaneGeometry();
    final material = three.MeshBasicMaterial.fromMap( {
      'map': texture,
      'side': three.DoubleSide,
    } );
    final mesh = three.Mesh( geometry, material );
    if(!kIsWeb){
      mesh.rotation.z = math.pi;
      mesh.rotation.y = math.pi;
    }
    threeJs.scene.add( mesh );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
