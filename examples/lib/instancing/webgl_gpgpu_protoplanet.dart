import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';

import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';

class WebglGpgpuProtoplanet extends StatefulWidget {
  
  const WebglGpgpuProtoplanet({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglGpgpuProtoplanet> {
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
  late three.BufferGeometry geometry;
  final width = 64;
  final numParticles = 64 * 64;
  late Map<String,dynamic> particleUniforms;
  late Map<String,double> effectController;
  late GPUComputationRenderer gpuCompute;
  late Map<String,dynamic> velocityVariable;
  late Map<String,dynamic> positionVariable;
  late Map<String,dynamic> velocityUniforms;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 75, threeJs.width/threeJs.height, 5, 15000 );
    threeJs.camera.position.y = 120;
    threeJs.camera.position.z = 400;

    threeJs.scene = three.Scene();

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 100;
    controls.maxDistance = 1000;

    effectController = {
      // Can be changed dynamically
      'gravityConstant': 100.0,
      'density': 0.45,

      // Must restart simulation
      'radius': 300.0,
      'height': 8.0,
      'exponent': 0.4,
      'maxMass': 15.0,
      'velocity': 70.0,
      'velocityExponent': 0.2,
      'randVelocity': 0.001
    };

    initComputeRenderer();
    initProtoplanets();
    dynamicValuesChanger();

    threeJs.addAnimationEvent((dt){
      render();
    });
  }

  void initComputeRenderer() {

    gpuCompute = GPUComputationRenderer( width, width, threeJs.renderer! );

    final dtPosition = gpuCompute.createTexture();
    final dtVelocity = gpuCompute.createTexture();

    fillTextures( dtPosition, dtVelocity );
    const computeShaderVelocity = '''
			// For PI declaration:
			#include <common>

			#define delta ( 1.0 / 60.0 )

			uniform float gravityConstant;
			uniform float density;

			const float width = resolution.x;
			const float height = resolution.y;

			float radiusFromMass( float mass ) {
				// Calculate radius of a sphere from mass and density
				return pow( ( 3.0 / ( 4.0 * PI ) ) * mass / density, 1.0 / 3.0 );
			}

			void main()	{

				vec2 uv = gl_FragCoord.xy / resolution.xy;
				float idParticle = uv.y * resolution.x + uv.x;

				vec4 tmpPos = texture2D( texturePosition, uv );
				vec3 pos = tmpPos.xyz;

				vec4 tmpVel = texture2D( textureVelocity, uv );
				vec3 vel = tmpVel.xyz;
				float mass = tmpVel.w;

				if ( mass > 0.0 ) {

					float radius = radiusFromMass( mass );

					vec3 acceleration = vec3( 0.0 );

					// Gravity interaction
					for ( float y = 0.0; y < height; y++ ) {

						for ( float x = 0.0; x < width; x++ ) {

							vec2 secondParticleCoords = vec2( x + 0.5, y + 0.5 ) / resolution.xy;
							vec3 pos2 = texture2D( texturePosition, secondParticleCoords ).xyz;
							vec4 velTemp2 = texture2D( textureVelocity, secondParticleCoords );
							vec3 vel2 = velTemp2.xyz;
							float mass2 = velTemp2.w;

							float idParticle2 = secondParticleCoords.y * resolution.x + secondParticleCoords.x;

							if ( idParticle == idParticle2 ) {
								continue;
							}

							if ( mass2 == 0.0 ) {
								continue;
							}

							vec3 dPos = pos2 - pos;
							float distance = length( dPos );
							float radius2 = radiusFromMass( mass2 );

							if ( distance == 0.0 ) {
								continue;
							}

							// Checks collision

							if ( distance < radius + radius2 ) {

								if ( idParticle < idParticle2 ) {

									// This particle is aggregated by the other
									vel = ( vel * mass + vel2 * mass2 ) / ( mass + mass2 );
									mass += mass2;
									radius = radiusFromMass( mass );

								}
								else {

									// This particle dies
									mass = 0.0;
									radius = 0.0;
									vel = vec3( 0.0 );
									break;

								}

							}

							float distanceSq = distance * distance;

							float gravityField = gravityConstant * mass2 / distanceSq;

							gravityField = min( gravityField, 1000.0 );

							acceleration += gravityField * normalize( dPos );

						}

						if ( mass == 0.0 ) {
							break;
						}
					}

					// Dynamics
					vel += delta * acceleration;

				}

				gl_FragColor = vec4( vel, mass );

			}
    ''';

    const computeShaderPosition = '''
			#define delta ( 1.0 / 60.0 )

			void main() {

				vec2 uv = gl_FragCoord.xy / resolution.xy;

				vec4 tmpPos = texture2D( texturePosition, uv );
				vec3 pos = tmpPos.xyz;

				vec4 tmpVel = texture2D( textureVelocity, uv );
				vec3 vel = tmpVel.xyz;
				float mass = tmpVel.w;

				if ( mass == 0.0 ) {
					vel = vec3( 0.0 );
				}

				// Dynamics
				pos += vel * delta;

				gl_FragColor = vec4( pos, 1.0 );

			}
    ''';
    velocityVariable = gpuCompute.addVariable( 'textureVelocity', computeShaderVelocity, dtVelocity );
    positionVariable = gpuCompute.addVariable( 'texturePosition', computeShaderPosition, dtPosition );

    gpuCompute.setVariableDependencies( velocityVariable, [ positionVariable, velocityVariable ] );
    gpuCompute.setVariableDependencies( positionVariable, [ positionVariable, velocityVariable ] );

    velocityUniforms = velocityVariable['material'].uniforms;
    velocityUniforms['gravityConstant'] = { 'value': 0.0 };
    velocityUniforms['density' ] = { 'value': 0.0 };

    final error = gpuCompute.init();

    if ( error != null ) {
      three.console.error( error );
    }
  }

  void restartSimulation() {
    final dtPosition = gpuCompute.createTexture();
    final dtVelocity = gpuCompute.createTexture();

    fillTextures( dtPosition, dtVelocity );

    gpuCompute.renderTexture( dtPosition, positionVariable['renderTargets'][ 0 ] );
    gpuCompute.renderTexture( dtPosition, positionVariable['renderTargets'][ 1 ] );
    gpuCompute.renderTexture( dtVelocity, velocityVariable['renderTargets'][ 0 ] );
    gpuCompute.renderTexture( dtVelocity, velocityVariable['renderTargets'][ 1 ] );
  }

  void initProtoplanets() {
    geometry = three.BufferGeometry();

    final positions = Float32List( numParticles * 3 );
    int p = 0;

    for ( int i = 0; i < numParticles; i ++ ) {
      positions[p ++ ] = ( math.Random().nextDouble() * 2 - 1 ) * effectController['radius']!;
      positions[p ++ ] = 0; //( math.Random().nextDouble() * 2 - 1 ) * effectController.radius;
      positions[p ++ ] = ( math.Random().nextDouble() * 2 - 1 ) * effectController['radius']!;
    }

    final uvs = Float32List( numParticles * 2 );
    p = 0;
    for ( int j = 0; j < width; j ++ ) {
      for ( int i = 0; i < width; i ++ ) {
        uvs[ p ++ ] = i / ( width - 1 );
        uvs[ p ++ ] = j / ( width - 1 );
      }
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geometry.setAttributeFromString( 'uv', three.Float32BufferAttribute.fromList( uvs, 2 ) );

    particleUniforms = {
      'texturePosition': { 'value': null },
      'textureVelocity': { 'value': null },
      'cameraConstant': { 'value': getCameraConstant( threeJs.camera ) },
      'density': { 'value': 0.0 }
    };

    const vertexShader = '''
			// For PI declaration:
			#include <common>

			uniform sampler2D texturePosition;
			uniform sampler2D textureVelocity;

			uniform float cameraConstant;
			uniform float density;

			varying vec4 vColor;


			void main() {
				vec4 posTemp = texture2D( texturePosition, uv );
				vec3 pos = posTemp.xyz;

				vec4 velTemp = texture2D( textureVelocity, uv );
				vec3 vel = velTemp.xyz;
				float mass = velTemp.w;

				vColor = vec4( 1.0, mass / 250.0, 0.0, 1.0 );

				vec4 mvPosition = modelViewMatrix * vec4( pos, 1.0 );

				// Calculate radius of a sphere from mass and density
				float radius = pow( ( 3.0 / ( 4.0 * PI ) ) * mass / density, 1.0 / 3.0 );

				// Apparent size in pixels
				if ( mass == 0.0 ) {
					gl_PointSize = 0.0;
				}
				else {
					gl_PointSize = radius * cameraConstant / ( - mvPosition.z );
				}

				gl_Position = projectionMatrix * mvPosition;

			}
    ''';
    
    const fragmentShader = '''
			varying vec4 vColor;

			void main() {

				if ( vColor.y == 0.0 ) discard;

				float f = length( gl_PointCoord - vec2( 0.5, 0.5 ) );
				if ( f > 0.5 ) {
					discard;
				}
				gl_FragColor = vColor;

			}
    ''';
    // THREE.ShaderMaterial
    final material = three.ShaderMaterial.fromMap( {
      'uniforms': particleUniforms,
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader
    } );

    final particles = three.Points( geometry, material );
    particles.matrixAutoUpdate = false;
    particles.updateMatrix();

    threeJs.scene.add( particles );

  }

  void fillTextures( texturePosition, textureVelocity ) {

    final posArray = texturePosition.image.data;
    final velArray = textureVelocity.image.data;

    final radius = effectController['radius']!;
    final height = effectController['height']!;
    final exponent = effectController['exponent']!;
    final maxMass = effectController['maxMass']! * 1024 / numParticles;
    final maxVel = effectController['velocity']!;
    final velExponent = effectController['velocityExponent']!;
    final randVel = effectController['randVelocity']!;

    for ( int k = 0, kl = posArray.length; k < kl; k += 4 ) {
      // Position
      double x, z, rr;

      do {
        x = ( math.Random().nextDouble() * 2 - 1 );
        z = ( math.Random().nextDouble() * 2 - 1 );
        rr = x * x + z * z;
      } while ( rr > 1 );

      rr = math.sqrt( rr );

      final rExp = radius * math.pow( rr, exponent );

      // Velocity
      final vel = maxVel * math.pow( rr, velExponent );

      final vx = vel * z + ( math.Random().nextDouble() * 2 - 1 ) * randVel;
      final vy = ( math.Random().nextDouble() * 2 - 1 ) * randVel * 0.05;
      final vz = - vel * x + ( math.Random().nextDouble() * 2 - 1 ) * randVel;

      x *= rExp;
      z *= rExp;
      final y = ( math.Random().nextDouble() * 2 - 1 ) * height;

      final mass = math.Random().nextDouble() * maxMass + 1;

      // Fill in texture values
      posArray[ k + 0 ] = x;
      posArray[ k + 1 ] = y;
      posArray[ k + 2 ] = z;
      posArray[ k + 3 ] = 1.0;

      velArray[ k + 0 ] = vx;
      velArray[ k + 1 ] = vy;
      velArray[ k + 2 ] = vz;
      velArray[ k + 3 ] = mass;
    }
  }

  void dynamicValuesChanger() {
    velocityUniforms[ 'gravityConstant' ]['value'] = effectController['gravityConstant'];
    velocityUniforms[ 'density' ]['value'] = effectController['density'];
    particleUniforms[ 'density' ]['value'] = effectController['density'];
  }

  double getCameraConstant(three.Camera camera) {
    return threeJs.height / ( math.tan( three.MathUtils.deg2rad * 0.5 * camera.fov ) / camera.zoom );
  }

  void render() {
    gpuCompute.compute();
    particleUniforms[ 'texturePosition' ] = {'value':gpuCompute.getCurrentRenderTarget( positionVariable ).texture};
    particleUniforms[ 'textureVelocity' ] = {'value' : gpuCompute.getCurrentRenderTarget( velocityVariable ).texture};
  }
}
