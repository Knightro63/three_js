import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/tube_painter.dart';
import 'package:three_js_xr/three_js_xr.dart';

class WebXRXRPaint extends StatefulWidget {
  const WebXRXRPaint({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRXRPaint> {
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

  late final three.OrbitControls controls;
  WebXRController? controller1;
  WebXRController? controller2;
  final cursor = three.Vector3();

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x222222 );

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.01, 50 );
    threeJs.camera.position.setValues( 0, 1.6, 3 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setValues( 0, 1.6, 0 );
    controls.update();

    final grid = GridHelper( 4, 1, 0x111111, 0x111111 );
    threeJs.scene.add( grid );

    threeJs.scene.add( three.HemisphereLight( 0x888877, 0x777788, 3 ) );

    final light = three.DirectionalLight( 0xffffff, 1.5 );
    light.position.setValues( 0, 4, 0 );
    threeJs.scene.add( light );

    //
    final painter1 = TubePainter();
    threeJs.scene.add( painter1.mesh );

    final painter2 = TubePainter();
    threeJs.scene.add( painter2.mesh );

    // controllers

    void onSelectStart(WebXRController controller) {
      controller.updateMatrixWorld( true );

      final pivot = controller.getObjectByName( 'pivot' );
      cursor.setFromMatrixPosition( pivot!.matrixWorld );

      final TubePainter painter = controller.userData['painter'];
      painter.moveTo( cursor );

      controller.userData['isSelecting'] = true;
    }

    void onSelectEnd(WebXRController controller) {
      controller.userData['isSelecting'] = false;
    }

    void onSqueezeStart(WebXRController controller) {
      controller.userData['isSqueezing'] = true;
      controller.userData['positionAtSqueezeStart'] = controller.position.y;
      controller.userData['scaleAtSqueezeStart'] = controller.scale.x;
    }

    void onSqueezeEnd(WebXRController controller) {
      controller.userData['isSqueezing'] = false;
    }

    controller1 = (threeJs.renderer?.xr as WebXRWorker).getController( 0 );
    controller1?.addEventListener( 'selectstart', (event){onSelectStart(controller1!);} );
    controller1?.addEventListener( 'selectend', (event){onSelectEnd(controller1!);} );
    controller1?.addEventListener( 'squeezestart', (event){onSqueezeStart(controller1!);} );
    controller1?.addEventListener( 'squeezeend', (event){onSqueezeEnd(controller1!);} );
    controller1?.userData['painter'] = painter1;
    threeJs.scene.add( controller1 );

    controller2 = (threeJs.renderer?.xr as WebXRWorker).getController( 1 );
    controller2?.addEventListener( 'selectstart', (event){onSelectStart(controller2!);} );
    controller2?.addEventListener( 'selectend', (event){onSelectEnd(controller2!);} );
    controller2?.addEventListener( 'squeezestart', (event){onSqueezeStart(controller2!);} );
    controller2?.addEventListener( 'squeezeend', (event){onSqueezeEnd(controller2!);} );
    controller2?.userData['painter'] = painter2;
    threeJs.scene.add( controller2 );

    //
    final pivot = three.Mesh( three.IcosahedronGeometry( 0.01, 3 ) );
    pivot.name = 'pivot';
    pivot.position.z = - 0.05;

    final group = three.Group();
    group.add( pivot );

    controller1?.add( group.clone() );
    controller2?.add( group.clone() );

    threeJs.addAnimationEvent((dt){
      handleController(controller1!);
      handleController(controller2!);
    });
  }

  void handleController(WebXRController controller ) {
    controller.updateMatrixWorld( true );

    final userData = controller.userData;
    final TubePainter painter = userData['painter'];
    final pivot = controller.getObjectByName( 'pivot' );

    if ( userData['isSqueezing'] == true ) {
      final delta = ( controller.position.y - userData['positionAtSqueezeStart'] ) * 5;
      final scale = math.max<double>( 0.1, userData['scaleAtSqueezeStart'] + delta );

      pivot?.scale.setScalar( scale );
      painter.setSize( scale );
    }

    cursor.setFromMatrixPosition( pivot!.matrixWorld );

    if ( userData['isSelecting'] == true ) {
      painter.lineTo( cursor );
      painter.update();
    }
  }
}
