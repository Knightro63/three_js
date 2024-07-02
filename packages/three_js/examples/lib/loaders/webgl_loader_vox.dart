import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderVox extends StatefulWidget {
  
  const WebglLoaderVox({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderVox> {
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

      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width/threeJs.height, 0.01, 10 );
    threeJs.camera.position.setValues( 0.175, 0.075, 0.175 );

    threeJs.scene = three.Scene();
    threeJs.scene.add( threeJs.camera );

    // light

    final hemiLight = three.HemisphereLight( 0xcccccc, 0x444444, 0.9 );
    threeJs.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff, 0.45 );
    dirLight.position.setValues( 1.5, 3, 2.5 );
    threeJs.scene.add( dirLight );

    final dirLight2 = three.DirectionalLight( 0xffffff, 0.25 );
    dirLight2.position.setValues( - 1.5, - 3, - 2.5 );
    threeJs.scene.add( dirLight2 );

    final loader = three.VOXLoader();
    await loader.fromAsset( 'assets/models/vox/monu10.vox').then(( chunks ) {

      for (int i = 0; i < chunks!.length; i ++ ) {
        final chunk = chunks[ i ];

        // displayPalette( chunk.palette );

        final mesh = three.VOXMesh( chunk );
        mesh.scale.setScalar( 0.0015 );
        threeJs.scene.add( mesh );
      }
    } );

    // controls

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);
    controls.minDistance = .1;
    controls.maxDistance = 0.5;

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  /*
  function displayPalette( palette ) {

    const canvas = document.createElement( 'canvas' );
    canvas.width = 8;
    canvas.height = 32;
    canvas.style.position = 'absolute';
    canvas.style.top = '0';
    canvas.style.width = '100px';
    canvas.style.imageRendering = 'pixelated';
    document.body.appendChild( canvas );

    const context = canvas.getContext( '2d' );

    for ( let c = 0; c < 256; c ++ ) {

      const x = c % 8;
      const y = Math.floor( c / 8 );

      const hex = palette[ c + 1 ];
      const r = hex >> 0 & 0xff;
      const g = hex >> 8 & 0xff;
      const b = hex >> 16 & 0xff;
      context.fillStyle = `rgba(${r},${g},${b},1)`;
      context.fillRect( x, 31 - y, 1, 1 );

    }

  }
  */
}
