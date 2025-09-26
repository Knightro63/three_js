import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/other/constants.dart';
import 'package:three_js_xr/three_js_xr.dart';

class WebXRVRHandInputCubes extends StatefulWidget {
  const WebXRVRHandInputCubes({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRHandInputCubes> {
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
        xr: xrSetup,
        enableShadowMap: true
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
          if(threeJs.mounted) VRButton(threeJs: threeJs)
        ],
      ) 
    );
  }

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  WebXRController? hand1;
  WebXRController? controllerGrip1;
  WebXRController? controller1;
  WebXRController? hand2;
  WebXRController? controllerGrip2;
  WebXRController? controller2;

  final tmpVector1 = three.Vector3();
  final tmpVector2 = three.Vector3();

  List<three.Mesh> spheres = [];

  bool grabbing = false;
  final Map<String,dynamic> scaling = {
    'active': false,
    'initialDistance': 0,
    'object': null,
    'initialScale': 1
  };

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    (threeJs.renderer?.xr as WebXRWorker).setUpOptions(XROptions(
      width: threeJs.width,
      height: threeJs.height,
      dpr: threeJs.dpr,
    ));

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x444444 );

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 10 );
    threeJs.camera.position.setValues( 0, 1.6, 3 );

    final floorGeometry = three.PlaneGeometry( 4, 4 );
    final floorMaterial = three.MeshStandardMaterial.fromMap( { 'color': 0x666666 } );
    final floor = three.Mesh( floorGeometry, floorMaterial );
    floor.rotation.x = - math.pi / 2;
    floor.receiveShadow = true;
    threeJs.scene.add( floor );
    threeJs.scene.add( three.HemisphereLight( 0xbcbcbc, 0xa5a5a5, 3 ) );

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 0, 6, 0 );
    light.castShadow = true;
    light.shadow?.camera?.top = 2;
    light.shadow?.camera?.bottom = - 2;
    light.shadow?.camera?.right = 2;
    light.shadow?.camera?.left = - 2;
    light.shadow?.mapSize.setValues( 4096, 4096 );
    threeJs.scene.add( light );

    // controllers
    controller1 = (threeJs.renderer?.xr as WebXRWorker).getController( 0 );
    threeJs.scene.add( controller1 );

    controller2 = (threeJs.renderer?.xr as WebXRWorker).getController( 1 );
    threeJs.scene.add( controller2 );

    final controllerModelFactory = XRControllerModelFactory();
    final handModelFactory = XRHandModelFactory();

    // Hand 1
    controllerGrip1 = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 0 );
    controllerGrip1?.add( controllerModelFactory.createControllerModel( controllerGrip1! ) );
    threeJs.scene.add( controllerGrip1 );

    hand1 = (threeJs.renderer?.xr as WebXRWorker).getHand( 0 );
    hand1?.addEventListener( 'pinchstart', onPinchStartLeft );
    hand1?.addEventListener( 'pinchend', (){scaling['active'] = false;});
    hand1?.add( handModelFactory.createHandModel( hand1! ) );

    threeJs.scene.add( hand1 );

    // Hand 2
    controllerGrip2 = (threeJs.renderer?.xr as WebXRWorker).getControllerGrip( 1 );
    controllerGrip2?.add( controllerModelFactory.createControllerModel( controllerGrip2! ) );
    threeJs.scene.add( controllerGrip2 );

    hand2 = (threeJs.renderer?.xr as WebXRWorker).getHand( 1 );
    hand2?.addEventListener( 'pinchstart', onPinchStartRight );
    hand2?.addEventListener( 'pinchend', onPinchEndRight );
    hand2?.add( handModelFactory.createHandModel( hand2! ) );
    threeJs.scene.add( hand2 );

    //
    final geometry = three.BufferGeometry().setFromPoints( [ three.Vector3( 0, 0, 0 ), three.Vector3( 0, 0, - 1 ) ] );

    final line = three.Line( geometry );
    line.name = 'line';
    line.scale.z = 5;

    controller1?.add( line.clone() );
    controller2?.add( line.clone() );

    threeJs.customRenderer = (threeJs.renderer?.xr as WebXRWorker).render;
  }

  final SphereRadius = 0.05;

  void onPinchStartLeft( event ) {
    final controller = event.target;

    if ( grabbing ) {
      final indexTip = controller.joints[ 'index-finger-tip' ];
      final sphere = collideObject( indexTip );
      if ( sphere != null) {
        final sphere2 = hand2!.userData['selected'];
        if ( sphere == sphere2 ) {
          scaling['active'] = true;
          scaling['object'] = sphere;
          scaling['initialScale'] = sphere.scale.x;
          scaling['initialDistance'] = indexTip.position.distanceTo( hand2!.joints[ 'index-finger-tip' ].position );
          return;
        }
      }
    }

    final geometry = three.BoxGeometry( SphereRadius, SphereRadius, SphereRadius );
    final material = three.MeshStandardMaterial.fromMap( {
      'color':( math.Random().nextDouble() * 0xffffff).toInt(),
      'roughness': 1.0,
      'metalness': 0.0
    } );
    final spawn = three.Mesh( geometry, material );
    spawn.geometry?.computeBoundingSphere();

    final indexTip = controller.joints[ 'index-finger-tip' ];
    spawn.position.setFrom( indexTip.position );
    spawn.quaternion.setFrom( indexTip.quaternion );

    spheres.add( spawn );
    threeJs.scene.add( spawn );
  }

  three.Mesh? collideObject( indexTip ) {
    for (int i = 0; i < spheres.length; i ++ ) {
      final sphere = spheres[ i ];
      final distance = indexTip.getWorldPosition( tmpVector1 ).distanceTo( sphere.getWorldPosition( tmpVector2 ) );

      if ( distance < (sphere.geometry?.boundingSphere?.radius ?? 0) * sphere.scale.x ) {
        return sphere;
      }
    }

    return null;
  }

  void onPinchStartRight( event ) {
    final controller = event.target;
    final indexTip = controller.joints[ 'index-finger-tip' ];
    final object = collideObject( indexTip );
    if ( object != null) {
      grabbing = true;
      indexTip.attach( object );
      controller.userData.selected = object;
      three.console.verbose( 'Selected' );
    }
  }

  void onPinchEndRight( event ) {
    final controller = event.target;

    if ( controller.userData['selected'] != null ) {
      final object = controller.userData['selected'];
      object?.material?.emissive?.blue = 0;
      threeJs.scene.attach( object! );

      controller.userData.selected = null;
      grabbing = false;
    }

    scaling['active'] = false;
  }

  void animate() {
    if ( scaling['active'] == true) {
      final indexTip1Pos = hand1!.joints[ 'index-finger-tip' ].position;
      final indexTip2Pos = hand2!.joints[ 'index-finger-tip' ].position;
      final distance = indexTip1Pos.distanceTo( indexTip2Pos );
      final newScale = scaling['initialScale'] + distance / scaling['initialDistance'] - 1;
      scaling['object'].scale.setScalar( newScale );
    }
  }
}
