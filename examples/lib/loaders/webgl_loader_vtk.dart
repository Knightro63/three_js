import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';

class WebglLoaderVtk extends StatefulWidget {
  
  const WebglLoaderVtk({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderVtk> {
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
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width/threeJs.height, 0.1, 20 );
    threeJs.camera.position.setValues( 3, 0.15, 3 );

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x72645b );

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    final loader = VTKLoader();
    await loader.fromAsset( 'assets/models/vtk/liver.vtk').then( ( geometry ) {
      final material = three.MeshPhongMaterial.fromMap( { 'color': 0xff9c7c} );
      final mesh = three.Mesh(geometry,material);

      mesh.material = material;
      mesh.position.setValues( 0, - 0.25, 0.6 );
      mesh.rotation.set( 0, math.pi / 2, 0 );
      mesh.scale.setValues( 0.01, 0.01, 0.01 );

      threeJs.scene.add( mesh );
    });

    await loader.fromAsset( 'assets/models/vtk/bunny.vtk').then( ( geometry ) {
      final material = three.MeshPhongMaterial.fromMap( { 'color': 0xd5d5d5} );
      final mesh = three.Mesh(geometry,material);
      geometry?.computeVertexNormals();
      geometry?.center();

      mesh.material = material;
      mesh.position.setValues( 0, - 0.37, - 0.6 );
      // mesh.rotation.set( - math.pi / 2, 0, 0 );
      mesh.scale.setValues( 5, 5, 5 );

      threeJs.scene.add( mesh );
    });

    await loader.fromAsset( 'assets/models/vtk/cube_no_compression.vtp').then( ( geometry ) {
      final material = three.MeshPhongMaterial.fromMap( { 'color': 0xcbcbcb} );
      final mesh = three.Mesh(geometry,material);

      mesh.material = material;
      mesh.position.setValues( 0.5, - 0.37, - 0.6 );
      mesh.rotation.set( - math.pi / 2, 0.3, 0 );
      mesh.scale.setValues( 0.1, 0.1, 0.1 );

      threeJs.scene.add( mesh );
    });

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
