import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/other/constants.dart';
import 'package:three_js_xr/three_js_xr.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

void main() {
  runApp(const WebXRXRCubes());
}

class WebXRXRCubes extends StatefulWidget {
  const WebXRXRCubes({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRXRCubes> {
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            threeJs.build(),
            if(threeJs.mounted) VRButton(threeJs: threeJs)
          ],
        ) 
      )
    );
  }

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  final three.Raycaster raycaster = three.Raycaster();
  late final three.LineSegments room;
  WebXRController? controller;
  WebXRController? controllerGrip;
  three.Object3D? intersected;
  final three.Matrix4 tempMatrix = three.Matrix4();

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
      (threeJs.renderer?.xr as WebXRWorker).setUpOptions(XROptions(
      width: threeJs.width,
      height: threeJs.height,
      dpr: threeJs.dpr,
    ));
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x505050 );
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 10 );
    threeJs.camera.position.setValues( 0, 1.6, 3 );
    threeJs.scene.add( threeJs.camera );

    room = three.LineSegments(
      BoxLineGeometry( 6, 6, 6, 10, 10, 10 ).translate( 0, 3, 0 ),
      three.LineBasicMaterial.fromMap( { 'color': 0xbcbcbc } )
    );
    threeJs.scene.add( room );

    threeJs.scene.add( three.HemisphereLight( 0xa5a5a5, 0x898989, 3 ) );

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 1, 1, 1 ).normalize();
    threeJs.scene.add( light );

    final geometry = three.BoxGeometry( 0.15, 0.15, 0.15 );

    for (int i = 0; i < 200; i ++ ) {
      final object = three.Mesh( geometry, three.MeshLambertMaterial.fromMap( { 'color': (math.Random().nextDouble() * 0xffffff).toInt() } ) );

      object.position.x = math.Random().nextDouble() * 4 - 2;
      object.position.y = math.Random().nextDouble() * 4;
      object.position.z = math.Random().nextDouble() * 4 - 2;

      object.rotation.x = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.y = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.z = math.Random().nextDouble() * 2 * math.pi;

      object.scale.x = math.Random().nextDouble() + 0.5;
      object.scale.y = math.Random().nextDouble() + 0.5;
      object.scale.z = math.Random().nextDouble() + 0.5;

      object.userData['velocity'] = three.Vector3();
      object.userData['velocity'].x = math.Random().nextDouble() * 0.01 - 0.005;
      object.userData['velocity'].y = math.Random().nextDouble() * 0.01 - 0.005;
      object.userData['velocity'].z = math.Random().nextDouble() * 0.01 - 0.005;

      room.add( object );
    }

    void onSelectStart(event) {
      controller?.userData['isSelecting'] = true;
    }

    void onSelectEnd(event) {
      controller?.userData['isSelecting'] = false;
    }

    controller = (threeJs.renderer?.xr as WebXRWorker).getController( 0 );
    controller?.addEventListener( 'selectstart', onSelectStart );
    controller?.addEventListener( 'selectend', onSelectEnd );
    controller?.addEventListener( 'connected', ( event ) {
      controller?.add( buildController( event.data ) );
    } );
    controller?.addEventListener( 'disconnected', (event) {
      controller?.remove( controller!.children[ 0 ] );
    } );
    threeJs.scene.add( controller );

    final controllerModelFactory = XRControllerModelFactory();

    controllerGrip = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 0 );
    controllerGrip?.add( controllerModelFactory.createControllerModel( controllerGrip! ) );
    threeJs.scene.add( controllerGrip );

    threeJs.customRenderer = (threeJs.renderer?.xr as WebXRWorker).render;

    threeJs.addAnimationEvent((dt){
      render();
    });
  }

  three.Object3D? buildController( data ) {
    three.BufferGeometry geometry;
    three.Material material;

    switch ( data.targetRayMode ) {
      case 'tracked-pointer':
        geometry = three.BufferGeometry();
        geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( [ 0, 0, 0, 0, 0, - 1 ], 3 ) );
        geometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( [ 0.5, 0.5, 0.5, 0, 0, 0 ], 3 ) );

        material = three.LineBasicMaterial.fromMap( { 'vertexColors': true, 'blending': three.AdditiveBlending } );

        return three.Line( geometry, material );

      case 'gaze':
        geometry = three.RingGeometry( 0.02, 0.04, 32 ).translate( 0, 0, - 1 );
        material = three.MeshBasicMaterial.fromMap( { 'opacity': 0.5, 'transparent': true } );
        return three.Mesh( geometry, material );
    }

    return null;
  }

  void render() {
    final delta = threeJs.clock.getDelta() * 60;
    if ( controller != null ){
      if ( controller?.userData['isSelecting'] == true ) {
        final cube = room.children[ 0 ];
        room.remove( cube );

        cube.position.setFrom( controller!.position );
        cube.userData['velocity'].x = ( math.Random().nextDouble() - 0.5 ) * 0.02 * delta;
        cube.userData['velocity'].y = ( math.Random().nextDouble() - 0.5 ) * 0.02 * delta;
        cube.userData['velocity'].z = ( math.Random().nextDouble() * 0.01 - 0.05 ) * delta;
        cube.userData['velocity'].applyQuaternion( controller!.quaternion );
        room.add( cube );
      }

      // find intersections
      tempMatrix.identity().extractRotation( controller!.matrixWorld );
      raycaster.ray.origin.setFromMatrixPosition( controller!.matrixWorld );
    }
    raycaster.ray.direction.setValues( 0, 0, - 1 ).applyMatrix4( tempMatrix );

    final intersects = raycaster.intersectObjects( room.children, false );

    if ( intersects.isNotEmpty ) {
      if ( intersected != intersects[ 0 ].object ) {
        if ( intersected != null) intersected?.material?.emissive?.setFromHex32( intersected?.userData['currentHex'] );
        intersected = intersects[ 0 ].object;
        intersected?.userData['currentHex'] = intersected?.material?.emissive?.getHex();
        intersected?.material?.emissive?.setFromHex32( 0xff0000 );
      }
    } 
    else {
      if ( intersected != null) intersected?.material?.emissive?.setFromHex32( intersected?.userData['currentHex'] );
      intersected = null;
    }

    // Keep cubes inside room
    for (int i = 0; i < room.children.length; i ++ ) {
      final cube = room.children[ i ];
      cube.userData['velocity'].scale( 1 - ( 0.001 * delta ) );
      cube.position.add( cube.userData['velocity'] );

      if ( cube.position.x < - 3 || cube.position.x > 3 ) {
        cube.position.x = three.MathUtils.clamp( cube.position.x, - 3, 3 );
        cube.userData['velocity'].x = - cube.userData['velocity'].x;
      }

      if ( cube.position.y < 0 || cube.position.y > 6 ) {
        cube.position.y = three.MathUtils.clamp( cube.position.y, 0, 6 );
        cube.userData['velocity'].y = - cube.userData['velocity'].y;
      }

      if ( cube.position.z < - 3 || cube.position.z > 3 ) {
        cube.position.z = three.MathUtils.clamp( cube.position.z, - 3, 3 );
        cube.userData['velocity'].z = - cube.userData['velocity'].z;
      }

      cube.rotation.x += cube.userData['velocity'].x * 2 * delta;
      cube.rotation.y += cube.userData['velocity'].y * 2 * delta;
      cube.rotation.z += cube.userData['velocity'].z * 2 * delta;
    }
  }
}
