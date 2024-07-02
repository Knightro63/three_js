import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglVolumeInstancing extends StatefulWidget {
  
  const WebglVolumeInstancing({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglVolumeInstancing> {
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

      body: threeJs.build()
    );
  }

  late three.OrbitControls controls ;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width/threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 0, 0, 4 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.autoRotate = true;
    controls.autoRotateSpeed = - 1.0;
    controls.enableDamping = true;

    // Material

    const vertexShader = /* glsl */'''
      in vec3 position;
      in mat4 instanceMatrix;

      uniform mat4 modelMatrix;
      uniform mat4 modelViewMatrix;
      uniform mat4 projectionMatrix;
      uniform vec3 cameraPos;

      out vec3 vOrigin;
      out vec3 vDirection;

      void main() {
        vec4 mvPosition = modelViewMatrix * instanceMatrix * vec4( position, 1.0 );

        vOrigin = vec3( inverse( instanceMatrix * modelMatrix ) * vec4( cameraPos, 1.0 ) ).xyz;
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

        vec3 rayDir = normalize( vDirection );
        vec2 bounds = hitBox( vOrigin, rayDir );

        if ( bounds.x > bounds.y ) discard;

        bounds.x = max( bounds.x, 0.0 );

        vec3 p = vOrigin + bounds.x * rayDir;
        vec3 inc = 1.0 / abs( rayDir );
        float delta = min( inc.x, min( inc.y, inc.z ) );
        delta /= 50.0;

        for ( float t = bounds.x; t < bounds.y; t += delta ) {

          float d = sample1( p + 0.5 );

          if ( d > 0.5 ) {

            color.rgb = p * 2.0; // normal( p + 0.5 ); // * 0.5 + ( p * 1.5 + 0.25 );
            color.a = 1.;
            break;

          }

          p += rayDir * delta;

        }

        if ( color.a == 0.0 ) discard;

      }
    ''';

    final loader = three.VOXLoader();
    loader.fromAsset( 'assets/models/vox/menger.vox').then(( chunks ) {

      for (int i = 0; i < chunks!.length; i ++ ) {

        final chunk = chunks[ i ];

        final geometry = three.BoxGeometry( 1, 1, 1 );
        final material = three.RawShaderMaterial.fromMap( {
          'glslVersion': three.GLSL3,
          'uniforms': {
            'map': { 'value': three.VOXData3DTexture( chunk ) },
            'cameraPos': { 'value': three.Vector3() }
          },
          'vertexShader':vertexShader,
          'fragmentShader':fragmentShader,
          'side': three.BackSide
        } );

        final mesh = three.InstancedMesh( geometry, material, 50000 );
        mesh.onBeforeRender = ({
          three.Camera? camera, 
          three.BufferGeometry? geometry, 
          Map<String, dynamic>? group, 
          three.Material? material, 
          three.Object3D? mesh, 
          three.RenderTarget? renderTarget, 
          three.WebGLRenderer? renderer, 
         three. Scene? scene
        }) {
          material?.uniforms['cameraPos']['value'].setFrom( threeJs.camera.position );
        };

        final transform = three.Object3D();

        for ( int i = 0; i < mesh.count!; i ++ ) {
          transform.position.random().subScalar( 0.5 ).scale( 150 );
          transform.rotation.x = math.Random().nextDouble() * math.pi;
          transform.rotation.y = math.Random().nextDouble() * math.pi;
          transform.rotation.z = math.Random().nextDouble() * math.pi;
          transform.updateMatrix();

          mesh.setMatrixAt( i, transform.matrix );
        }

        threeJs.scene.add( mesh );
      }
    });

    threeJs.addAnimationEvent((delta){
      controls.update();
    });
  }
}
