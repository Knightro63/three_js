import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:example/src/statistics.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLightsRectarealight extends StatefulWidget {
  
  const WebglLightsRectarealight({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLightsRectarealight> {
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
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 5, - 15 );

    threeJs.scene = three.Scene();

    //RectAreaLightUniformsLib.init();

    final rectLight1 = three.RectAreaLight( 0xff0000, 5, 4, 10 );
    rectLight1.position.setValues( - 5, 5, 5 );
    threeJs.scene.add( rectLight1 );

    final rectLight2 = three.RectAreaLight( 0x00ff00, 5, 4, 10 );
    rectLight2.position.setValues( 0, 5, 5 );
    threeJs.scene.add( rectLight2 );

    final rectLight3 = three.RectAreaLight( 0x0000ff, 5, 4, 10 );
    rectLight3.position.setValues( 5, 5, 5 );
    threeJs.scene.add( rectLight3 );

    threeJs.scene.add( RectAreaLightHelper( rectLight1 ) );
    threeJs.scene.add( RectAreaLightHelper( rectLight2 ) );
    threeJs.scene.add( RectAreaLightHelper( rectLight3 ) );

    final geoFloor = three.BoxGeometry( 2000, 0.1, 2000 );
    final matStdFloor = three.MeshStandardMaterial.fromMap( { 'color': 0xbcbcbc, 'roughness': 0.1, 'metalness': 0 } );
    final mshStdFloor = three.Mesh( geoFloor, matStdFloor );
    threeJs.scene.add( mshStdFloor );

    final geoKnot = TorusKnotGeometry( 1.5, 0.5, 200, 16 );
    final matKnot = three.MeshStandardMaterial.fromMap( { 'color': 0xffffff, 'roughness': 0, 'metalness': 0 } );
    final meshKnot = three.Mesh( geoKnot, matKnot );
    meshKnot.position.setValues( 0, 5, 0 );
    threeJs.scene.add( meshKnot );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setFrom( meshKnot.position );
    controls.update();

    threeJs.addAnimationEvent((dt) {
        controls.update();
        meshKnot.rotation.y = dt / 1000;
    });
  }
}
