import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_video_texture/three_js_video_texture.dart';
import 'package:three_js_xr/other/constants.dart';
import 'package:three_js_xr/three_js_xr.dart';

class WebXRVRVideo extends StatefulWidget {
  const WebXRVRVideo({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRVideo> {
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

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    (threeJs.renderer?.xr as WebXRWorker).setUpOptions(XROptions(
      width: threeJs.width,
      height: threeJs.height,
      dpr: threeJs.dpr,
    ));
    final texture = VideoTextureWorker.fromOptions(
      three.VideoTextureOptions(
        asset: 'assets/textures/MaryOculus.mp4',
      )
    );
    texture.colorSpace = three.SRGBColorSpace;
    texture.play();

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.layers.enable( 1 ); // render left view when no stereo available    

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color( 0x101010 );

    // left
    final geometry1 = three.SphereGeometry( 500, 60, 40 );
    // invert the geometry on the x-axis so that all of the faces point inward
    geometry1.scale( - 1, 1, 1 );

    final uvs1 = geometry1.attributes['uv'].array;

    for ( int i = 0; i < uvs1.length; i += 2 ) {
      uvs1[ i ] *= 0.5;
    }

    final material1 = three.MeshBasicMaterial.fromMap( { 'map': texture } );

    final mesh1 = three.Mesh( geometry1, material1 );
    mesh1.rotation.y = - math.pi / 2;
    mesh1.layers.set( 1 ); // display in left eye only
    threeJs.scene.add( mesh1 );

    // right

    final geometry2 = three.SphereGeometry( 500, 60, 40 );
    geometry2.scale( - 1, 1, 1 );

    final uvs2 = geometry2.attributes['uv'].array;

    for (int i = 0; i < uvs2.length; i += 2 ) {
      uvs2[ i ] *= 0.5;
      uvs2[ i ] += 0.5;
    }

    final material2 = three.MeshBasicMaterial.fromMap( { 'map': texture } );

    final mesh2 = three.Mesh( geometry2, material2 );
    mesh2.rotation.y = - math.pi / 2;
    mesh2.layers.set( 2 ); // display in right eye only
    threeJs.scene.add( mesh2 );
    threeJs.customRenderer = (threeJs.renderer?.xr as WebXRWorker).render;
  }
}
