import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_modifers/three_js_modifers.dart';

class WebglModifierTessellation extends StatefulWidget {
  const WebglModifierTessellation({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglModifierTessellation> {
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
        useOpenGL: useOpenGL
      )
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

  late final three.Mesh mesh;
  late final three.TrackballControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.setValues( - 100, 100, 200 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x050505 );

		final loader = three.FontLoader();
    final font  = await loader.fromAsset( 'assets/helvetiker_bold.typeface.json');

    final textG = three.TextGeometry( 'THREE.JS', three.TextGeometryOptions(
      font: font,
      size: 40,
      depth: 5,
      curveSegments: 3,
      bevelThickness: 2,
      bevelSize: 1,
      bevelEnabled: true
    ));

    textG.center();

    final tessellateModifier = TessellateModifier( 8, 6 );
    final geometry = tessellateModifier.modify( textG );

    final numFaces = geometry.attributes['position'].count ~/ 3;
    final colors = three.Float32Array( numFaces * 3 * 3 );
    final displacement = three.Float32Array( numFaces * 3 * 3 );
    final color = three.Color();

    for (int f = 0; f < numFaces; f ++ ) {
      final index = 9 * f;
      final h = 0.2 * math.Random().nextDouble();
      final s = 0.5 + 0.5 * math.Random().nextDouble();
      final l = 0.5 + 0.5 * math.Random().nextDouble();

      color.setHSL( h, s, l );

      final d = 10 * ( 0.5 - math.Random().nextDouble() );

      for (int i = 0; i < 3; i ++ ) {
        colors[ index + ( 3 * i ) ] = color.red;
        colors[ index + ( 3 * i ) + 1 ] = color.green;
        colors[ index + ( 3 * i ) + 2 ] = color.blue;

        displacement[ index + ( 3 * i ) ] = d;
        displacement[ index + ( 3 * i ) + 1 ] = d;
        displacement[ index + ( 3 * i ) + 2 ] = d;
      }
    }

    geometry.setAttributeFromString( 'customColor', three.Float32BufferAttribute( colors, 3 ) );
    geometry.setAttributeFromString( 'displacement', three.Float32BufferAttribute( displacement, 3 ) );

    final uniforms = {
      'amplitude': { 'value': 0.0 }
    };

    final shaderMaterial = three.ShaderMaterial.fromMap( {
      'uniforms': uniforms,
      'vertexShader': '''
        uniform float amplitude;

        attribute vec3 customColor;
        attribute vec3 displacement;

        varying vec3 vNormal;
        varying vec3 vColor;

        void main() {

          vNormal = normal;
          vColor = customColor;

          vec3 newPosition = position + normal * amplitude * displacement;
          gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );

        }
      ''',
      'fragmentShader': '''
        varying vec3 vNormal;
        varying vec3 vColor;

        void main() {

          const float ambient = 0.4;

          vec3 light = vec3( 1.0 );
          light = normalize( light );

          float directional = max( dot( vNormal, light ), 0.0 );

          gl_FragColor = vec4( ( directional + ambient ) * vColor, 1.0 );

        }
      '''
    });

    //
    mesh = three.Mesh( geometry, shaderMaterial );
    threeJs.scene.add( mesh );

    controls = three.TrackballControls( threeJs.camera, threeJs.globalKey);

    threeJs.addAnimationEvent((dt){
			final time = DateTime.now().millisecondsSinceEpoch * 0.001;
			uniforms['amplitude']!['value'] = 1.0 + math.sin( time * 0.5 );
      controls.update();
    });
  }
}
