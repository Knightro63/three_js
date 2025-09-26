import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/other/constants.dart';
import 'package:three_js_xr/three_js_xr.dart';
import '../src/atlas/index.dart';

class WebXRVRPanorama extends StatefulWidget {
  const WebXRVRPanorama({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRPanorama> {
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
      onSetupComplete: () async{setState(() {});},
      setup: setup,
      settings: three.Settings(
        xr: xrSetup
      )
    );
    super.initState();
  }
  @override
  void dispose() {
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
          if(threeJs.mounted) VRButton(threeJs: threeJs)
        ],
      ) 
    );
  }

  late three.Mesh mesh; 
  late three.Material material;
  late three.BufferGeometry geometry;
  
  final position = three.Vector3();
  final tangent = three.Vector3();
  final lookAt = three.Vector3();

  double velocity = 0;
  double progress = 0;
  int prevTime = DateTime.now().millisecond;

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  Future<void> setup() async {
    final Atlas atlas = Atlas();
    threeJs.renderer?.xr.enabled = true;
    (threeJs.renderer?.xr as WebXRWorker).setUpOptions(XROptions(
      width: threeJs.width,
      height: threeJs.height,
      dpr: threeJs.dpr,
    ));
    (threeJs.renderer?.xr as WebXRWorker).setReferenceSpaceType( 'local' );

    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.layers.enable( 1 );

    final geometry = three.BoxGeometry( 100, 100, 100 );
    geometry.scale( 1, 1, - 1 );

    final textures = atlas.getTexturesFromAtlasFile( 'assets/textures/sun_temple_stripe_stereo.jpg', 12 );
    final materials = three.GroupMaterial();

    for (int i = 0; i < 6; i ++ ) {
      materials.add(three.MeshBasicMaterial.fromMap( { 'map': textures[ i ] } ) );
    }

    final skyBox = three.Mesh( geometry, materials );
    skyBox.layers.set( 1 );
    threeJs.scene.add( skyBox );

    final materialsR = three.GroupMaterial();

    for (int i = 6; i < 12; i ++ ) {
      materialsR.add( three.MeshBasicMaterial.fromMap( { 'map': textures[ i ] } ) );
    }

    final skyBoxR = three.Mesh( geometry, materialsR );
    skyBoxR.layers.set( 2 );
    threeJs.scene.add( skyBoxR );

    threeJs.customRenderer = (threeJs.renderer?.xr as WebXRWorker).render;
  }
}
