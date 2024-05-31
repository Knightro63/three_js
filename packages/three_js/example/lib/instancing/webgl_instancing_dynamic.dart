import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_tjs_loader/buffer_geometry_loader.dart';

class WebglInstancingDynamic extends StatefulWidget {
  final String fileName;
  const WebglInstancingDynamic({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglInstancingDynamic> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      )
    );
    super.initState();
  }
  @override
  void dispose() {
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

  static double amount = 10;
  final count = math.pow( amount, 3 ).toInt();
  late three.InstancedMesh mesh;
  final dummy = three.Object3D();

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( amount * 0.9, amount * 0.9, amount * 0.9 );
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));
    //threeJs.camera.position.z = 30;

    threeJs.scene = three.Scene();

    final loader = BufferGeometryLoader();
    await loader.fromAsset( 'assets/models/json/suzanne_buffergeometry.json').then(( geometry ) {
      geometry?.computeVertexNormals();
      geometry?.scale( 0.5, 0.5, 0.5 );

      final material = three.MeshNormalMaterial();
      // check overdraw
      // let material = three.MeshBasicMaterial( { color: 0xff0000, opacity: 0.1, transparent: true } );

      mesh = three.InstancedMesh( geometry, material, count );
      mesh.instanceMatrix?.setUsage(three.DynamicDrawUsage ); // will be updated every frame
      threeJs.scene.add( mesh );

      threeJs.addAnimationEvent((dt){
        render();
      });
    });
  }
  void render() {
    final time = DateTime.now().millisecondsSinceEpoch * 0.001;

    mesh.rotation.x = math.sin( time / 4 );
    mesh.rotation.y = math.sin( time / 2 );

    int i = 0;
    final offset = ( amount - 1 ) / 2;

    for (int x = 0; x < amount; x ++ ) {
      for ( int y = 0; y < amount; y ++ ) {
        for ( int z = 0; z < amount; z ++ ) {
          dummy.position.setValues( offset - x, offset - y, offset - z );
          dummy.rotation.y = ( math.sin( x / 4 + time ) + math.sin( y / 4 + time ) + math.sin( z / 4 + time ) );
          dummy.rotation.z = dummy.rotation.y * 2;

          dummy.updateMatrix();

          mesh.setMatrixAt(i++, dummy.matrix );
        }
      }
    }

    mesh.instanceMatrix?.needsUpdate = true;
    mesh.computeBoundingSphere();
  }
}
