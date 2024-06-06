import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglBuffergeometryCustomAttributesParticles extends StatefulWidget {
  final String fileName;
  const WebglBuffergeometryCustomAttributesParticles({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglBuffergeometryCustomAttributesParticles> {
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
    const particles = 100000;

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width/threeJs.height, 1, 10000 );
    threeJs.camera.position.z = 300;

    threeJs.scene = three.Scene();

    final uniforms = {
      'pointTexture': { 'value': await three.TextureLoader().fromAsset( 'assets/textures/sprites/spark1.png' ) }
    };
    const vertexShader = '''
			attribute float size;

			varying vec4 vColor;

			void main() {

				vColor = vec4( color, 1.0 );
        
				vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
				gl_PointSize = size * ( 300.0 / -mvPosition.z );

				gl_Position = projectionMatrix * mvPosition;

			}
    ''';
    const fragmentShader = '''
			uniform sampler2D pointTexture;

			varying vec4 vColor;

			void main() {

				gl_FragColor = vColor;//vec4( vColor, 1.0 );

				//gl_FragColor = gl_FragColor * texture2D( pointTexture, gl_PointCoord );

			}
      ''';

    final shaderMaterial = three.ShaderMaterial.fromMap( {
      'uniforms': uniforms,
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader,
      'blending': three.AdditiveBlending,
      'depthTest': false,
      'transparent': false,
      'vertexColors': true
    });


    const radius = 200;
    final geometry = three.BufferGeometry();

    final List<double> positions = [];
    final List<double> colors = [];
    final List<double> sizes = [];
    final color = three.Color();

    for (int i = 0; i < particles; i ++ ) {
      positions.add( ( math.Random().nextDouble() * 2 - 1 ) * radius );
      positions.add( ( math.Random().nextDouble() * 2 - 1 ) * radius );
      positions.add( ( math.Random().nextDouble() * 2 - 1 ) * radius );
      color.setHSL( i / particles, 1.0, 0.5 );
      colors.addAll( [color.red, color.green, color.blue] );
      sizes.add( 20 );
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );
    geometry.setAttributeFromString( 'size', three.Float32BufferAttribute.fromList( sizes, 1 ).setUsage( three.DynamicDrawUsage ) );

    final particleSystem = three.Points( geometry, shaderMaterial );
    threeJs.scene.add( particleSystem );

    threeJs.renderer?.gl.enable(0x8642);

    threeJs.addAnimationEvent((dt){
      final time = DateTime.now().millisecondsSinceEpoch * 0.005;

      particleSystem.rotation.z = 0.01 * time;

      final sizes = geometry.attributes['size'].array;

      for (int i = 0; i < particles; i ++ ) {
        sizes[ i ] = 3 * ( 1 + math.sin( 0.1 * i + time ) );
      }
      geometry.attributes['size'].needsUpdate = true;
    });
  }
}
