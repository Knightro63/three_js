import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglPortal extends StatefulWidget {
  
  const WebglPortal({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglPortal> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        localClippingEnabled: true,
        toneMapping: three.ACESFilmicToneMapping,
        useSourceTexture: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    cameraControls.dispose();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: threeJs.build()
    );
  }

  late three.OrbitControls cameraControls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.camera = three.PerspectiveCamera( 45,threeJs.width / threeJs.height, 1, 5000 );
    threeJs.camera.position.setValues( 0, 75, 160 );

    cameraControls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    cameraControls.target.setValues( 0, 40, 0 );
    cameraControls.maxDistance = 400;
    cameraControls.minDistance = 10;
    cameraControls.update();

    //

    final planeGeo = three.PlaneGeometry( 100.1, 100.1 );

    // bouncing icosphere
    final portalPlane = three.Plane( three.Vector3( 0, 0, 1 ), 0.0 );
    final geometry = IcosahedronGeometry( 5, 0 );
    final material = three.MeshPhongMaterial.fromMap( {
      'color': 0xffffff, 'emissive': 0x333333, 'flatShading': true,
      'clippingPlanes': [ portalPlane ], } );
    final smallSphereOne = three.Mesh( geometry, material );
    threeJs.scene.add( smallSphereOne );
    final smallSphereTwo = three.Mesh( geometry, material );
    threeJs.scene.add( smallSphereTwo );

    // portals
    final portalCamera = three.PerspectiveCamera( 45, 1.0, 0.1, 500.0 );
    threeJs.scene.add( portalCamera );
    //frustumHelper = three.CameraHelper( portalCamera );
    //threeJs.scene.add( frustumHelper );
    final bottomLeftCorner = three.Vector3();
    final bottomRightCorner = three.Vector3();
    final topLeftCorner = three.Vector3();
    final reflectedPosition = three.Vector3();

    final leftPortalTexture = three.WebGLRenderTarget( 256, 256 );
    final leftPortal = three.Mesh( planeGeo, three.MeshBasicMaterial.fromMap( { 'map': leftPortalTexture.texture } ) );
    leftPortal.position.x = - 30;
    leftPortal.position.y = 20;
    leftPortal.scale.setValues( 0.35, 0.35, 0.35 );
    threeJs.scene.add( leftPortal );

    final rightPortalTexture = three.WebGLRenderTarget( 256, 256 );
    final rightPortal = three.Mesh( planeGeo, three.MeshBasicMaterial.fromMap( { 'map': rightPortalTexture.texture } ) );
    rightPortal.position.x = 30;
    rightPortal.position.y = 20;
    rightPortal.scale.setValues( 0.35, 0.35, 0.35 );
    threeJs.scene.add( rightPortal );

    // walls
    final planeTop = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } ) );
    planeTop.position.y = 100;
    planeTop.rotateX( math.pi / 2 );
    threeJs.scene.add( planeTop );

    final planeBottom = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } ) );
    planeBottom.rotateX( - math.pi / 2 );
    threeJs.scene.add( planeBottom );

    final planeFront = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0x7f7fff } ) );
    planeFront.position.z = 50;
    planeFront.position.y = 50;
    planeFront.rotateY( math.pi );
    threeJs.scene.add( planeFront );

    final planeBack = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xff7fff } ) );
    planeBack.position.z = - 50;
    planeBack.position.y = 50;
    //planeBack.rotateY( math.pi );
    threeJs.scene.add( planeBack );

    final planeRight = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0x00ff00 } ) );
    planeRight.position.x = 50;
    planeRight.position.y = 50;
    planeRight.rotateY( - math.pi / 2 );
    threeJs.scene.add( planeRight );

    final planeLeft = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xff0000 } ) );
    planeLeft.position.x = - 50;
    planeLeft.position.y = 50;
    planeLeft.rotateY( math.pi / 2 );
    threeJs.scene.add( planeLeft );

    // lights
    final mainLight = three.PointLight( 0xe7e7e7, 2.5, 250, 0 );
    mainLight.position.y = 60;
    threeJs.scene.add( mainLight );

    final greenLight = three.PointLight( 0x00ff00, 0.5, 1000, 0 );
    greenLight.position.setValues( 550, 50, 0 );
    threeJs.scene.add( greenLight );

    final redLight = three.PointLight( 0xff0000, 0.5, 1000, 0 );
    redLight.position.setValues( - 550, 50, 0 );
    threeJs.scene.add( redLight );

    final blueLight = three.PointLight( 0xbbbbfe, 0.5, 1000, 0 );
    blueLight.position.setValues( 0, 50, 550 );
    threeJs.scene.add( blueLight );

    void renderPortal(three.Mesh thisPortalMesh,three.Mesh otherPortalMesh,three.WebGLRenderTarget thisPortalTexture ) {
      // set the portal camera position to be reflected about the portal plane
      thisPortalMesh.worldToLocal( reflectedPosition.setFrom( threeJs.camera.position ) );
      reflectedPosition.x *= - 1.0; reflectedPosition.z *= - 1.0;
      otherPortalMesh.localToWorld( reflectedPosition );
      portalCamera.position.setFrom( reflectedPosition );

      // grab the corners of the other portal
      // - note: the portal is viewed backwards; flip the left/right coordinates
      otherPortalMesh.localToWorld( bottomLeftCorner.setValues( 50.05, - 50.05, 0.0 ) );
      otherPortalMesh.localToWorld( bottomRightCorner.setValues( - 50.05, - 50.05, 0.0 ) );
      otherPortalMesh.localToWorld( topLeftCorner.setValues( 50.05, 50.05, 0.0 ) );
      // set the projection matrix to encompass the portal's frame
      CameraUtils.frameCorners( portalCamera, bottomLeftCorner, bottomRightCorner, topLeftCorner, false );

      // render the portal
      //thisPortalTexture.texture.colorSpace = threeJs.renderer.outputColorSpace;
      threeJs.renderer?.setRenderTarget( thisPortalTexture );
      threeJs.renderer?.state.buffers['depth'].setMask( true ); // make sure the depth buffer is writable so it can be properly cleared, see #18897
      if ( threeJs.renderer?.autoClear == false ) threeJs.renderer?.clear();
      thisPortalMesh.visible = false; // hide this portal from its own rendering
      threeJs.renderer?.render( threeJs.scene, portalCamera );
      thisPortalMesh.visible = true; // re-enable this portal's visibility for general rendering
    }

    threeJs.postProcessor = ([double? dt]) {
      // move the bouncing sphere(s)
      final timerOne = DateTime.now().millisecondsSinceEpoch * 0.01;
      final timerTwo = timerOne + math.pi * 10.0;

      smallSphereOne.position.setValues(
        math.cos( timerOne * 0.1 ) * 30,
        ( math.cos( timerOne * 0.2 ) ).abs() * 20 + 5,
        math.sin( timerOne * 0.1 ) * 30
      );
      smallSphereOne.rotation.y = ( math.pi / 2 ) - timerOne * 0.1;
      smallSphereOne.rotation.z = timerOne * 0.8;

      smallSphereTwo.position.setValues(
        math.cos( timerTwo * 0.1 ) * 30,
        ( math.cos( timerTwo * 0.2 ) ).abs() * 20 + 5,
        math.sin( timerTwo * 0.1 ) * 30
      );
      smallSphereTwo.rotation.y = ( math.pi / 2 ) - timerTwo * 0.1;
      smallSphereTwo.rotation.z = timerTwo * 0.8;

      // save the original camera properties
      final currentRenderTarget = threeJs.renderer?.getRenderTarget();
      final currentXrEnabled = threeJs.renderer?.xr.enabled;
      final currentShadowAutoUpdate = threeJs.renderer?.shadowMap.autoUpdate;
      threeJs.renderer?.xr.enabled = false; // Avoid camera modification
      threeJs.renderer?.shadowMap.autoUpdate = false; // Avoid re-computing shadows

      // render the portal effect
      renderPortal( leftPortal, rightPortal, leftPortalTexture );
      renderPortal( rightPortal, leftPortal, rightPortalTexture );

      // restore the original rendering properties
      threeJs.renderer?.xr.enabled = currentXrEnabled!;
      threeJs.renderer?.shadowMap.autoUpdate = currentShadowAutoUpdate!;
      threeJs.renderer?.setRenderTarget( currentRenderTarget );

      // render the main scene
      threeJs.renderer?.render( threeJs.scene, threeJs.camera );
    };
  }
}
