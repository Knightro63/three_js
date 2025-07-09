import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/three_js_xr.dart';

class WebXRARCones extends StatefulWidget {
  const WebXRARCones({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRARCones> {
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
          if(threeJs.mounted) ARButton(threeJs: threeJs)
        ],
      ) 
    );
  }

  WebXRController? controller; 

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 0.01, 20 );
    threeJs.camera.layers.enable( 1 );

    final light = three.HemisphereLight( 0xffffff, 0xbbbbff, 3 );
    light.position.setValues( 0.5, 1, 0.25 );
    threeJs.scene.add( light );


    final geometry = three.CylinderGeometry( 0, 0.05, 0.2, 32 ).rotateX( math.pi / 2 );

    void onSelect() {
      final material = three.MeshPhongMaterial.fromMap( { 'color': (0xffffff * math.Random().nextDouble()).toInt() } );
      final mesh = three.Mesh( geometry, material );
      mesh.position.setValues( 0, 0, - 0.3 ).applyMatrix4( controller!.matrixWorld );
      mesh.quaternion.setFromRotationMatrix( controller!.matrixWorld );
      threeJs.scene.add( mesh );
    }

    controller = (threeJs.renderer!.xr as WebXRWorker).getController( 0 );
    controller?.addEventListener( 'select', onSelect );
    threeJs.scene.add( controller );
  }
}
