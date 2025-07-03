import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglInteractiveLines extends StatefulWidget {
  const WebglInteractiveLines({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglInteractiveLines> {
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

  late final three.Object3D parentTransform;
  late final three.Mesh sphereInter;
  final raycaster = three.Raycaster();
  final three.Vector2 pointer = three.Vector2();
  int? intersected;

  final double radius = 100;
  double theta = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width / threeJs.height, 1, 10000 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0f0 );

    final geometry = three.SphereGeometry( 5 );
    final material = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

    sphereInter = three.Mesh( geometry, material );
    sphereInter.visible = false;
    threeJs.scene.add( sphereInter );

    final lineGeometry = three.BufferGeometry();
    final List<double> points = [];

    final point = three.Vector3();
    final direction = three.Vector3();

    for ( int i = 0; i < 50; i ++ ) {
      direction.x += math.Random().nextDouble() - 0.5;
      direction.y += math.Random().nextDouble() - 0.5;
      direction.z += math.Random().nextDouble() - 0.5;
      direction.normalize().scale( 10 );

      point.add( direction );
      points.addAll([ point.x, point.y, point.z ]);
    }

    lineGeometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( points, 3 ) );

    parentTransform = three.Object3D();
    parentTransform.position.x = math.Random().nextDouble() * 40 - 20;
    parentTransform.position.y = math.Random().nextDouble() * 40 - 20;
    parentTransform.position.z = math.Random().nextDouble() * 40 - 20;

    parentTransform.rotation.x = math.Random().nextDouble() * 2 * math.pi;
    parentTransform.rotation.y = math.Random().nextDouble() * 2 * math.pi;
    parentTransform.rotation.z = math.Random().nextDouble() * 2 * math.pi;

    parentTransform.scale.x = math.Random().nextDouble() + 0.5;
    parentTransform.scale.y = math.Random().nextDouble() + 0.5;
    parentTransform.scale.z = math.Random().nextDouble() + 0.5;

    for (int i = 0; i < 50; i ++ ) {
      three.Line object;

      final lineMaterial = three.LineBasicMaterial.fromMap( { 'color': (math.Random().nextDouble() * 0xffffff).toInt() } );

      if ( math.Random().nextDouble() > 0.5 ) {
        object = three.Line( lineGeometry, lineMaterial );
      } 
      else {
        object = three.LineSegments( lineGeometry, lineMaterial );
      }

      object.position.x = math.Random().nextDouble() * 400 - 200;
      object.position.y = math.Random().nextDouble() * 400 - 200;
      object.position.z = math.Random().nextDouble() * 400 - 200;

      object.rotation.x = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.y = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.z = math.Random().nextDouble() * 2 * math.pi;

      object.scale.x = math.Random().nextDouble() + 0.5;
      object.scale.y = math.Random().nextDouble() + 0.5;
      object.scale.z = math.Random().nextDouble() + 0.5;

      parentTransform.add( object );
    }

    threeJs.scene.add( parentTransform );
    raycaster.params['Line']['threshold'] = 2.0;

    threeJs.domElement.addEventListener( three.PeripheralType.pointerHover, onPointerMove );
    threeJs.addAnimationEvent(render);
  }

  void onPointerMove(three.WebPointerEvent event ) {
    pointer.x = ( event.clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( event.clientY / threeJs.height ) * 2 + 1;
  }

  void render([double? dt]){
    theta += 0.1;

    threeJs.camera.position.x = radius * math.sin( three.MathUtils.degToRad( theta ) );
    threeJs.camera.position.y = radius * math.sin( three.MathUtils.degToRad( theta ) );
    threeJs.camera.position.z = radius * math.cos( three.MathUtils.degToRad( theta ) );
    threeJs.camera.lookAt( threeJs.scene.position );

    threeJs.camera.updateMatrixWorld();

    raycaster.setFromCamera( pointer, threeJs.camera );

    final intersects = raycaster.intersectObjects( parentTransform.children, true );

    if ( intersects.isNotEmpty ) {
      sphereInter.visible = true;
      sphereInter.position.setFrom( intersects[ 0 ].point! );
    } 
    else {
      sphereInter.visible = false;

    }
  }
}
