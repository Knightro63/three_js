import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/three_js_objects.dart';
import 'package:three_js_xr/three_js_xr.dart';

class WebXRXRSculpt extends StatefulWidget {
  const WebXRXRSculpt({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRXRSculpt> {
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
	late final MarchingCubes blob;
	List<Map<String,dynamic>> points = [];

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

    void onSelectStart(WebXRController controller) {
      controller.userData['isSelecting'] = true;
    }

    void onSelectEnd(WebXRController controller) {
      controller.userData['isSelecting'] = false;
    }

    controller1 = (threeJs.renderer?.xr as WebXRWorker).getController( 0 );
    controller1?.addEventListener( 'selectstart', (event){onSelectStart(controller1!);} );
    controller1?.addEventListener( 'selectend', (event){onSelectEnd(controller1!);} );
    controller1?.userData['id'] = 0;
    threeJs.scene.add( controller1 );

    controller2 = (threeJs.renderer?.xr as WebXRWorker).getController( 1 );
    controller2?.addEventListener( 'selectstart', (event){onSelectStart(controller2!);} );
    controller2?.addEventListener( 'selectend', (event){onSelectEnd(controller2!);} );
    controller2?.userData['id'] = 1;
    threeJs.scene.add( controller2 );

    //
    final pivot = three.Mesh( three.IcosahedronGeometry( 0.01, 3 ) );
    pivot.name = 'pivot';
    pivot.position.z = - 0.05;

    final group = three.Group();
    group.add( pivot );

    controller1?.add( group.clone() );
    controller2?.add( group.clone() );

    initBlob();

    threeJs.addAnimationEvent((dt){
      handleController(controller1!);
      handleController(controller2!);

      updateBlob();
    });
  }
  
  void updateBlob() {
    blob.reset();

    for (int i = 0; i < points.length; i ++ ) {
      final point = points[ i ];
      final three.Vector3 position = point['position'];
      blob.addBall( position.x, position.y, position.z, point['strength'], point['subtract'] );
    }

    blob.update();
  }

  void initBlob() {

    /*
    const path = 'textures/cube/SwedishRoyalCastle/';
    const format = '.jpg';
    const urls = [
      path + 'px' + format, path + 'nx' + format,
      path + 'py' + format, path + 'ny' + format,
      path + 'pz' + format, path + 'nz' + format
    ];

    const reflectionCube = new THREE.CubeTextureLoader().load( urls );
    */

    final material = three.MeshStandardMaterial.fromMap( {
      'color': 0xffffff,
      // envMap: reflectionCube,
      'roughness': 0.9,
      'metalness': 0.0,
      'transparent': true
    } );

    blob = MarchingCubes( 64, material, false, false, 500000 );
    blob.position.y = 1;
    threeJs.scene.add( blob );

    initPoints();
  }

  void initPoints() {
    points = [
      { 'position': three.Vector3(), 'strength': 0.04, 'subtract': 10 },
      { 'position': three.Vector3(), 'strength': - 0.08, 'subtract': 10 }
    ];
  }

  void transformPoint(three.Vector3 vector ) {
    vector.x = ( vector.x + 1.0 ) / 2.0;
    vector.y = ( vector.y / 2.0 );
    vector.z = ( vector.z + 1.0 ) / 2.0;
  }

  void handleController(WebXRController controller ) {
    final pivot = controller.getObjectByName( 'pivot' );

    if ( pivot != null) {
      final id = controller.userData['id'];
      final matrix = pivot.matrixWorld;

      (points[ id ]['position'] as three.Vector3).setFromMatrixPosition( matrix );
      transformPoint( points[ id ]['position'] );

      if ( controller.userData['isSelecting'] == true) {
        final strength = points[ id ]['strength'] / 2;
        final vector = three.Vector3().setFromMatrixPosition( matrix );

        transformPoint( vector );
        points.add( { 'position': vector, 'strength': strength, 'subtract': 10 } );
      }
    }
  }
}
