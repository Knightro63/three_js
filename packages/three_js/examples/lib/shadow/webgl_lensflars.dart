import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';

class WebglLensflars extends StatefulWidget {
  final String fileName;
  const WebglLensflars({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglLensflars> {
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
    controls.dispose();
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

  late three.FlyControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width/threeJs.height, 1, 15000 );
    threeJs.camera.position.z = 250;

    // threeJs.scene

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color().setHSL( 0.51, 0.4, 0.01, three.ColorSpace.srgb );
    threeJs.scene.fog = three.Fog( (threeJs.scene.background as three.Color).getHex(), 3500, 15000 );

    // world

    const s = 250.0;

    final geometry = three.BoxGeometry( s, s, s );
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'specular': 0xffffff, 'shininess': 50 } );

    for (int i = 0; i < 3000; i ++ ) {

      final mesh = three.Mesh( geometry, material );

      mesh.position.x = 8000 * ( 2.0 * math.Random().nextDouble() - 1.0 );
      mesh.position.y = 8000 * ( 2.0 * math.Random().nextDouble() - 1.0 );
      mesh.position.z = 8000 * ( 2.0 * math.Random().nextDouble() - 1.0 );

      mesh.rotation.x = math.Random().nextDouble() * math.pi;
      mesh.rotation.y = math.Random().nextDouble() * math.pi;
      mesh.rotation.z = math.Random().nextDouble() * math.pi;

      mesh.matrixAutoUpdate = false;
      mesh.updateMatrix();

      threeJs.scene.add( mesh );

    }


    // lights

    final dirLight = three.DirectionalLight( 0xffffff, 0.15 );
    dirLight.position.setValues( 0, - 1, 0 ).normalize();
    dirLight.color?.setHSL( 0.1, 0.7, 0.5 );
    threeJs.scene.add( dirLight );

    // lensflares
    final textureLoader = three.TextureLoader();

    final textureFlare0 = await textureLoader.fromAsset( 'assets/textures/lensflare/lensflare0.png' );
    final textureFlare3 = await textureLoader.fromAsset( 'assets/textures/lensflare/lensflare3.png' );

    void addLight(double h,double s,double l,double x,double y,double z ) {
      final light = three.PointLight( 0xffffff, 1.5, 2000, 0 );
      light.color?.setHSL( h, s, l );
      light.position.setValues( x, y, z );
      threeJs.scene.add( light );

      final lensflare = Lensflare();
      lensflare.addElement( LensflareElement( textureFlare0!, 700, 0, light.color!.getHex() ) );
      lensflare.addElement( LensflareElement( textureFlare3!, 60, 0.6 ) );
      lensflare.addElement( LensflareElement( textureFlare3, 70, 0.7 ) );
      lensflare.addElement( LensflareElement( textureFlare3, 120, 0.9 ) );
      lensflare.addElement( LensflareElement( textureFlare3, 70, 1 ) );
      light.add( lensflare );
    }

    addLight( 0.55, 0.9, 0.5, 5000, 0, - 1000 );
    addLight( 0.08, 0.8, 0.5, 0, 0, - 1000 );
    addLight( 0.995, 0.5, 0.9, 5000, 5000, - 1000 );

    controls = three.FlyControls( threeJs.camera, threeJs.globalKey);

    controls.movementSpeed = 2500;
    controls.rollSpeed = math.pi / 6;
    controls.autoForward = false;
    controls.dragToLook = false;

    threeJs.addAnimationEvent((dt){
      controls.update(dt);
    });
  }
}
