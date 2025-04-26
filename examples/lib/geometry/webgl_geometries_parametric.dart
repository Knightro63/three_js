import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglGeometriesParametric extends StatefulWidget {
  const WebglGeometriesParametric({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometriesParametric> {
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

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.y = 400;
    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight( 0xcccccc, 1.5 );
    threeJs.scene.add( ambientLight );

    final pointLight = three.PointLight( 0xffffff, 2.5, 0, 0 );
    threeJs.camera.add( pointLight );
    threeJs.scene.add( threeJs.camera );

    final map = await three.TextureLoader().fromAsset( 'assets/textures/uv_grid_opengl.jpg' );
    map?.wrapS = map.wrapT = three.RepeatWrapping;
    map?.anisotropy = 16;
    map?.colorSpace = three.SRGBColorSpace;

    final material = three.MeshPhongMaterial.fromMap( { 'map': map, 'side': three.DoubleSide } );

    //

    three.ParametricGeometry geometry;
    three.Mesh object;

    geometry = three.ParametricGeometry( three.ParametricGeometries.plane( 100, 100 ), 10, 10 );
    geometry.center();
    object = three.Mesh( geometry, material );
    object.position.setValues( - 200, 0, 200 );
    threeJs.scene.add( object );

    geometry = three.ParametricGeometry( three.ParametricGeometries.klein, 20, 20 );
    object = three.Mesh( geometry, material );
    object.position.setValues( 0, 0, 200 );
    object.scale.scale( 5 );
    threeJs.scene.add( object );

    geometry = three.ParametricGeometry( three.ParametricGeometries.mobius, 20, 20 );
    object = three.Mesh( geometry, material );
    object.position.setValues( 200, 0, 200 );
    object.scale.scale( 30 );
    threeJs.scene.add( object );

    final torus = three.ParametricTorusKnotGeometry( 50, 10, 50, 20, 2, 3 );
    final sphere = three.ParametricSphereGeometry( 50, 20, 10 );
    final tube =  three.ParametricTubeGeometry( three.GrannyKnot(), 100, 3, 8, true );

    object = three.Mesh( torus, material );
    object.position.setValues( - 200, 0, - 200 );
    threeJs.scene.add( object );

    object = three.Mesh( sphere, material );
    object.position.setValues( 0, 0, - 200 );
    threeJs.scene.add( object );

    object = three.Mesh( tube, material );
    object.position.setValues( 200, 0, - 200 );
    object.scale.scale( 2 );
    threeJs.scene.add( object );

    threeJs.addAnimationEvent((dt){
      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;
      threeJs.camera.position.x = math.cos( timer ) * 800;
      threeJs.camera.position.z = math.sin( timer ) * 800;

      threeJs.camera.lookAt( threeJs.scene.position );

      threeJs.scene.traverse(( object ) {
        if ( object is three.Mesh) {
          object.rotation.x = timer * 5;
          object.rotation.y = timer * 2.5;
        }
      } );
    });
  }
}
