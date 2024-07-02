import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:example/src/statistics.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderFbxNurbs extends StatefulWidget {
  
  const WebglLoaderFbxNurbs({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderFbxNurbs> {
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
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 2000 );
    threeJs.camera.position.setValues( 2, 18, 28 );

    threeJs.scene = three.Scene();

    // grid
    final gridHelper = GridHelper( 28, 28, 0x303030, 0x303030 );
    threeJs.scene.add( gridHelper );

    // model
    final loader = three.FBXLoader(width: threeJs.width.toInt(), height: threeJs.height.toInt());
    await loader.fromAsset( 'assets/models/fbx/nurbs.fbx').then(( object ) {
      threeJs.scene.add( object );
    } );

    controls =  three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setValues( 0, 12, 0 );
    controls.update();

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
