import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglInteractiveRaycastingPoints extends StatefulWidget {
  const WebglInteractiveRaycastingPoints({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglInteractiveRaycastingPoints> {
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

  final three.Raycaster raycaster = three.Raycaster();
  final three.Vector2 pointer = three.Vector2();
  final threshold = 0.1;
  final pointSize = 0.05;
  final width = 80;
  final length = 160;
  final rotateY = three.Matrix4().makeRotationY( 0.005 );

  final List<three.Object3D> spheres = [];
  late List<three.Points> pointclouds;

  three.Intersection? intersection;
  int spheresIndex = 0;
  double toggle = 0;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.setValues( 10, 10, 10 );
    threeJs.camera.lookAt( threeJs.scene.position );
    threeJs.camera.updateMatrix();

    final pcBuffer = generatePointcloud( three.Color( 1, 0, 0 ), width, length );
    pcBuffer.scale.setValues( 5, 10, 10 );
    pcBuffer.position.setValues( - 5, 0, 0 );
    threeJs.scene.add( pcBuffer );

    final pcIndexed = generateIndexedPointcloud( three.Color( 0, 1, 0 ), width, length );
    pcIndexed.scale.setValues( 5, 10, 10 );
    pcIndexed.position.setValues( 0, 0, 0 );
    threeJs.scene.add( pcIndexed );

    final pcIndexedOffset = generateIndexedWithOffsetPointcloud( three.Color( 0, 1, 1 ), width, length );
    pcIndexedOffset.scale.setValues( 5, 10, 10 );
    pcIndexedOffset.position.setValues( 5, 0, 0 );
    threeJs.scene.add( pcIndexedOffset );

    pointclouds = [ pcBuffer, pcIndexed, pcIndexedOffset ];

    final sphereGeometry = three.SphereGeometry( 0.1, 32, 32 );
    final sphereMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

    for ( int i = 0; i < 40; i ++ ) {
      final sphere = three.Mesh( sphereGeometry, sphereMaterial );
      threeJs.scene.add( sphere );
      spheres.add( sphere );
    }

    raycaster.params['Points']['threshold'] = threshold;
    threeJs.domElement.addEventListener(three.PeripheralType.pointerHover, onPointerMove );

    threeJs.addAnimationEvent((dt){
      render(dt);
    });
  }

	three.BufferGeometry generatePointCloudGeometry(three.Color color, int width, int length ) {
    final geometry = three.BufferGeometry();
    final numPoints = (width * length).toInt();

    final positions = three.Float32Array( numPoints * 3 );
    final colors = three.Float32Array( numPoints * 3 );

    int k = 0;

    for ( int i = 0; i < width; i ++ ) {
      for ( int j = 0; j < length; j ++ ) {
        final u = i / width;
        final v = j / length;
        final x = u - 0.5;
        final y = ( math.cos( u * math.pi * 4 ) + math.sin( v * math.pi * 8 ) ) / 20;
        final z = v - 0.5;

        positions[ 3 * k ] = x;
        positions[ 3 * k + 1 ] = y;
        positions[ 3 * k + 2 ] = z;

        final intensity = ( y + 0.1 ) * 5;
        colors[ 3 * k ] = color.red * intensity;
        colors[ 3 * k + 1 ] = color.green * intensity;
        colors[ 3 * k + 2 ] = color.blue * intensity;

        k ++;
      }
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute( positions, 3 ) );
    geometry.setAttributeFromString( 'color', three.Float32BufferAttribute( colors, 3 ) );
    geometry.computeBoundingBox();

    return geometry;
  }

  three.Points generatePointcloud(three.Color color, int width, int length ) {
    final geometry = generatePointCloudGeometry( color, width, length );
    final material = three.PointsMaterial.fromMap( { 'size': pointSize, 'vertexColors': true } );

    return three.Points( geometry, material );
  }

  three.Points generateIndexedPointcloud(three.Color color, int width, int length ) {
    final geometry = generatePointCloudGeometry( color, width, length );
    final numPoints = (width * length).toInt();
    final indices = three.Uint16Array( numPoints );

    int k = 0;

    for ( int i = 0; i < width; i ++ ) {
      for ( int j = 0; j < length; j ++ ) {
        indices[ k ] = k;
        k ++;
      }
    }

    geometry.setIndex( three.Uint16BufferAttribute( indices, 1 ) );
    final material = three.PointsMaterial.fromMap( { 'size': pointSize, 'vertexColors': true } );
    return three.Points( geometry, material );
  }

  three.Points generateIndexedWithOffsetPointcloud(three.Color color, int width, int length ) {
    final geometry = generatePointCloudGeometry( color, width, length );
    final numPoints = (width * length).toInt();
    final indices = three.Uint16Array( numPoints );

    int k = 0;

    for ( int i = 0; i < width; i ++ ) {
      for ( int j = 0; j < length; j ++ ) {
        indices[ k ] = k;
        k ++;
      }
    }

    geometry.setIndex( three.Uint16BufferAttribute( indices, 1 ) );
    geometry.addGroup( 0, indices.length );
    final material = three.PointsMaterial.fromMap( { 'size': pointSize, 'vertexColors': true } );

    return three.Points( geometry, material );
  }

  void onPointerMove(three.WebPointerEvent event ) {
    pointer.x = ( event.clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( event.clientY / threeJs.height ) * 2 + 1;
  }

  void render(double dt){
    threeJs.camera.position.applyMatrix4( rotateY );
    threeJs.camera.lookAt( threeJs.scene.position );
    threeJs.camera.updateMatrixWorld();

    raycaster.setFromCamera( pointer, threeJs.camera );

    final intersections = raycaster.intersectObjects( pointclouds, false );
    intersection = intersections.isNotEmpty ? intersections[ 0 ] : null;

    if ( toggle > 0.02 && intersection != null ) {
      spheres[ spheresIndex ].position.setFrom( intersection!.point! );
      spheres[ spheresIndex ].scale.setValues( 1, 1, 1 );
      spheresIndex = ( spheresIndex + 1 ) % spheres.length;

      toggle = 0;
    }

    for (int i = 0; i < spheres.length; i ++ ) {
      final sphere = spheres[ i ];
      sphere.scale.scale( 0.98 );
      sphere.scale.clampScalar( 0.01, 1 );
    }

    toggle += dt;
  }
}
