import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderPly extends StatefulWidget {
  
  const WebglLoaderPly({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderPly> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useSourceTexture: true
      )
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

      body: threeJs.build()
    );
  }

  late three.Vector3 cameraTarget;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 35, threeJs.width/threeJs.height, 1, 15 );
    threeJs.camera.position.setValues( 3, 0.15, 3 );

    cameraTarget = three.Vector3( 0, - 0.1, 0 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x72645b );
    threeJs.scene.fog = three.Fog( 0x72645b, 2, 15 );


    // Ground

    final plane = three.Mesh(
      three.PlaneGeometry( 40, 40 ),
      three.MeshPhongMaterial.fromMap( { 'color': 0xcbcbcb, 'specular': 0x474747 } )
    );
    plane.rotation.x = - math.pi / 2;
    plane.position.y = - 0.5;
    threeJs.scene.add( plane );

    plane.receiveShadow = true;


    // PLY file

    final loader = three.PLYLoader();
    await loader.fromAsset( 'assets/models/ply/ascii/dolphins.ply').then(( geometry ) {

      geometry?.computeVertexNormals();

      final material = three.MeshStandardMaterial.fromMap( { 'color': 0x009cff, 'flatShading': true } );
      final mesh = three.Mesh( geometry, material );

      mesh.position.y = - 0.2;
      mesh.position.z = 0.3;
      mesh.rotation.x = - math.pi / 2;
      mesh.scale.scale( 0.001 );

      mesh.castShadow = true;
      mesh.receiveShadow = true;

      threeJs.scene.add( mesh );

    } );

    await loader.fromAsset( 'assets/models/ply/binary/Lucy100k.ply').then( ( geometry ) {
      geometry?.computeVertexNormals();

      final material = three.MeshStandardMaterial.fromMap( { 'color': 0x009cff, 'flatShading': true } );
      final mesh = three.Mesh( geometry, material );

      mesh.position.x = - 0.2;
      mesh.position.y = - 0.02;
      mesh.position.z = - 0.2;
      mesh.scale.scale( 0.0006 );

      mesh.castShadow = true;
      mesh.receiveShadow = true;

      threeJs.scene.add( mesh );
    } );

    // Lights

    threeJs.scene.add( three.HemisphereLight( 0x8d7c7c, 0x494966, 0.8 ) );

    addShadowedLight( 1, 1, 1, 0xffffff, 0.85 );
    addShadowedLight( 0.5, 1, - 1, 0xffd500, 0.8 );

    threeJs.addAnimationEvent((dt){
      render();
    });
  }

  void addShadowedLight(double x, double y, double z, int color, double intensity ) {

    final directionalLight = three.DirectionalLight( color, intensity );
    directionalLight.position.setValues( x, y, z );
    threeJs.scene.add( directionalLight );

    directionalLight.castShadow = true;

    const d = 1.0;
    directionalLight.shadow?.camera?.left = - d;
    directionalLight.shadow?.camera?.right = d;
    directionalLight.shadow?.camera?.top = d;
    directionalLight.shadow?.camera?.bottom = - d;

    directionalLight.shadow?.camera?.near = 1;
    directionalLight.shadow?.camera?.far = 4;

    directionalLight.shadow?.mapSize.width = 1024;
    directionalLight.shadow?.mapSize.height = 1024;

    directionalLight.shadow?.bias = - 0.001;
  }

  void render() {
    final timer = DateTime.now().millisecondsSinceEpoch * 0.0005;

    threeJs.camera.position.x = math.sin( timer ) * 2.5;
    threeJs.camera.position.z = math.cos( timer ) * 2.5;

    threeJs.camera.lookAt( cameraTarget );
  }
}
