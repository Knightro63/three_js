import 'dart:async';
import 'dart:math' as math;
import 'package:example/rollercoster/rollercoaster.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

extension on three.Vector3{
  three.Float32Array toNativeArray(three.Float32Array array, [int offset = 0]) {
    array[offset] = storage[0];
    array[offset + 1] = storage[1];
    array[offset + 2] = storage[2];
    return array;
  }
}

class WebXRVRRollercoaster extends StatefulWidget {
  const WebXRVRRollercoaster({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRRollercoaster> {
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
          Statistics(data: data),
        ],
      ) 
    );
  }

  late three.Mesh mesh; 
  late three.Material material;
  late three.BufferGeometry geometry;
  
  final position = three.Vector3();
  final tangent = three.Vector3();
  final lookAt = three.Vector3();

  double velocity = 0;
  double progress = 0;
  int prevTime = DateTime.now().millisecond;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0ff );

    final light = three.HemisphereLight( 0xfff0f0, 0x60606, 0.3 );
    light.position.setValues( 1, 1, 1 );
    threeJs.scene.add( light );

    final train = three.Object3D();
    threeJs.scene.add( train );

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 500 );
    train.add( threeJs.camera );

    // environment
    geometry = three.PlaneGeometry( 500, 500, 15, 15 );
    geometry.rotateX( - math.pi / 2 );

    final positions = geometry.attributes['position'].array;
    final vertex = three.Vector3();

    for (int i = 0; i < positions.length; i += 3 ) {
      vertex.fromNativeArray( positions, i );

      vertex.x += math.Random().nextDouble() * 10 - 5;
      vertex.z += math.Random().nextDouble() * 10 - 5;

      final distance = ( vertex.distanceTo( threeJs.scene.position ) / 5 ) - 25;
      vertex.y = math.Random().nextDouble() * math.max( 0, distance );

      vertex.toNativeArray( positions, i );
    }

    geometry.computeVertexNormals();

    material = three.MeshLambertMaterial.fromMap( {
      'color': 0x407000
    } );

    mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    geometry = TreesGeometry( mesh );
    material = three.MeshBasicMaterial.fromMap( {
      'side': three.DoubleSide, 'vertexColors': true
    } );
    mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    geometry = SkyGeometry();
    material = three.MeshBasicMaterial.fromMap( { 'color': 0xffffff } );
    mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    //
    const pi2 = math.pi * 2;

    RollerCoasterCurve rcc() {
      final vector = three.Vector3();
      final vector2 = three.Vector3();

      final rcc = RollerCoasterCurve(
        getPointAt:  (double t ) {
          t = t * pi2;

          final x = math.sin( t * 3 ) * math.cos( t * 4 ) * 50;
          final y = math.sin( t * 10 ) * 2 + math.cos( t * 17 ) * 2 + 5;
          final z = math.sin( t ) * math.sin( t * 4 ) * 50;

          return vector.setValues( x, y, z ).scale( 2 );
        }
      );

      rcc.getTangentAt = (double t ) {
        const delta = 0.0001;
        final t1 = math.max( 0.0, t - delta );
        final t2 = math.min( 1.0, t + delta );

        return vector2.setFrom( rcc.getPointAt( t2 ) )
          .sub( rcc.getPointAt( t1 ) ).normalize();
      };

      return rcc;
    }

    final curve = rcc();

    geometry = RollerCoasterGeometry(curve, 1500 );
    material = three.MeshPhongMaterial.fromMap( {
      'vertexColors': true
    } );
    mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    geometry = RollerCoasterLiftersGeometry(curve, 100 );
    material = three.MeshPhongMaterial();
    mesh = three.Mesh( geometry, material );
    mesh.position.y = 0.1;
    threeJs.scene.add( mesh );

    geometry = RollerCoasterShadowGeometry( curve, 500 );
    material = three.MeshBasicMaterial.fromMap( {
      'color': 0x305000, 'depthWrite': false, 'transparent': true
    } );
    mesh = three.Mesh( geometry, material );
    mesh.position.y = 0.1;
    threeJs.scene.add( mesh );

    final List<three.Mesh> funfairs = [];

    geometry = CylinderGeometry( 10, 10, 5, 15 );
    material = three.MeshLambertMaterial.fromMap( {
      'color': 0xff8080
    } );
    mesh = three.Mesh( geometry, material );
    mesh.position.setValues( - 80, 10, - 70 );
    mesh.rotation.x = math.pi / 2;
    threeJs.scene.add( mesh );

    funfairs.add( mesh );

    geometry = CylinderGeometry( 5, 6, 4, 10 );
    material = three.MeshLambertMaterial.fromMap( {
      'color': 0x8080ff
    } );
    mesh = three.Mesh( geometry, material );
    mesh.position.setValues( 50, 2, 30 );
    threeJs.scene.add( mesh );

    funfairs.add( mesh );

    threeJs.addAnimationEvent((st){
      final time = DateTime.now().millisecond;
      final delta = time - prevTime;

      for (int i = 0; i < funfairs.length; i ++ ) {
        funfairs[ i ].rotation.y = time * 0.0004;
      }

      progress += velocity;
      progress = progress % 1;

      position.setFrom( curve.getPointAt( progress ) );
      position.y += 0.3;

      train.position.setFrom( position );

      tangent.setFrom( curve.getTangentAt( progress ) );

      velocity -= tangent.y * 0.0000001 * delta;
      velocity = math.max( 0.00004, math.min( 0.0002, velocity ) );

      train.lookAt( lookAt.setFrom( position ).sub( tangent ) );
      prevTime = time;
    });
  }
}
