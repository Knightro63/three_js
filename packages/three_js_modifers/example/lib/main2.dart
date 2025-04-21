import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_controls/three_js_controls.dart';
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'package:three_js_modifers/three_js_modifers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglModifierSubdivision(),
    );
  }
}

class WebglModifierSubdivision extends StatefulWidget {
  const WebglModifierSubdivision({super.key});

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
      settings: three.Settings(
        useOpenGL: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    threeJs.dispose();
    //three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  late OrbitControls controls;
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
    'wireframe': false,
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 75,threeJs.width/threeJs.height );
    threeJs.camera.position.setValues( 0, 0.7, 2.1 );

    controls = OrbitControls( threeJs.camera, threeJs.globalKey );
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

    meshNormal = three.Mesh( three.BufferGeometry(), three.MeshBasicMaterial() );
    meshSmooth = three.Mesh( three.BufferGeometry(), three.MeshBasicMaterial() );
    meshNormal.position.setValues( - 0.7, 0, 0 );
    meshSmooth.position.setValues( 0.7, 0, 0 );
    threeJs.scene.addAll([ meshNormal, meshSmooth ]);

    final wireMaterial = three.MeshBasicMaterial.fromMap( { 
      'color': 0, 
      'depthTest': true, 
      'wireframe': true 
    } );
    wireNormal = three.Mesh( three.BufferGeometry(), wireMaterial );
    wireSmooth = three.Mesh( three.BufferGeometry(), wireMaterial );
    // wireNormal.visible = false;
    // wireSmooth.visible = false;
    wireNormal.position.setFrom( meshNormal.position );
    wireSmooth.position.setFrom( meshSmooth.position );
    threeJs.scene.addAll([ wireNormal, wireSmooth] );

    updateMeshes();

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
  

  void updateMeshes() {
    final normalGeometry = three.BoxGeometry();
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

        materialParams['side'] = tmath.DoubleSide;
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

        materialParams['side'] = tmath.FrontSide;
        break;

    }

    meshNormal.material = meshSmooth.material = three.MeshStandardMaterial.fromMap( materialParams );
  }
}
