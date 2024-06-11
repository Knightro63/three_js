import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglSimpleGi extends StatefulWidget {
  final String fileName;
  const WebglSimpleGi({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglSimpleGi> {
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

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 70, threeJs.width/threeJs.height, 0.1, 100 );
    threeJs.camera.position.z = 4;

    threeJs.scene = three.Scene();

    // torus knot

    final torusGeometry = TorusKnotGeometry( 0.75, 0.3, 128, 32, 1 );
    final material =three.MeshBasicMaterial.fromMap( { 'vertexColors': true } );

    final torusKnot = GIMesh( torusGeometry, material );
    threeJs.scene.add( torusKnot );

    // room
    three.BufferGeometry;
    final materials = three.GroupMaterial();

    final boxGeometry = three.BoxGeometry( 3, 3, 3 );

    for (int i = 0; i < 1; i ++ ) {
      materials.add(three.MeshBasicMaterial.fromMap({ 
        'color': (math.Random().nextDouble() * 0xffffff).toInt(), 
        'side': three.BackSide 
      }));
    }

    final box = three.Mesh( boxGeometry, materials);
    threeJs.scene.add( box );
    simpleGI(threeJs.renderer!, threeJs.scene );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 1;
    controls.maxDistance = 10;

    threeJs.rendererUpdate = compute;

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  void Function([double?])? compute;

  void simpleGI(three.WebGLRenderer renderer, three.Scene scene) {

    final SIZE = 32, SIZE2 = SIZE * SIZE;

    final camera = three.PerspectiveCamera( 90, 1, 0.01, 100 );

    scene.updateMatrixWorld( true );

    three.Object3D clone = scene.clone();
    //clone.matrixWorldAutoUpdate = false;

    final rt =three.WebGLRenderTarget( SIZE, SIZE );

    final normalMatrix = three.Matrix3.identity();

    final position = three.Vector3();
    final normal = three.Vector3();

    int bounces = 0;
    int currentVertex = 0;

    final color = Float32List( 3 );
    final three.Uint8Array buffer = three.Uint8Array( SIZE2 * 4 );

    void compute([double? dt]) {

      if ( bounces == 3 ) return;

      final object = scene.children[ 0 ]; // torusKnot
      final geometry = object.geometry;

      final attributes = geometry?.attributes;
      final positions = attributes!['position'].array;
      final normals = attributes['normal'].array;

      if ( attributes['color'] == null ) {
        final colors = Float32List( positions.length );
        geometry?.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ).setUsage( three.DynamicDrawUsage ) );
      }

      final colors = attributes['color'].array;

      final startVertex = currentVertex;
      final totalVertex = positions.length / 3;

      for (int i = 0; i < 32; i ++ ) {

        if ( currentVertex >= totalVertex ) break;

        position.fromNativeArray( positions, currentVertex * 3 );
        position.applyMatrix4( object.matrixWorld );

        normal.fromNativeArray( normals, currentVertex * 3 );
        normal.applyMatrix3( normalMatrix.getNormalMatrix( object.matrixWorld ) ).normalize();

        camera.position.setFrom( position );
        camera.lookAt( position.add( normal ) );

        renderer.setRenderTarget( rt );
        renderer.render( clone, camera );

        renderer.readRenderTargetPixels( rt, 0, 0, SIZE, SIZE, buffer );

        color[ 0 ] = 0;
        color[ 1 ] = 0;
        color[ 2 ] = 0;

        for (int k = 0, kl = buffer.length; k < kl; k += 4 ) {
          color[ 0 ] += buffer[ k + 0 ];
          color[ 1 ] += buffer[ k + 1 ];
          color[ 2 ] += buffer[ k + 2 ];
        }

        colors[ currentVertex * 3 + 0 ] = color[ 0 ] / ( SIZE2 * 255 );
        colors[ currentVertex * 3 + 1 ] = color[ 1 ] / ( SIZE2 * 255 );
        colors[ currentVertex * 3 + 2 ] = color[ 2 ] / ( SIZE2 * 255 );

        currentVertex ++;

      }

      attributes['color'].updateRange['offset'] = startVertex * 3;
      attributes['color'].updateRange['count'] = ( currentVertex - startVertex ) * 3;
      attributes['color'].needsUpdate = true;

      if ( currentVertex >= totalVertex ) {

        clone = scene.clone();
        //clone.matrixWorldAutoUpdate = false;

        bounces ++;
        currentVertex = 0;
      }
    }

    this.compute = compute;
  }
}

class GIMesh extends three.Mesh {
  GIMesh(super.geometry,super.material);

  @override
  GIMesh copy(three.Object3D source, [bool? recursive]) {
    super.copy( source );
    geometry = source.geometry?.clone();
    return this;
  }
}