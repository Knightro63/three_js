import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';

class WebglShadowmapCsm extends StatefulWidget {
  
  const WebglShadowmapCsm({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglShadowmapCsm> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late CSM csm;

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
        shadowMapType: three.PCFSoftShadowMap,
      )
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

  late three.OrbitControls controls;
  late three.OrthographicCamera orthoCamera;

  final Map<String,dynamic> params = {
    'orthographic': false,
    'fade': false,
    'far': 1000.0,
    'mode': CSMMode.practical,
    'lightX': - 1.0,
    'lightY': - 1.0,
    'lightZ': - 1.0,
    'margin': 100.0,
    'lightFar': 5000.0,
    'lightNear': 1.0,
    'autoUpdateHelper': true,
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0x454e61);
    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width/threeJs.height, 0.1, 5000 );
    orthoCamera = three.OrthographicCamera();

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.maxPolarAngle = math.pi/ 2;
    threeJs.camera.position.setValues( 60, 60, 0 );
    controls.target = three.Vector3( - 100, 10, 0 );
    controls.update();

    final ambientLight = three.AmbientLight( 0xffffff, 0.1 );
    threeJs.scene.add( ambientLight );

    final additionalDirectionalLight = three.DirectionalLight( 0x000020, 0.8 );
    additionalDirectionalLight.position.setValues( params['lightX'], params['lightY'], params['lightZ'] ).normalize().scale( - 200 );
    threeJs.scene.add( additionalDirectionalLight );

    csm = CSM(
      CSMData(
        maxFar: params['far'],
        cascades: 1,
        mode: params['mode'],
        parent: threeJs.scene,
        shadowMapSize: 1024,
        lightDirection: three.Vector3( params['lightX'], params['lightY'], params['lightZ'] ).normalize(),
        camera: threeJs.camera
      )
    );

    final floorMaterial = three.MeshPhongMaterial.fromMap( { 'color': 0x252a34 } );
    csm.setupMaterial( floorMaterial );

    final floor = three.Mesh( three.PlaneGeometry( 10000, 10000, 8, 8 ), floorMaterial );
    floor.rotation.x = - math.pi/ 2;
    floor.castShadow = true;
    floor.receiveShadow = true;
    threeJs.scene.add( floor );

    final material1 = three.MeshPhongMaterial.fromMap( { 'color': 0x08d9d6 } );
    csm.setupMaterial( material1 );

    final material2 = three.MeshPhongMaterial.fromMap( { 'color': 0xff2e63 } );
    csm.setupMaterial( material2 );

    final geometry = three.BoxGeometry( 10, 10, 10 );

    for (int i = 0; i < 40; i ++ ) {
      final cube1 = three.Mesh( geometry, i % 2 == 0 ? material1 : material2 );
      cube1.castShadow = true;
      cube1.receiveShadow = true;
      threeJs.scene.add( cube1 );
      cube1.position.setValues( - i * 25, 20, 30 );
      cube1.scale.y = math.Random().nextDouble() * 2 + 6;

      final cube2 = three.Mesh( geometry, i % 2 == 0 ? material2 : material1 );
      cube2.castShadow = true;
      cube2.receiveShadow = true;
      threeJs.scene.add( cube2 );
      cube2.position.setValues( - i * 25, 20, - 30 );
      cube2.scale.y = math.Random().nextDouble() * 2 + 6;
    }

    threeJs.addAnimationEvent((dt) {
      //updateOrthoCamera();
      animate();
    });

    threeJs.toDispose((){
      csm.dispose();
    });
  }

  void updateOrthoCamera() {

    final size = controls.target.distanceTo( threeJs.camera.position );
    final aspect = threeJs.camera.aspect;

    orthoCamera.left = size * aspect / - 2;
    orthoCamera.right = size * aspect / 2;

    orthoCamera.top = size / 2;
    orthoCamera.bottom = size / - 2;
    orthoCamera.position.setFrom( threeJs.camera.position );
    orthoCamera.rotation.copy( threeJs.camera.rotation );
    orthoCamera.updateProjectionMatrix();

  }
  void animate() {
    threeJs.camera.updateMatrixWorld();
    csm.update();
    controls.update();

    if (params['orthographic']) {
      updateOrthoCamera();
      csm.updateFrustums();
    } 
  }
}
