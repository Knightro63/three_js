import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMaterialsModified extends StatefulWidget {
  
  const WebglMaterialsModified({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglMaterialsModified> {
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
      setup: setup,    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
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

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 27, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.z = 20;

    threeJs.scene = three.Scene();

    final loader = three.GLTFLoader();
    loader.fromAsset( 'assets/models/gltf/LeePerrySmith/LeePerrySmith.glb').then(( gltf ) {
      final geometry = gltf!.scene.children[ 0 ].geometry;

      three.Mesh mesh = three.Mesh( geometry, buildTwistMaterial( 2.0 ) );
      mesh.position.x = - 3.5;
      mesh.position.y = - 0.5;
      threeJs.scene.add( mesh );

      mesh = three.Mesh( geometry, buildTwistMaterial( - 2.0 ) );
      mesh.position.x = 3.5;
      mesh.position.y = - 0.5;
      threeJs.scene.add( mesh );

    } );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 10;

    threeJs.addAnimationEvent((dt){
      controls.update();
      threeJs.scene.traverse(( child ) {
        if ( child is three.Mesh ) {
          final shader = child.material?.userData['shader'];
          if ( shader != null) {
            shader.uniforms['time']['value'] = shader.uniforms['time']['value']+dt;
          }
        }
      });
    });
  }

  three.Material buildTwistMaterial( amount ) {
    final material = three.MeshNormalMaterial();
    material.onBeforeCompile = ( shader,t ) {
      shader.uniforms['time'] = { 'value': 0.0 };
      shader.vertexShader = 'uniform float time;\n${shader.vertexShader}';
      shader.vertexShader = shader.vertexShader.replaceAll(
        '#include <begin_vertex>',
        [
          'float theta = sin( time + position.y ) / ${ (amount as double).toStringAsFixed( 1 ) };',
          'float c = cos( theta );',
          'float s = sin( theta );',
          'mat3 m = mat3( c, 0, s, 0, 1, 0, -s, 0, c );',
          'vec3 transformed = vec3( position ) * m;',
          'vNormal = vNormal * m;'
        ].join( '\n' )
      );

      material.userData['shader'] = shader;
    };

    // Make sure WebGLRenderer doesnt reuse a single program

    material.customProgramCacheKey = () {
      return (amount as double).toStringAsFixed( 1 );
    };

    return material;
  }
}
