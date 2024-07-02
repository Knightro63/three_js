import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderXyz extends StatefulWidget {
  
  const WebglLoaderXyz({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderXyz> {
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
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 10, 7, 10 );

    threeJs.scene = three.Scene();
    threeJs.scene.add( threeJs.camera );
    threeJs.camera.lookAt( threeJs.scene.position );


    final geometry = await three.XYZLoader().fromAsset( 'assets/models/xyz/helix_201.xyz');
    geometry?.center();

    final vertexColors = ( geometry?.hasAttributeFromString( 'color' ) == true );
    final material = three.PointsMaterial.fromMap( { 'size': 0.1, 'vertexColors': vertexColors } );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    final points = three.Points( geometry!, material );
    threeJs.scene.add( points );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
