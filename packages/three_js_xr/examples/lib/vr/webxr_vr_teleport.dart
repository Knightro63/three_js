import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_xr/three_js_xr.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'dart:math' as math;

class WebXRVRTeleport extends StatefulWidget {
  const WebXRVRTeleport({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebXRVRTeleport> {
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

  late three.Raycaster raycaster;
  XRReferenceSpace? baseReferenceSpace;

  WebXRWorker xrSetup(three.WebGLRenderer renderer, dynamic gl){
    return WebXRWorker(renderer,gl);
  }

  Future<void> setup() async {
    threeJs.renderer?.xr.enabled = true;
    //(threeJs.renderer?.xr as WebXRWorker).addEventListener( 'sessionstart', (event) => baseReferenceSpace = (threeJs.renderer?.xr as WebXRWorker).getReferenceSpace() );

    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.1, 10 );
    threeJs.camera.position.setValues( 0, 1, 3 );

    final room = three.LineSegments(
      BoxLineGeometry( 6, 6, 6, 10, 10, 10 ).translate( 0, 3, 0 ),
      three.LineBasicMaterial.fromMap( { 'color': 0xbcbcbc } )
    );
    threeJs.scene.add( room );

    threeJs.scene.add( three.HemisphereLight( 0xa5a5a5, 0x898989, 3 ) );

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 1, 1, 1 ).normalize();
    threeJs.scene.add( light );

    final marker = three.Mesh(
      three.CircleGeometry(radius: 0.25, segments: 32 ).rotateX( - math.pi / 2 ),
      three.MeshBasicMaterial.fromMap( { 'color': 0xbcbcbc } )
    );
    threeJs.scene.add( marker );

    final floor = three.Mesh(
      three.PlaneGeometry( 4.8, 4.8, 2, 2 ).rotateX( - math.pi / 2 ),
      three.MeshBasicMaterial.fromMap( { 'color': 0xbcbcbc, 'transparent': true, 'opacity': 0.25 } )
    );
    threeJs.scene.add( floor );

    raycaster = three.Raycaster();

    // controllers
    three.Vector3? intersection;

    void onSelectEnd() {
      if ( intersection != null) {
        print('jediou32hio');
        final offsetPosition = { 'x': - intersection!.x, 'y': - intersection!.y, 'z': - intersection!.z, 'w': 1 };
        final offsetRotation = three.Quaternion();
        final transform = XRRigidTransform( offsetPosition.jsify(), offsetRotation.toMap().jsify());
        final teleportSpaceOffset = baseReferenceSpace?.getOffsetReferenceSpace( transform );
        (threeJs.renderer!.xr as WebXRWorker).setReferenceSpace( teleportSpaceOffset );
      }
    }

    final controller1 = (threeJs.renderer!.xr as WebXRWorker).getController( 0 )!;
    controller1.addEventListener( 'selectstart', (event){controller1.userData['isSelecting'] = true;} );
    controller1.addEventListener( 'selectend', (event){controller1.userData['isSelecting'] = false; onSelectEnd();});
    controller1.addEventListener( 'connected', (three.Event event ) {
      controller1.add( buildController( event.data ) );
    });
    controller1.addEventListener( 'disconnected', (event) {
      controller1.remove( controller1.children[ 0 ] );
    });
    threeJs.scene.add( controller1 );

    final controller2 = (threeJs.renderer!.xr as WebXRWorker).getController( 1 )!;
    controller2.addEventListener( 'selectstart', (event){controller2.userData['isSelecting'] = true;}  );
    controller2.addEventListener( 'selectend', (event){controller1.userData['isSelecting'] = false; onSelectEnd();} );
    controller2.addEventListener( 'connected', (three.Event  event ) {
      controller2.add( buildController( event.data ) );
    });
    controller2.addEventListener( 'disconnected', (event) {
      controller2.remove( controller2.children[ 0 ] );
    });
    threeJs.scene.add( controller2 );

    // The XRControllerModelFactory will automatically fetch controller models
    // that match what the user is holding as closely as possible. The models
    // should be attached to the object returned from getControllerGrip in
    // order to match the orientation of the held device.

    final controllerModelFactory = XRControllerModelFactory();

    final controllerGrip1 = (threeJs.renderer!.xr as WebXRWorker).getControllerGrip( 0 )!;
    controllerGrip1.add( controllerModelFactory.createControllerModel( controllerGrip1 ) );
    threeJs.scene.add( controllerGrip1 );

    final controllerGrip2 = (threeJs.renderer!.xr as WebXRWorker).getControllerGrip( 1 )!;
    controllerGrip2.add( controllerModelFactory.createControllerModel( controllerGrip2 ) );
    threeJs.scene.add( controllerGrip2 );

    threeJs.addAnimationEvent((dt){
				intersection = null;
				if ( controller1.userData['isSelecting'] == true ) {
					final three.Matrix4 tempMatrix =three. Matrix4.identity().extractRotation( controller1.matrixWorld );

					raycaster.ray.origin.setFromMatrixPosition( controller1.matrixWorld );
					raycaster.ray.direction.setValues( 0, 0, - 1 ).applyMatrix4( tempMatrix );

					final intersects = raycaster.intersectObjects( [ floor ] );

					if ( intersects.isNotEmpty) {
						intersection = intersects[ 0 ].point;
					}
				} 
        else if ( controller2.userData['isSelecting'] == true ) {
					final three.Matrix4 tempMatrix = three.Matrix4.identity().extractRotation( controller2.matrixWorld );

					raycaster.ray.origin.setFromMatrixPosition( controller2.matrixWorld );
					raycaster.ray.direction.setValues( 0, 0, - 1 ).applyMatrix4( tempMatrix );

					final intersects = raycaster.intersectObjects( [ floor ] );

					if ( intersects.isNotEmpty ) {
						intersection = intersects[ 0 ].point;
					}
				}

				if ( intersection != null ) marker.position.setFrom( intersection! );
				marker.visible = intersection != null;
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
}
