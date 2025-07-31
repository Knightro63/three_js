import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglMultipleScenesComparison extends StatefulWidget {
  const WebglMultipleScenesComparison({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglMultipleScenesComparison> {
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
    double w = MediaQuery.of(context).size.width/30;
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          Positioned(
            top: MediaQuery.of(context).size.height/2-w/2,
            left: sliderPos-w/2,
            child: Container(
              width: w,
              height: w,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(w/2) 
              ),
              child: GestureDetector(
                onHorizontalDragUpdate: (event){
                  setState(() {
                    sliderPos = event.globalPosition.dx;
                  });
                },
              )
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final three.Scene sceneR;
  double sliderPos = 0;

  Future<void> setup() async {
    sliderPos = threeJs.width/2;
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xBCD48F );

    sceneR = three.Scene();
    sceneR.background = three.Color.fromHex32( 0x8FBCD4 );

    threeJs.scene.add(three.AmbientLight(0xffffff,2));

    threeJs.camera = three.PerspectiveCamera( 35, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.z = 6;

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );

    initMeshes();

    threeJs.renderer?.setScissorTest(true);

    threeJs.postProcessor = ([dt]){
      threeJs.renderer!.setScissor( 0, 0, sliderPos, threeJs.height );
      threeJs.renderer!.render( threeJs.scene, threeJs.camera );
      threeJs.renderer!.setScissor( sliderPos, 0, threeJs.width,threeJs.height );
      threeJs.renderer!.render( sceneR, threeJs.camera );
    };
  }

  void initMeshes() {
    final geometry = IcosahedronGeometry( 1, 3 );
    final meshL = three.Mesh( geometry, three.MeshStandardMaterial.fromMap({'color': 0xffffff}) );
    threeJs.scene.add( meshL );
    final meshR = three.Mesh( geometry, three.MeshStandardMaterial.fromMap( { 'wireframe': true } ) );
    sceneR.add( meshR );
  }
}
