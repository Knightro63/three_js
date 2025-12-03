import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';

class WebglVolumePerlin extends StatefulWidget {
  
  const WebglVolumePerlin({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglVolumePerlin> {
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
      windowResizeUpdate: (newSize){
				threeJs.camera.aspect = newSize.width / newSize.height;
				threeJs.camera.updateProjectionMatrix();
      }
    );
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
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 0, 2 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );

    // Texture

    const size = 128;
    final data = three.Uint8Array( size * size * size );

    int i = 0;
    final perlin = ImprovedNoise();
    final vector = three.Vector3();

    for ( int z = 0; z < size; z ++ ) {
      for ( int y = 0; y < size; y ++ ) {
        for ( int x = 0; x < size; x ++ ) {
          vector.setValues( x.toDouble(), y.toDouble(), z.toDouble()).divideScalar( size );
          final d = perlin.noise( vector.x * 6.5, vector.y * 6.5, vector.z * 6.5 );
          data[i++] = (d * 128 + 128).toInt();
        }
      }
    }

    final texture = three.Data3DTexture( data, size, size, size );
    texture.format = three.RedFormat;
    texture.minFilter = three.LinearFilter;
    texture.magFilter = three.LinearFilter;
    texture.unpackAlignment = 1;
    texture.needsUpdate = true;

    // Material

    const vertexShader = /* glsl */'''
      in vec3 position;

      uniform mat4 modelMatrix;
      uniform mat4 modelViewMatrix;
      uniform mat4 projectionMatrix;
      uniform vec3 cameraPos;

      out vec3 vOrigin;
      out vec3 vDirection;

      void main() {
        vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );

        vOrigin = vec3( inverse( modelMatrix ) * vec4( cameraPos, 1.0 ) ).xyz;
        vDirection = position - vOrigin;

        gl_Position = projectionMatrix * mvPosition;
      }
    ''';

    const fragmentShader = /* glsl */'''
      precision highp float;
      precision highp sampler3D;

      uniform mat4 modelViewMatrix;
      uniform mat4 projectionMatrix;

      in vec3 vOrigin;
      in vec3 vDirection;

      out vec4 color;

      uniform sampler3D map;

      uniform float threshold;
      uniform float steps;

      vec2 hitBox( vec3 orig, vec3 dir ) {
        const vec3 box_min = vec3( - 0.5 );
        const vec3 box_max = vec3( 0.5 );
        vec3 inv_dir = 1.0 / dir;
        vec3 tmin_tmp = ( box_min - orig ) * inv_dir;
        vec3 tmax_tmp = ( box_max - orig ) * inv_dir;
        vec3 tmin = min( tmin_tmp, tmax_tmp );
        vec3 tmax = max( tmin_tmp, tmax_tmp );
        float t0 = max( tmin.x, max( tmin.y, tmin.z ) );
        float t1 = min( tmax.x, min( tmax.y, tmax.z ) );
        return vec2( t0, t1 );
      }

      float sample1( vec3 p ) {
        return texture( map, p ).r;
      }

      #define epsilon .0001

      vec3 normal( vec3 coord ) {
        if ( coord.x < epsilon ) return vec3( 1.0, 0.0, 0.0 );
        if ( coord.y < epsilon ) return vec3( 0.0, 1.0, 0.0 );
        if ( coord.z < epsilon ) return vec3( 0.0, 0.0, 1.0 );
        if ( coord.x > 1.0 - epsilon ) return vec3( - 1.0, 0.0, 0.0 );
        if ( coord.y > 1.0 - epsilon ) return vec3( 0.0, - 1.0, 0.0 );
        if ( coord.z > 1.0 - epsilon ) return vec3( 0.0, 0.0, - 1.0 );

        float step = 0.01;
        float x = sample1( coord + vec3( - step, 0.0, 0.0 ) ) - sample1( coord + vec3( step, 0.0, 0.0 ) );
        float y = sample1( coord + vec3( 0.0, - step, 0.0 ) ) - sample1( coord + vec3( 0.0, step, 0.0 ) );
        float z = sample1( coord + vec3( 0.0, 0.0, - step ) ) - sample1( coord + vec3( 0.0, 0.0, step ) );

        return normalize( vec3( x, y, z ) );
      }

      void main(){
        color = vec4(0.0); // Explicitly initialize color
        
        vec3 rayDir = normalize( vDirection );
        vec2 bounds = hitBox( vOrigin, rayDir );

        if ( bounds.x > bounds.y ) discard;

        bounds.x = max( bounds.x, 0.0 );

        vec3 p = vOrigin + bounds.x * rayDir;
        vec3 inc = 1.0 / abs( rayDir );
        float delta = min( inc.x, min( inc.y, inc.z ) );
        delta /= steps;

        for ( float t = bounds.x; t < bounds.y; t += delta ) {

          float d = sample1( p + 0.5 );

          if ( d > threshold ) {

            color.rgb = normal( p + 0.5 ) * 0.5 + ( p * 1.5 + 0.25 );
            color.a = 1.;
            break;

          }

          p += rayDir * delta;

        }

        if ( color.a == 0.0 ) discard;
      }
    ''';

    final geometry = three.BoxGeometry( 1, 1, 1 );
    final material = three.RawShaderMaterial.fromMap({
      'glslVersion':three.GLSL3,
      'uniforms': {
        'map': { 'value': texture },
        'cameraPos': { 'value': three.Vector3() },
        'threshold': { 'value': 0.6 },
        'steps': { 'value': 200 }
      },
      'vertexShader':vertexShader,
      'fragmentShader':fragmentShader,
      'side': three.BackSide,
    } );

    final mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    threeJs.addAnimationEvent((dt){
      mesh.material?.uniforms['cameraPos']['value'].setFrom( threeJs.camera.position );
      controls.update();
    });
  }
}
