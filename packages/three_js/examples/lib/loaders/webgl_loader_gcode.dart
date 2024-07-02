import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderGcode extends StatefulWidget {
  
  const WebglLoaderGcode({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderGcode> {
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 0, 70 );

    threeJs.scene = three.Scene();

    final loader = three.GCodeLoader();
    final object = await loader.fromAsset( 'assets/models/gcode/benchy.gcode');
    object?.position.setValues( - 100, - 20, 100 );

    threeJs.scene.add( object );
    threeJs.render();

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    // controls.addEventListener( 'change', render ); // use if there is no animation loop
    controls.minDistance = 10;
    controls.maxDistance = 100;

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
