import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglInteractiveVoxelpainter extends StatefulWidget {
  final String fileName;
  const WebglInteractiveVoxelpainter({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglInteractiveVoxelpainter> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.Raycaster raycaster;
  late three.BoxGeometry cubeGeo;
  late three.MeshLambertMaterial cubeMaterial;
  late three.MeshBasicMaterial rollOverMaterial;
  late three.Mesh rollOverMesh;
  late three.Vector2 pointer;
  late three.Mesh plane;
  List<three.Object3D> objects = []; 
  bool isShiftDown = false;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 10000 );
    threeJs.camera.position.setValues( 500, 800, 1300 );
    threeJs.camera.lookAt(three.Vector3(0, 0, 0) );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0f0 );

    // roll-over helpers

    final rollOverGeo = three.BoxGeometry( 50, 50, 50 );
    rollOverMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'opacity': 0.5, 'transparent': true } );
    rollOverMesh = three.Mesh( rollOverGeo, rollOverMaterial );
    threeJs.scene.add( rollOverMesh );

    // cubes

    final map = await three.TextureLoader().fromAsset( 'assets/textures/square-outline-textured.png' );
    //map.colorSpace = three.SRGBColorSpace;
    cubeGeo = three.BoxGeometry( 50, 50, 50 );
    cubeMaterial = three.MeshLambertMaterial.fromMap( { 'color': 0xfeb74c, 'map': map } );

    // grid

    final gridHelper = GridHelper( 1000, 20 );
    threeJs.scene.add( gridHelper );

    //

    raycaster = three.Raycaster();
    pointer = three.Vector2();

    final geometry = three.PlaneGeometry( 1000, 1000 );
    geometry.rotateX( - math.pi / 2 );

    plane = three.Mesh( geometry, three.MeshBasicMaterial.fromMap( { 'visible': false } ) );
    threeJs.scene.add( plane );

    objects.add( plane );

    // lights

    final ambientLight = three.AmbientLight( 0x606060, 0.9 );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 0.9 );
    directionalLight.position.setValues( 1, 0.75, 0.5 ).normalize();
    threeJs.scene.add( directionalLight );

    threeJs.domElement.addEventListener( three.PeripheralType.pointerHover, onPointerMove );
    threeJs.domElement.addEventListener(three.PeripheralType.pointerdown, onPointerDown );
    threeJs.domElement.addEventListener(three.PeripheralType.keydown, onDocumentKeyDown );
    threeJs.domElement.addEventListener(three.PeripheralType.keyup, onDocumentKeyUp );

  }

  void onPointerMove( event ) {
    pointer.setValues( ( event.clientX / threeJs.width ) * 2 - 1, - ( event.clientY / threeJs.height ) * 2 + 1 );
    raycaster.setFromCamera( pointer, threeJs.camera );

    final intersects = raycaster.intersectObjects( objects, false );

    if ( intersects.isNotEmpty ) {
      final intersect = intersects[ 0 ];

      rollOverMesh.position.setFrom( intersect.point! ).add( intersect.face!.normal );
      rollOverMesh.position.divideScalar( 50 ).floor().scale( 50 ).addScalar( 25 );
    }
  }

  void onPointerDown( event ) {
    pointer.setValues( ( event.clientX / threeJs.width ) * 2 - 1, - ( event.clientY / threeJs.height ) * 2 + 1 );
    raycaster.setFromCamera( pointer, threeJs.camera );

    final intersects = raycaster.intersectObjects( objects, false );

    if ( intersects.isNotEmpty ) {

      final intersect = intersects[ 0 ];

      // delete cube

      if ( isShiftDown ) {
        if ( intersect.object != plane ) {
          threeJs.scene.remove( intersect.object! );
          objects.removeAt( objects.indexOf( intersect.object! ));
        }
        // create cube
      } 
      else {
        final voxel = three.Mesh( cubeGeo, cubeMaterial );
        voxel.position.setFrom( intersect.point! ).add( intersect.face!.normal );
        voxel.position.divideScalar( 50 ).floor().scale( 50 ).addScalar( 25 );
        threeJs.scene.add( voxel );

        objects.add( voxel );

      }
    }
  }

  void onDocumentKeyDown( event ) {
    switch ( event.keyCode ) {
      case 16: isShiftDown = true; break;
    }
  }

  void onDocumentKeyUp( event ) {
    switch ( event.keyCode ) {
      case 16: isShiftDown = false; break;
    }
  }
}
