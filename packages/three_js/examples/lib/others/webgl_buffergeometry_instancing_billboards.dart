import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglBuffergeometryInstancingBillboards extends StatefulWidget {
  final String fileName;
  const WebglBuffergeometryInstancingBillboards({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglBuffergeometryInstancingBillboards> {
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
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 1, 5000 );
    threeJs.camera.position.z = 1400;

    threeJs.scene = three.Scene();

    final circleGeometry = CircleGeometry(radius:  1, segments:  6 );

    final geometry = three.InstancedBufferGeometry();
    geometry.index = circleGeometry.index;
    geometry.attributes = circleGeometry.attributes;

    const particleCount = 75000;

    final translateArray = three.Float32Array( particleCount * 3 );

    for ( int i = 0, i3 = 0, l = particleCount; i < l; i ++, i3 += 3 ) {
      translateArray[ i3 + 0 ] = math.Random().nextDouble() * 2 - 1;
      translateArray[ i3 + 1 ] = math.Random().nextDouble() * 2 - 1;
      translateArray[ i3 + 2 ] = math.Random().nextDouble() * 2 - 1;
    }

    geometry.setAttributeFromString( 'translate', three.InstancedBufferAttribute( translateArray, 3 ) );
    const vertexShader = '''
      precision highp float;
      uniform mat4 modelViewMatrix;
      uniform mat4 projectionMatrix;
      uniform float time;

      attribute vec3 position;
      attribute vec2 uv;
      attribute vec3 translate;

      varying vec2 vUv;
      varying float vScale;

      void main() {

        vec4 mvPosition = modelViewMatrix * vec4( translate, 1.0 );
        vec3 trTime = vec3(translate.x + time,translate.y + time,translate.z + time);
        float scale =  sin( trTime.x * 2.1 ) + sin( trTime.y * 3.2 ) + sin( trTime.z * 4.3 );
        vScale = scale;
        scale = scale * 10.0 + 10.0;
        mvPosition.xyz += position * scale;
        vUv = uv;
        gl_Position = projectionMatrix * mvPosition;

      }
    ''';
    const fragmentShader = '''
      precision highp float;

      uniform sampler2D map;

      varying vec2 vUv;
      varying float vScale;

      // HSL to RGB Convertion helpers
      vec3 HUEtoRGB(float H){
        H = mod(H,1.0);
        float R = abs(H * 6.0 - 3.0) - 1.0;
        float G = 2.0 - abs(H * 6.0 - 2.0);
        float B = 2.0 - abs(H * 6.0 - 4.0);
        return clamp(vec3(R,G,B),0.0,1.0);
      }

      vec3 HSLtoRGB(vec3 HSL){
        vec3 RGB = HUEtoRGB(HSL.x);
        float C = (1.0 - abs(2.0 * HSL.z - 1.0)) * HSL.y;
        return (RGB - 0.5) * C + HSL.z;
      }

      void main() {
        vec4 diffuseColor = texture2D( map, vUv );
        gl_FragColor = vec4( diffuseColor.xyz * HSLtoRGB(vec3(vScale/5.0, 1.0, 0.5)), diffuseColor.w );

        if ( diffuseColor.w < 0.5 ) discard;
      }
    ''';

    final material = three.RawShaderMaterial.fromMap( {
      'uniforms': {
        'map': { 'value': await three.TextureLoader().fromAsset( 'assets/textures/sprites/circle.png' ) },
        'time': { 'value': 0.0 }
      },
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader,
      'depthTest': true,
      'depthWrite': true
    } );

    final mesh = three.Mesh( geometry, material );
    mesh.scale.setValues( 500, 500, 500 );
    threeJs.scene.add( mesh );

    threeJs.addAnimationEvent((dt){
			final time = DateTime.now().millisecondsSinceEpoch * 0.0005;
			material.uniforms[ 'time' ]['value'] = material.uniforms[ 'time' ]['value']+dt;
			mesh.rotation.x = time * 0.2;
			mesh.rotation.y = time * 0.4;
    });
  }
}
