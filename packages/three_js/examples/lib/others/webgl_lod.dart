import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglLod extends StatefulWidget {
  final String fileName;
  const WebglLod({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglLod> {
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
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.FlyControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 15000 );
    threeJs.camera.position.z = 1000;

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.Fog( 0x000000, 1, 15000 );

    final pointLight = three.PointLight( 0xff2200, 0.9, 0, 0 );
    pointLight.position.setValues( 0, 0, 0 );
    threeJs.scene.add( pointLight );

    final dirLight = three.DirectionalLight( 0xffffff, 0.9 );
    dirLight.position.setValues( 0, 0, 1 ).normalize();
    threeJs.scene.add( dirLight );

    final List geometry = [
      [ IcosahedronGeometry( 100, 16 ), 50.0 ],
      [ IcosahedronGeometry( 100, 8 ), 300.0 ],
      [ IcosahedronGeometry( 100, 4 ), 1000.0 ],
      [ IcosahedronGeometry( 100, 2 ), 2000.0 ],
      [ IcosahedronGeometry( 100, 1 ), 8000.0 ]
    ];

    final material = three.MeshLambertMaterial.fromMap( { 'color': 0xffffff, 'wireframe': true } );

    for ( int j = 0; j < 1000; j ++ ) {
      final lod = three.LOD();

      for (int i = 0; i < geometry.length; i ++ ) {
        final mesh = three.Mesh( geometry[ i ][ 0 ], material );
        mesh.scale.setValues( 1.5, 1.5, 1.5 );
        mesh.updateMatrix();
        mesh.matrixAutoUpdate = false;
        lod.addLevel( mesh, geometry[ i ][ 1 ] );
      }

      lod.position.x = 10000 * ( 0.5 - math.Random().nextDouble() );
      lod.position.y = 7500 * ( 0.5 - math.Random().nextDouble() );
      lod.position.z = 10000 * ( 0.5 - math.Random().nextDouble() );
      lod.updateMatrix();
      lod.matrixAutoUpdate = false;
      threeJs.scene.add( lod );

    }

    controls = three.FlyControls( threeJs.camera, threeJs.globalKey );
    controls.movementSpeed = 1000;
    controls.rollSpeed = math.pi / 10;

    threeJs.addAnimationEvent((dt){
      controls.update( dt );
    });
  }
}
