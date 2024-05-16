import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglUboArrays extends StatefulWidget {
  final String fileName;
  const WebglUboArrays({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglUboArrays> {
  late three.ThreeJS threeJs;
  late three.OrbitControls controls;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      windowResizeUpdate: (newSize){
				threeJs.camera.aspect = threeJs.width / threeJs.height;
				threeJs.camera.updateProjectionMatrix();
      }
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    controls.clearListeners();
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

  late three.UniformsGroup lightingUniformsGroup;
  List<three.Vector2> lightCenters = [];
  final pointLightsMax = 300;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 50, 50 );

    threeJs.scene = three.Scene();
    threeJs.camera.lookAt( threeJs.scene.position );

    // geometry

    final geometry = three.SphereGeometry();

    // uniforms groups

    lightingUniformsGroup = three.UniformsGroup();
    lightingUniformsGroup.setName( 'LightingData' );

    final List<three.Uniform> data = [];
    final List<three.Uniform> dataColors = [];

    for (int i = 0; i < pointLightsMax; i ++ ) {

      final col = three.Color(0xffffff * math.Random().nextDouble()).storage;
      final x = math.Random().nextDouble() * 50 - 25;
      final z = math.Random().nextDouble() * 50 - 25;

      data.add(three.Uniform( three.Vector4( x, 1, z, 0 ))); // light position
      dataColors.add( three.Uniform( three.Vector4( col[0], col[1], col[2], 0))); // light color

      // Store the center positions
      lightCenters.add(three.Vector2(x, z));
    }

    lightingUniformsGroup.addAll(data); // light position
    lightingUniformsGroup.addAll(dataColors); // light position
    lightingUniformsGroup.add(three.Uniform( pointLightsMax) ); // light position

    final cameraUniformsGroup = three.UniformsGroup();
    cameraUniformsGroup.setName( 'ViewData' );
    cameraUniformsGroup.add( three.Uniform( threeJs.camera.projectionMatrix ) ); // projection matrix
    cameraUniformsGroup.add( three.Uniform( threeJs.camera.matrixWorldInverse ) ); // view matrix

    const vertexShader = '''
			uniform ViewData {
				mat4 projectionMatrix;
				mat4 viewMatrix;
			};

			//uniform mat4 modelMatrix;
			//uniform mat3 normalMatrix;

			//in vec3 position;
			//in vec3 normal;
			//in vec2 uv;
			out vec2 vUv;

			out vec3 vPositionEye;
			out vec3 vNormalEye;

			void main()	{

				vec4 vertexPositionEye = viewMatrix * modelMatrix * vec4( position, 1.0 );

				vPositionEye = (modelMatrix * vec4( position, 1.0 )).xyz;
				vNormalEye = (vec4(normal , 1.)).xyz;

				vUv = uv;

				gl_Position = projectionMatrix * vertexPositionEye;

			}
    ''';

    const fragmentShader = '''
			precision highp float;
			precision highp int;

			uniform LightingData {
				vec4 lightPosition[POINTLIGHTS_MAX];
				vec4 lightColor[POINTLIGHTS_MAX];
				float pointLightsCount;
			};
			
			#include <common>
			float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
		
				float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
		
				if ( cutoffDistance > 0.0 ) {
					distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
				}
		
				return distanceFalloff;
			}

			in vec2 vUv;
			in vec3 vPositionEye;
			in vec3 vNormalEye;
			out vec4 fragColor;

			void main()	{

				vec4 color = vec4(vec3(0.), 1.);
				for (int x = 0; x < int(pointLightsCount); x++) {
					vec3 offset = lightPosition[x].xyz - vPositionEye;
					vec3 dirToLight = normalize( offset );
					float distance = length( offset );

					float diffuse = max(0.0, dot(vNormalEye, dirToLight));
					float attenuation = 1.0 / (distance * distance);

					vec3 lightWeighting = lightColor[x].xyz * getDistanceAttenuation( distance, 4., .7 );
					color.rgb += lightWeighting;
				}
				fragColor = color;

			}
    ''';

    final material = three.RawShaderMaterial.fromMap( {
      'uniforms': {
        'modelMatrix': { 'value': null },
        'normalMatrix': { 'value': null }
      },
      // 'uniformsGroups': [ cameraUniformsGroup, lightingUniformsGroup ],
      'name': 'Box',
      'defines': {
        'POINTLIGHTS_MAX': pointLightsMax
      },
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader,
      //'glslVersion': three.GLSL3
    } );

    final plane = three.Mesh( three.PlaneGeometry( 100, 100 ), material.clone() );
    //plane.material.uniformsGroups = [ cameraUniformsGroup, lightingUniformsGroup ];
    plane.material?.uniforms['modelMatrix']['value'] = plane.matrixWorld;
    plane.material?.uniforms['normalMatrix']['value'] = plane.normalMatrix;
    plane.rotation.x = - math.pi / 2;
    plane.position.y = - 1;
    threeJs.scene.add( plane );

    // meshes
    const gridSize = {'x': 10,'y': 1, 'z': 10};
    const spacing = 6;

    for (int i = 0; i < gridSize['x']!; i ++ ) {
      for (int j = 0; j < gridSize['y']!; j ++ ) {
        for (int k = 0; k < gridSize['z']!; k ++ ) {
          final mesh = three.Mesh( geometry, material.clone() );
          mesh.name = 'Sphere';
          //mesh.material?.uniformsGroups = [ cameraUniformsGroup, lightingUniformsGroup ];
          mesh.material?.uniforms['modelMatrix']['value'] = mesh.matrixWorld;
          mesh.material?.uniforms['normalMatrix']['value'] = mesh.normalMatrix;
          threeJs.scene.add( mesh );

          mesh.position.x = i * spacing - ( gridSize['x']! * spacing ) / 2;
          mesh.position.y = 0;
          mesh.position.z = k * spacing - ( gridSize['z']! * spacing ) / 2;
        }
      }
    }

    // controls

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enablePan = false;

    threeJs.addAnimationEvent((dt){
      animate();
      controls.update();
    });

    // // gui
    // const gui = new GUI();
    // gui.add( api, 'count', 1, pointLightsMax ).step( 1 ).onChange( function () {
    //   lightingUniformsGroup.uniforms[ 2 ].value = api.count;
    // } );
  }

  void animate() {
    final elapsedTime = threeJs.clock.getElapsedTime();

    final lights = lightingUniformsGroup.uniforms;//[0]
  
    // Parameters for circular movement
    const radius = 5; // Smaller radius for individual circular movements
    const speed = 0.5; // Speed of rotation

    // Update each light's position
    for(int i = 0; i < lights.length/2-1; i ++ ) {
      final light = lights[i];
      final center = lightCenters[i];

      // Calculate circular movement around the light's center
      final angle = speed * elapsedTime + i * 0.5; // Phase difference for each light
      final x = center.x + math.sin( angle ) * radius;
      final z = center.y + math.cos( angle ) * radius;

      // Update the light's position
      light.value.setValues( x, 1.0, z, 0.0 );
    }
  }
}
