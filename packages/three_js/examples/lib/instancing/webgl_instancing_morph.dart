import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglInstancingMorph extends StatefulWidget {
  final String fileName;
  const WebglInstancingMorph({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglInstancingMorph> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap: true,
        shadowMapType: three.VSMShadowMap,
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
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.AnimationMixer mixer;
  three.InstancedMesh? mesh;
  late three.Object3D dummy;

  Future<void> setup() async {
    const offset = 5000;
    final timeOffsets = Float32List( 1024 );

    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 100, 10000 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x99DDFF );
    threeJs.scene.fog = three.Fog( 0x99DDFF, 5000, 10000 );

    final light = three.DirectionalLight( 0xffffff, 1 );
    light.position.setValues( 200, 1000, 50 );

    light.castShadow = true;
    light.shadow?.camera?.left = - 5000;
    light.shadow?.camera?.right = 5000;
    light.shadow?.camera?.top = 5000;
    light.shadow?.camera?.bottom = - 5000;
    light.shadow?.camera?.far = 2000;

    light.shadow?.bias = - 0.01;
    light.shadow?.camera?.updateProjectionMatrix();
    threeJs.scene.add( light );

    final hemi = three.HemisphereLight( 0x99DDFF, 0x669933, 1 / 3 );
    threeJs.scene.add( hemi );

    final ground = three.Mesh(
      three.PlaneGeometry( 1000000, 1000000 ),
      three.MeshStandardMaterial.fromMap( { 'color': 0x669933, 'depthWrite': true } )
    );

    ground.rotation.x = - math.pi / 2;
    ground.receiveShadow = true;
    threeJs.scene.add( ground );

    final glb = await three.GLTFLoader().fromAsset( 'assets/models/gltf/Horse.gltf');

    dummy = glb!.scene.children[ 0 ];
    mesh = three.InstancedMesh( dummy.geometry, dummy.material, 1024 );
    mesh!.castShadow = true;

    for ( int x = 0, i = 0; x < 32; x ++ ) {
      for ( int y = 0; y < 32; y ++ ) {
        dummy.position.setValues( offset - 300 * x + 200.0 * math.Random().nextDouble(), 0, offset - 300.0 * y );
        dummy.updateMatrix();
        mesh!.setMatrixAt( i, dummy.matrix );
        mesh!.setColorAt( i, three.Color().setFromHSL(math.Random().nextDouble() * 360,0.5,0.66));
        i++;
      }
    }

    threeJs.scene.add( mesh );
    mixer = three.AnimationMixer( glb.scene );
    mixer.clipAction( glb.animations![ 0 ] )!.setDuration(1).play();
    

    threeJs.addAnimationEvent((dt){
      final time = threeJs.clock.getElapsedTime();

      const r = 3000;
      threeJs.camera.position.setValues( math.sin( time / 10 ) * r, 1500 + 1000 * math.cos( time / 5 ), math.cos( time / 10 ) * r );
      threeJs.camera.lookAt(three.Vector3.zero());

  
      for (int i = 0; i < 1024; i ++ ) {
        mixer.setTime( time + timeOffsets[ i ] );
        mesh!.setMorphAt( i, dummy );
      }

      mesh!.morphTexture!.needsUpdate = true;
      
    });
  }
}
