import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglGeometryDynamic extends StatefulWidget {
  final String fileName;
  const WebglGeometryDynamic({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglGeometryDynamic> {
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

  late three.FirstPersonControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 1, 20000 );
    threeJs.camera.position.y = 500;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xaaccff );
    threeJs.scene.fog = three.FogExp2( 0xaaccff, 0.0007 );

    final geometry = three.PlaneGeometry( 20000, 20000, 128 - 1, 128 - 1 );
    geometry.rotateX( - math.pi / 2 );

    final position = geometry.attributes['position'] as three.Float32BufferAttribute;
    position.usage = three.DynamicDrawUsage;

    for ( int i = 0; i < position.count; i ++ ) {
      num y = 35 * math.sin( i / 2 );
      position.setY( i , y );
    }

    final texture = (await three.TextureLoader().fromAsset( 'assets/textures/water.jpg' ))!;
    texture.wrapS = texture.wrapT = three.RepeatWrapping;
    texture.repeat.setValues( 5, 5 );
    //texture.colorSpace = THREE.SRGBColorSpace;

    final material = three.MeshBasicMaterial.fromMap( { 'color': 0x0044ff, 'map': texture } );

    final mesh = three.Mesh( geometry, material );
    mesh.frustumCulled = false;
    threeJs.scene.add( mesh );

    controls = three.FirstPersonControls(camera:threeJs.camera, listenableKey:  threeJs.globalKey );

    controls.movementSpeed = 50;
    controls.lookSpeed = 0.01;

    threeJs.addAnimationEvent((dt){
      final time = threeJs.clock.getElapsedTime() * 10;

      final position = geometry.attributes['position'];

      for (int i = 0; i < position.count; i ++ ) {
        final y = 35 * math.sin( i / 5 + ( time + i ) / 7 );
        position.setY( i, y );
      }

      position.needsUpdate = true;
      controls.update( dt );
    });
  }
}
