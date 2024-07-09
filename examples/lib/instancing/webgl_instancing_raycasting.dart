import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglInstancingRaycast extends StatefulWidget {
  
  const WebglInstancingRaycast({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglInstancingRaycast> {
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
    controls.dispose();
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

  static double amount = 10;
  final count = math.pow( amount, 3 ).toInt();
  late three.InstancedMesh mesh;
  late three.OrbitControls controls;

  final raycaster = three.Raycaster();
  final mouse = three.Vector2( 1, 1 );

  final color = three.Color.fromHex32( 0xffffff );
  final white = three.Color.fromHex32( 0xffffff );

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( amount, amount, amount );
    threeJs.camera.lookAt( three.Vector3(0, 0, 0) );

    threeJs.scene = three.Scene();

    final light = three.HemisphereLight( 0xffffff, 0x888888, 1 );
    light.position.setValues( 0, 1, 0 );
    threeJs.scene.add( light );

    final geometry = IcosahedronGeometry( 0.5, 3 );
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } );
    mesh = three.InstancedMesh( geometry, material, count );

    int i = 0;
    final offset = ( amount - 1 ) / 2;
    final matrix = three.Matrix4.identity();

    for ( int x = 0; x < amount; x ++ ) {
      for ( int y = 0; y < amount; y ++ ) {
        for ( int z = 0; z < amount; z ++ ) {
          matrix.setPosition( offset - x, offset - y, offset - z );
          mesh.setMatrixAt( i, matrix );
          mesh.setColorAt( i, color );
          i++;
        }
      }
    }

    threeJs.scene.add( mesh );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enableDamping = true;
    controls.enableZoom = false;
    controls.enablePan = false;

    threeJs.domElement.addEventListener(three.PeripheralType.pointerHover, onMouseMove );
    threeJs.addAnimationEvent((dt){
      animate();
      controls.update();
    });
  }

  void onMouseMove( event ) {
    event.preventDefault();
    mouse.x = ( event.clientX / threeJs.width ) * 2 - 1;
    mouse.y = - ( event.clientY / threeJs.height ) * 2 + 1;
  }

  void animate() {
    controls.update();
    raycaster.setFromCamera( mouse, threeJs.camera );

    final intersection = raycaster.intersectObject(mesh,false);

    if(intersection.isNotEmpty) {
      final instanceId = intersection[0].instanceId;
      mesh.getColorAt( instanceId!, color );

      if(color.equals( white )){
        mesh.setColorAt( instanceId, color..setFromHex32( (math.Random().nextDouble() * 0xffffff).toInt() ) );
        mesh.instanceColor?.needsUpdate = true;
      }
    }
  }
}
