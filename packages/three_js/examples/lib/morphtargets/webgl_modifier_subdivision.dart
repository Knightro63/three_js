import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class WebglModifierSubdivision extends StatefulWidget {
  final String fileName;
  const WebglModifierSubdivision({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglModifierSubdivision> {
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
  late three.Mesh meshNormal;
  late three.Mesh meshSmooth;
  late three.Mesh wireNormal;
  late three.Mesh wireSmooth;
  three.Texture? texture;

  final Map<String,dynamic> params = {
    'geometry': 'Box',
    'iterations': 3,
    'split': true,
    'uvSmooth': false,
    'preserveEdges': false,
    'flatOnly': false,
    'maxTriangles': 25000,
    'flatShading': false,
    'textured': true,
    'wireframe': false
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 75,threeJs.width/threeJs.height );
    threeJs.camera.position.setValues( 0, 0.7, 2.1 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.rotateSpeed = 0.5;
    controls.minZoom = 1;
    controls.target.setValues( 0, 0, 0 );
    controls.update();

    threeJs.scene.add( three.HemisphereLight( 0xffffff, 0x737373, 3 ) );

    final frontLight = three.DirectionalLight( 0xffffff, 1.5 );
    final backLight = three.DirectionalLight( 0xffffff, 1.5 );
    frontLight.position.setValues( 0, 1, 1 );
    backLight.position.setValues( 0, 1, - 1 );
    threeJs.scene.addAll( [frontLight, backLight] );

    texture = await three.TextureLoader().fromAsset( 'assets/textures/uv_grid_opengl.jpg');

    texture?.wrapS = three.RepeatWrapping;
    texture?.wrapT = three.RepeatWrapping;
    texture?.colorSpace = three.SRGBColorSpace;

    meshNormal = three.Mesh( three.BufferGeometry(), three.MeshBasicMaterial() );
    meshSmooth = three.Mesh( three.BufferGeometry(), three.MeshBasicMaterial() );
    meshNormal.position.setValues( - 0.7, 0, 0 );
    meshSmooth.position.setValues( 0.7, 0, 0 );
    threeJs.scene.addAll([ meshNormal, meshSmooth ]);

    final wireMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xffffff, 'depthTest': true, 'wireframe': true } );
    wireNormal = three.Mesh( three.BufferGeometry(), wireMaterial );
    wireSmooth = three.Mesh( three.BufferGeometry(), wireMaterial );
    wireNormal.visible = false;
    wireSmooth.visible = false;
    wireNormal.position.setFrom( meshNormal.position );
    wireSmooth.position.setFrom( meshSmooth.position );
    threeJs.scene.addAll([ wireNormal, wireSmooth] );

    updateMeshes();

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  three.BufferGeometry getGeometry() {
    switch ( params['geometry'].toLowerCase() ) {
      case 'box':
        return three.BoxGeometry();
      case 'capsule':
        return CapsuleGeometry(radius: 0.5, length: 0.5, capSegments: 3,radialSegments: 5 );
      case 'circle':
        return CircleGeometry( radius: 0.6, segments: 10 );
      case 'cone':
        return ConeGeometry( 0.6, 1.5, 5, 3 );
      case 'cylinder':
        return CylinderGeometry( 0.5, 0.5, 1, 5, 4 );
      case 'dodecahedron':
        return DodecahedronGeometry( 0.6 );
      case 'icosahedron':
        return IcosahedronGeometry( 0.6 );
      case 'lathe':
        final List<three.Vector2> points = [];

        for (int i = 0; i < 65; i += 5 ) {
          final x = ( math.sin( i * 0.2 ) * math.sin( i * 0.1 ) * 15 + 50 ) * 1.2;
          final y = ( i - 5 ) * 3;
          points.add( three.Vector2( x * 0.0075, y * 0.005 ) );
        }

        final latheGeometry = LatheGeometry( points, segments: 4 );
        latheGeometry.center();

        return latheGeometry;
      case 'octahedron':
        return OctahedronGeometry( 0.7 );
      case 'plane':
        return three.PlaneGeometry();
      case 'ring':
        return RingGeometry( 0.3, 0.6, 10 );
      case 'sphere':
        return three.SphereGeometry( 0.6, 8, 4 );
      case 'tetrahedron':
        return TetrahedronGeometry( 0.8 );
      case 'torus':
        return TorusGeometry( 0.48, 0.24, 4, 6 );
      default:
        return TorusKnotGeometry( 0.38, 0.18, 20, 4 );
    }
  }

  void updateMeshes() {
    final normalGeometry = getGeometry();
    final smoothGeometry = LoopSubdivision.modify(
      normalGeometry, 
      params['iterations'], 
      LoopParameters.fromJson(params)
    );

    meshNormal.geometry?.dispose();
    meshSmooth.geometry?.dispose();
    meshNormal.geometry = normalGeometry;
    meshSmooth.geometry = smoothGeometry;

    wireNormal.geometry?.dispose();
    wireSmooth.geometry?.dispose();
    wireNormal.geometry = normalGeometry.clone();
    wireSmooth.geometry = smoothGeometry.clone();

    updateMaterial();
  }

  void disposeMaterial(three.Material? material ) {
    final materials = material is three.GroupMaterial ? material.children : [material];
    for (int i = 0; i < materials.length; i ++ ) {
      materials[ i ]?.dispose();
    }
  }

  void updateMaterial() {

    disposeMaterial( meshNormal.material );
    disposeMaterial( meshSmooth.material );

    final materialParams = {
      'color': ( params['textured'] ) ? 0xffffff : 0x808080,
      'flatShading': params['flatShading'],
      'map': ( params['textured'] ) ? texture : null,
      'polygonOffset': true,
      'polygonOffsetFactor': 1, // positive value pushes polygon further away
      'polygonOffsetUnits': 1
    };

    switch ( params['geometry'].toLowerCase() ) {

      case 'circle':
      case 'lathe':
      case 'plane':
      case 'ring':

        materialParams['side'] = three.DoubleSide;
        break;

      case 'box':
      case 'capsule':
      case 'cone':
      case 'cylinder':
      case 'dodecahedron':
      case 'icosahedron':
      case 'octahedron':
      case 'sphere':
      case 'tetrahedron':
      case 'torus':
      case 'torusknot':

        materialParams['side'] = three.FrontSide;
        break;

    }

    meshNormal.material = meshSmooth.material = three.MeshStandardMaterial.fromMap( materialParams );
  }
}
