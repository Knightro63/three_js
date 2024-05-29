import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglInstancingScatter extends StatefulWidget {
  final String fileName;
  const WebglInstancingScatter({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglInstancingScatter> {
  late three.ThreeJS threeJs;
  late CSM csm;

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
    controls.clearListeners();
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

  late three.OrbitControls controls;
  late three.BufferGeometry stemGeometry;
  late three.BufferGeometry blossomGeometry;
  late three.Material stemMaterial;
  late three.Material blossomMaterial;
  late three.InstancedMesh stemMesh;
  late three.InstancedMesh blossomMesh;
  final count = 2000;
  final dummy = three.Object3D();

  final ages = Float32List( 2000 );
  final scales = Float32List( 2000 );

  final _position = three.Vector3();
  final _normal = three.Vector3();
  final _scale = three.Vector3();

  late three.Mesh surface;
  late MeshSurfaceSampler sampler;

  double easeOutCubic(double t ) {
    return ( -- t ) * t * t + 1;
  }
  double scaleCurve(double t ) {
    return easeOutCubic( ( t > 0.5 ? 1 - t : t ) * 2 ).abs();
  }

  Future<void> setup() async {
    final surfaceGeometry = TorusKnotGeometry( 10, 3, 100, 16 ).toNonIndexed();
    final surfaceMaterial = three.MeshLambertMaterial.fromMap( { 'color': 0xFFF784, 'wireframe': false } );
		surface = three.Mesh( surfaceGeometry, surfaceMaterial );

    final loader = three.GLTFLoader();

    await loader.fromAsset( 'assets/models/gltf/Flower/Flower.glb').then(( gltf ) {

      final _stemMesh = gltf!.scene.getObjectByName( 'Stem' );
      final _blossomMesh = gltf.scene.getObjectByName( 'Blossom' );

      stemGeometry = _stemMesh!.geometry!.clone();
      blossomGeometry = _blossomMesh!.geometry!.clone();

      final defaultTransform = three.Matrix4()
        .makeRotationX( math.pi )
        .multiply( three.Matrix4().makeScale( 7, 7, 7 ) );

      stemGeometry.applyMatrix4( defaultTransform );
      blossomGeometry.applyMatrix4( defaultTransform );

      stemMaterial = _stemMesh.material!;
      blossomMaterial = _blossomMesh.material!;

      stemMesh = three.InstancedMesh( stemGeometry, stemMaterial, count );
      blossomMesh = three.InstancedMesh( blossomGeometry, blossomMaterial, count );

      // Assign random colors to the blossoms.
      final color = three.Color();
      final blossomPalette = [ 0xF20587, 0xF2D479, 0xF2C879, 0xF2B077, 0xF24405 ];

      for (int i = 0; i < count; i ++ ) {
        color.setFromHex32( blossomPalette[ ( math.Random().nextDouble() * blossomPalette.length ).floor() ] );
        blossomMesh.setColorAt( i, color );
      }

      // Instance matrices will be updated every frame.
      stemMesh.instanceMatrix?.setUsage( three.DynamicDrawUsage );
      blossomMesh.instanceMatrix?.setUsage( three.DynamicDrawUsage );

      resample();

      init().then((e){
        threeJs.addAnimationEvent((dt){
          controls.update();
          render();
        });
      });
    });
  }
  Future<void> init() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 25, 25, 25 );
    threeJs.camera.lookAt(three.Vector3( 0, 0, 0 ));

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xE39469 );

    final pointLight = three.PointLight( 0xAA8899, 2.5, 0, 0 );
    pointLight.position.setValues( 50, - 25, 75 );
    threeJs.scene.add( pointLight );

    threeJs.scene.add( three.AmbientLight( 0xffffff, 0.8 ) );

    threeJs.scene.add( stemMesh );
    threeJs.scene.add( blossomMesh );
    threeJs.scene.add( surface );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
  }

  void resample() {

    final vertexCount = surface.geometry?.getAttributeFromString( 'position' ).count;

    three.console.info( 'Sampling $count points from a surface with $vertexCount vertices...' );

    sampler = MeshSurfaceSampler( surface )
      .setWeightAttribute('random' == 'weighted' ? 'uv' : null )
      .build();

    for (int i = 0; i < count; i ++ ) {
      ages[ i ] = math.Random().nextDouble();
      scales[ i ] = scaleCurve( ages[ i ] );
      resampleParticle( i );
    }

    stemMesh.instanceMatrix?.needsUpdate = true;
    blossomMesh.instanceMatrix?.needsUpdate = true;
  }

  void resampleParticle( i ) {
    sampler.sample( _position, _normal );
    _normal.add( _position );

    dummy.position.setFrom( _position );
    dummy.scale.setValues( scales[ i ], scales[ i ], scales[ i ] );
    dummy.lookAt( _normal );
    dummy.updateMatrix();

    stemMesh.setMatrixAt( i, dummy.matrix );
    blossomMesh.setMatrixAt( i, dummy.matrix );
  }

  void updateParticle(int i ) {
    ages[ i ] += 0.005;

    if ( ages[ i ] >= 1 ) {
      ages[ i ] = 0.001;
      scales[ i ] = scaleCurve( ages[ i ] );
      resampleParticle( i );
      return;
    }

    // Update scale.

    final prevScale = scales[ i ];
    scales[ i ] = scaleCurve( ages[ i ] );
    _scale.setValues( scales[ i ] / prevScale, scales[ i ] / prevScale, scales[ i ] / prevScale );

    // Update transform.

    stemMesh.getMatrixAt( i, dummy.matrix );
    dummy.matrix.scaleByVector( _scale );
    stemMesh.setMatrixAt( i, dummy.matrix );
    blossomMesh.setMatrixAt( i, dummy.matrix );
  }

  void render() {
    final time = DateTime.now().millisecondsSinceEpoch * 0.001;

    threeJs.scene.rotation.x = math.sin( time / 4 );
    threeJs.scene.rotation.y = math.sin( time / 2 );

    for ( int i = 0; i < count; i ++ ) {
      updateParticle( i );
    }

    stemMesh.instanceMatrix?.needsUpdate = true;
    blossomMesh.instanceMatrix?.needsUpdate = true;

    stemMesh.computeBoundingSphere();
    blossomMesh.computeBoundingSphere();
  }
}
