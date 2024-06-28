import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglCustomAttributesLines extends StatefulWidget {
  final String fileName;
  const WebglCustomAttributesLines({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglCustomAttributesLines> {
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

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 30, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.z = 400;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x050505 );

    final Map<String,dynamic> uniforms = {
      'amplitude': { 'value': 5.0 },
      'opacity': { 'value': 0.3 },
      'color': { 'value': three.Color( 0xffffff ) }
    };

    const vertexShader = '''
			uniform float amplitude;

			attribute vec3 displacement;
			attribute vec3 customColor;

			varying vec3 vColor;

			void main() {

				vec3 newPosition = position + amplitude * displacement;

				vColor = customColor;

				gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );

			}
    ''';
    const fragmentShader = '''
			uniform vec3 color;
			uniform float opacity;

			varying vec3 vColor;

			void main() {

				gl_FragColor = vec4( vColor * color, opacity );

			}
    ''';

    final shaderMaterial = three.ShaderMaterial.fromMap( {
      'uniforms': uniforms,
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader,
      'blending': three.AdditiveBlending,
      'depthTest': false,
      'transparent': true
    } );

		final loader = three.FontLoader();
    final font = await loader.fromAsset( 'assets/helvetiker_bold.typeface.json');
    final geometry = three.TextGeometry( 'three.js', three.TextGeometryOptions(
      font: font,
      size: 50,
      depth: 15,
      curveSegments: 10,
      bevelThickness: 5,
      bevelSize: 1.5,
      bevelEnabled: true,
      bevelSegments: 10,
    ));

    geometry.center();

    final count = geometry.attributes['position'].count;
    final displacement = three.Float32BufferAttribute(three.Float32Array( count * 3), 3 );
    geometry.setAttributeFromString( 'displacement', displacement );

    final customColor = three.Float32BufferAttribute(three.Float32Array( count * 3), 3 );
    geometry.setAttributeFromString( 'customColor', customColor );

    final color = three.Color( 0xffffff );

    for (int i = 0, l = customColor.count; i < l; i ++ ) {
      color.setHSL( i / l, 0.5, 0.5 );
      color.copyIntoArray( customColor.array, i * customColor.itemSize );
    }

    final line = three.Line( geometry, shaderMaterial );
    line.rotation.x = 0.2;
    threeJs.scene.add( line );

    threeJs.addAnimationEvent((dt){
      final time = DateTime.now().millisecondsSinceEpoch * 0.001;

      line.rotation.y = 0.25 * time;

      uniforms['amplitude']!['value'] = math.sin( 0.5 * time );
      (uniforms['color']!['value'] as three.Color).offsetHSL( 0.0005, 0, 0 );

      final attributes = line.geometry!.attributes;
      final array = attributes['displacement'].array;

      for (int i = 0, l = array.length; i < l; i += 3 ) {
        array[ i ] += 0.3 * ( 0.5 - math.Random().nextDouble() );
        array[ i + 1 ] += 0.3 * ( 0.5 - math.Random().nextDouble() );
        array[ i + 2 ] += 0.3 * ( 0.5 - math.Random().nextDouble() );
      }

      attributes['displacement'].needsUpdate = true;
    });
  }
}
