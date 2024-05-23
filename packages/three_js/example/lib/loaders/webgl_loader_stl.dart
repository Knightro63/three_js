import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderStl extends StatefulWidget {
  final String fileName;
  const WebglLoaderStl({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderStl> {
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

  late three.Vector3 cameraTarget;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 35, threeJs.width/threeJs.height, 1, 15 );
    threeJs.camera.position.setValues( 3, 0.15, 3 );

    cameraTarget = three.Vector3( 0, - 0.25, 0 );

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


    // ASCII file

    final loader = three.STLLoader();
    await loader.fromAsset( 'assets/models/stl/ascii/slotted_disk.stl').then( ( geometry ) {

      final material = three.MeshPhongMaterial.fromMap( { 'color': 0xff9c7c, 'specular': 0x494949, 'shininess': 200 } );
      final mesh = three.Mesh( geometry, material );

      mesh.position.setValues( 0, - 0.25, 0.6 );
      mesh.rotation.set( 0, - math.pi / 2, 0 );
      mesh.scale.setValues( 0.5, 0.5, 0.5 );

      mesh.castShadow = true;
      mesh.receiveShadow = true;

      threeJs.scene.add( mesh );
    } );


    // Binary files

    final material = three.MeshPhongMaterial.fromMap( { 'color': 0xd5d5d5, 'specular': 0x494949, 'shininess': 200 } );

    await loader.fromAsset( 'assets/models/stl/binary/pr2_head_pan.stl').then( ( geometry ) {

      final mesh = three.Mesh( geometry, material );

      mesh.position.setValues( 0, - 0.37, - 0.6 );
      mesh.rotation.set( - math.pi / 2, 0, 0 );
      mesh.scale.setValues( 2, 2, 2 );

      mesh.castShadow = true;
      mesh.receiveShadow = true;

      threeJs.scene.add( mesh );

    } );

    await loader.fromAsset( 'assets/models/stl/binary/pr2_head_tilt.stl').then( ( geometry ) {

      final mesh = three.Mesh( geometry, material );

      mesh.position.setValues( 0.136, - 0.37, - 0.6 );
      mesh.rotation.set( - math.pi / 2, 0.3, 0 );
      mesh.scale.setValues( 2, 2, 2 );

      mesh.castShadow = true;
      mesh.receiveShadow = true;

      threeJs.scene.add( mesh );

    } );

    // Colored binary STL
    await loader.fromAsset( 'assets/models/stl/binary/colored.stl').then( ( geometry ) {

      three.Material meshMaterial = material;

      // if ( geometry.hasColors ) {
      //   meshMaterial = three.MeshPhongMaterial.fromMap( { 'opacity': geometry.alpha, 'vertexColors': true } );
      // }

      final mesh = three.Mesh( geometry, meshMaterial );

      mesh.position.setValues( 0.5, 0.2, 0 );
      mesh.rotation.set( - math.pi / 2, math.pi / 2, 0 );
      mesh.scale.setValues( 0.3, 0.3, 0.3 );

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

  void addShadowedLight(double x,double y,double z, int color, double intensity ) {
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

    directionalLight.shadow?.bias = - 0.002;
  }

  void render() {
    final timer = DateTime.now().millisecondsSinceEpoch * 0.0005;

    threeJs.camera.position.x = math.cos( timer ) * 3;
    threeJs.camera.position.z = math.sin( timer ) * 3;

    threeJs.camera.lookAt( cameraTarget );
  }
}
