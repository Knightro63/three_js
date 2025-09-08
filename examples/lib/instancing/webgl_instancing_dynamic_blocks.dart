import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart' as al;

class WebglInstancingDynamicBlocks extends StatefulWidget {
  
  const WebglInstancingDynamicBlocks({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglInstancingDynamicBlocks> {
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
      onSetupComplete: (){setState(() {});},
      setup: setup,      
      settings: three.Settings(
        toneMapping: three.NeutralToneMapping,
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    colors.clear();
    seeds.clear();
    baseColors.clear();
    dummy.dispose();
    mesh.dispose();
    animation.clear();
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

  final Map<String,dynamic> animation = { 't': 0 };
  int currentColorIndex = 0;
  int nextColorIndex = 1;
  final maxDistance = 75;
  final cameraTarget = three.Vector3();

  double amount = 40;
  late final count = math.pow( amount, 3 ).toInt();
  late three.InstancedMesh mesh;
  final dummy = three.Object3D();
  final List<double> seeds = [];
  final List<int> baseColors = [];

  final three.Color color = three.Color();
  final colors = [ three.Color.fromHex32( 0x00ffff ), three.Color.fromHex32( 0xffff00 ), three.Color.fromHex32( 0xff00ff ) ];

  late final al.Tween tween;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 10, 10, 10 );
    threeJs.camera.lookAt( three.Vector3(0, 0, 0) );

    final pmremGenerator = three.PMREMGenerator( threeJs.renderer! );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xadd8e6 );
    threeJs.scene.environment = pmremGenerator.fromScene( RoomEnvironment(), sigma: 0.04 ).texture;

    final loader = three.TextureLoader();
    final texture = await loader.fromAsset( 'assets/textures/edge3.jpg' );
    texture?.colorSpace = three.SRGBColorSpace;

    final geometry = three.BoxGeometry();
    final material = three.MeshStandardMaterial.fromMap( { 'map': texture } );

    mesh = three.InstancedMesh( geometry, material, count );
    mesh.instanceMatrix?.setUsage( three.DynamicDrawUsage ); // will be updated every frame
    threeJs.scene.add( mesh );

    int i = 0;
    final offset = ( amount - 1 ) / 2;

    for (int x = 0; x < amount; x ++ ) {
      for (int z = 0; z < amount; z ++ ) {
        dummy.position.setValues( offset - x, 0, offset - z );
        dummy.scale.setValues( 1, 2, 1 );

        dummy.updateMatrix();

        color.setHSL( 1, 0.5 + ( math.Random().nextDouble() * 0.5 ), 0.5 + ( math.Random().nextDouble() * 0.5 ) );
        baseColors.add( color.getHex() );

        mesh.setMatrixAt( i, dummy.matrix );
        mesh.setColorAt( i, color.multiply( colors[ 0 ] ) );

        i ++;

        seeds.add( math.Random().nextDouble() );
      }
    }

    startTween();
    threeJs.addAnimationEvent((dt){
      render();
    });

  }

  startTween() {
    tween = al.Tween( animation )
      .to({'t': 1}, 2000 )
      .easing( al.Easing.Sinusoidal[al.ETTypes.In] );

      tween.onComplete( (t){
        animation['t'] = 0;
        currentColorIndex = nextColorIndex;
        nextColorIndex ++;
        if ( nextColorIndex >= colors.length ) nextColorIndex = 0;
        
      } ).start();
  }

  void render() {
    final time = threeJs.clock.getElapsedTime();
    tween.update();
    //print(d);
    // animate camera

    threeJs.camera.position.x = math.sin( time / 4 ) * 10;
    threeJs.camera.position.z = math.cos( time / 4 ) * 10;
    threeJs.camera.position.y = 8 + math.cos( time / 2 ) * 2;

    cameraTarget.x = math.sin( time / 4 ) * - 8;
    cameraTarget.z = math.cos( time / 2 ) * - 8;

    threeJs.camera.lookAt( cameraTarget );

    threeJs.camera.up.x = math.sin( time / 400 );

    // animate instance positions and colors

    for (int i = 0; i < (mesh.count ?? 0); i ++ ) {
      mesh.getMatrixAt( i, dummy.matrix );
      dummy.matrix.decompose( dummy.position, dummy.quaternion, dummy.scale );
      int j = i;
      if(j >= seeds.length){
        int k = j~/seeds.length;
        j -= seeds.length*k;
      }

      dummy.position.y = ( math.sin( ( time + seeds[ j ] ) * 2 + seeds[ j ] ) ).abs();
      dummy.updateMatrix();
      mesh.setMatrixAt( i, dummy.matrix );

      // colors
      if ( animation['t'] > 0 ) {
        final currentColor = colors[ currentColorIndex ];
        final nextColor = colors[ nextColorIndex ];
        final f = dummy.position.length / maxDistance;

        if ( f <= animation['t'] ) {
          color..setFromHex32( baseColors[ j ] )..multiply( nextColor );
        } 
        else {
          color..setFromHex32( baseColors[ j ] )..multiply( currentColor );
        }

        mesh.setColorAt( i, color );
      }
    }
    
    if(!tween.isPlaying()){
      tween.resume();
    }

    mesh.instanceMatrix?.needsUpdate = true;
    if ( animation['t'] > 0 ) mesh.instanceColor?.needsUpdate = true;
  
    mesh.computeBoundingSphere();
  }
}
