import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/three_js_xr.dart';

class WebXRXRDragging extends StatefulWidget {
  const WebXRXRDragging({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRXRDragging> {
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
    controls.dispose();
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

  final three.Raycaster raycaster = three.Raycaster();
  WebXRController? controller1;
  WebXRController? controller2;
  WebXRController? controllerGrip1;
  WebXRController? controllerGrip2;
  late three.OrbitControls controls;
  late three.Group group;

  List<three.Object3D?> intersected = [];

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x808080 );

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 10 );
    threeJs.camera.position.setValues( 0, 1.6, 3 );
    threeJs.scene.add( threeJs.camera );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setValues( 0, 1.6, 0 );
    controls.update();


    final floorGeometry = three.PlaneGeometry( 6, 6 );
    final floorMaterial = three.ShadowMaterial.fromMap( { 'opacity': 0.25, 'blending': three.CustomBlending, 'transparent': false } );
    final floor = three.Mesh( floorGeometry, floorMaterial );
    floor.rotation.x = - math.pi / 2;
    floor.receiveShadow = true;
    threeJs.scene.add( floor );

    threeJs.scene.add( three.HemisphereLight( 0xbcbcbc, 0xa5a5a5, 3 ) );

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 0, 6, 0 );
    light.castShadow = true;
    light.shadow?.camera?.top = 3;
    light.shadow?.camera?.bottom = - 3;
    light.shadow?.camera?.right = 3;
    light.shadow?.camera?.left = - 3;
    light.shadow?.mapSize.setValues( 4096, 4096 );
    threeJs.scene.add( light );

    group = three.Group();
    threeJs.scene.add( group );

    final geometries = [
      three.BoxGeometry( 0.2, 0.2, 0.2 ),
      three.ConeGeometry( 0.2, 0.2, 64 ),
      three.CylinderGeometry( 0.2, 0.2, 0.2, 64 ),
      three.IcosahedronGeometry( 0.2, 8 ),
      three.TorusGeometry( 0.2, 0.04, 64, 32 )
    ];

    for (int i = 0; i < 50; i ++ ) {
      final geometry = geometries[ ( math.Random().nextDouble() * geometries.length ).toInt() ];
      final material = three.MeshStandardMaterial.fromMap( {
        'color': (math.Random().nextDouble() * 0xffffff).toInt(),
        'roughness': 0.7,
        'metalness': 0.0
      } );

      final object = three.Mesh( geometry, material );

      object.position.x = math.Random().nextDouble() * 4 - 2;
      object.position.y = math.Random().nextDouble() * 2;
      object.position.z = math.Random().nextDouble() * 4 - 2;

      object.rotation.x = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.y = math.Random().nextDouble() * 2 * math.pi;
      object.rotation.z = math.Random().nextDouble() * 2 * math.pi;

      object.scale.setScalar( math.Random().nextDouble() + 0.5 );

      object.castShadow = true;
      object.receiveShadow = true;

      group.add( object );
    }

    // controllers
    controller1 = (threeJs.renderer!.xr as WebXRWorker).getController( 0 );
    controller1?.addEventListener( 'selectstart', onSelectStart );
    controller1?.addEventListener( 'selectend', onSelectEnd );
    threeJs.scene.add( controller1 );

    controller2 = (threeJs.renderer!.xr as WebXRWorker).getController( 1 );
    controller2?.addEventListener( 'selectstart', onSelectStart );
    controller2?.addEventListener( 'selectend', onSelectEnd );
    threeJs.scene.add( controller2 );

    final controllerModelFactory = XRControllerModelFactory();

    controllerGrip1 = (threeJs.renderer!.xr as WebXRWorker).getControllerGrip( 0 );
    controllerGrip1?.add( controllerModelFactory.createControllerModel( controllerGrip1!) );
    threeJs.scene.add( controllerGrip1 );

    controllerGrip2 = (threeJs.renderer!.xr as WebXRWorker).getControllerGrip( 1 );
    controllerGrip2?.add( controllerModelFactory.createControllerModel( controllerGrip2! ) );
    threeJs.scene.add( controllerGrip2 );

    //
    final geometry = three.BufferGeometry().setFromPoints( [ three.Vector3( 0, 0, 0 ), three.Vector3( 0, 0, - 1 ) ] );

    final line = three.Line( geometry );
    line.name = 'line';
    line.scale.z = 5;

    controller1?.add( line.clone() );
    controller2?.add( line.clone() );

    threeJs.addAnimationEvent((dt){
      animate();
    });
  }


  void onSelectStart(three.Event event ) {
    final controller = event.target;
    final intersections = getIntersections( controller );

    if ( intersections.isNotEmpty ) {
      final intersection = intersections[ 0 ];

      final object = intersection.object;
      object?.material?.emissive?.blue = 1;
      controller?.attach( object );
      controller?.userData['selected'] = object;
    }

    controller?.userData['targetRayMode'] = event.data.targetRayMode;
  }

  void onSelectEnd(three.Event event ) {
    final controller = event.target;

    if ( controller?.userData['selected'] != null ) {
      final object = controller?.userData['selected'];
      object?.material?.emissive?.blue = 0;
      group.attach( object );
      controller?.userData['selected'] = null;
    }
  }

  List<three.Intersection> getIntersections(WebXRController controller ) {
    controller.updateMatrixWorld();
    raycaster.setFromXRController( controller );
    return raycaster.intersectObjects( group.children, false );
  }

  void intersectObjects(WebXRController controller ) {
    if ( controller.userData['targetRayMode'] == 'screen' ) return;
    if ( controller.userData['selected'] != null ) return;
    final line = controller.getObjectByName( 'line' );
    final intersections = getIntersections( controller );

    if ( intersections.isNotEmpty ) {
      final intersection = intersections[ 0 ];
      final object = intersection.object;
      object?.material?.emissive?.red = 1;
      intersected.add( object );

      line?.scale.z = intersection.distance;
    } 
    else {
      line?.scale.z = 5;
    }
  }

  void cleanIntersected() {
    while ( intersected.isNotEmpty ) {
      final object = intersected.removeLast();
      object?.material?.emissive?.red = 0;
    }
  }

  //

  void animate() {
    cleanIntersected();
    intersectObjects( controller1! );
    intersectObjects( controller2! );
  }
}
