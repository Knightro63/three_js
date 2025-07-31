import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_modifers/buffergeometry_utils.dart';

class WebglGeometryConvex extends StatefulWidget {
  const WebglGeometryConvex({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometryConvex> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late final three.OrbitControls controls;

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
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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

  Future<void> setup() async {
      threeJs.scene = three.Scene();

      // camera

      threeJs.camera = three.PerspectiveCamera( 40,threeJs.width / threeJs.height, 1, 1000 );
      threeJs.camera.position.setValues( 15, 20, 30 );
      threeJs.scene.add( threeJs.camera );

      // controls

      controls =  three.OrbitControls( threeJs.camera, threeJs.globalKey );
      controls.minDistance = 20;
      controls.maxDistance = 50;
      controls.maxPolarAngle = math.pi / 2;

      // ambient light

      threeJs.scene.add( three.AmbientLight( 0x666666 ) );

      // point light

      final light = three.PointLight( 0xffffff, 0.3, 0, 0 );
      threeJs.camera.add( light );

      // helper

      threeJs.scene.add( AxesHelper( 20 ) );

      // textures

      final loader = three.TextureLoader();
      final texture = await loader.fromAsset( 'assets/textures/sprites/disc.png' );
      //texture.colorSpace = three.SRGBColorSpace;

      final group = three.Group();
      threeJs.scene.add( group );

      // points

      final ddg = DodecahedronGeometry( 10 );

      // if normal and uv attributes are not removed, mergeVertices() can't consolidate indentical vertices with different normal/uv data

      ddg.deleteAttributeFromString( 'normal' );
      ddg.deleteAttributeFromString( 'uv' );

      final dodecahedronGeometry = BufferGeometryUtils.mergeVertices( ddg );

      final List<three.Vector3> vertices = [];
      final positionAttribute = dodecahedronGeometry.getAttributeFromString( 'position' );

      for ( int i = 0; i < positionAttribute.count; i ++ ) {
        final vertex = three.Vector3();
        vertex.fromBuffer( positionAttribute, i );
        vertices.add( vertex );
      }

      final pointsMaterial = three.PointsMaterial.fromMap( {
        'color': 0x0080ff,
        'map': texture,
        'size': 1,
        'alphaTest': 0.5
      } );

      final pointsGeometry = three.BufferGeometry().setFromPoints( vertices );

      final points = three.Points( pointsGeometry, pointsMaterial );
      group.add( points );

      // convex hull

      final meshMaterial = three.MeshLambertMaterial.fromMap( {
        'color': 0xffffff,
        'opacity': 0.5,
        'side': three.DoubleSide,
        'transparent': true
      } );

      final meshGeometry = ConvexGeometry( vertices );

      final mesh = three.Mesh( meshGeometry, meshMaterial );
      group.add( mesh );
  }
}
