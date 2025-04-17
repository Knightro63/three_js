import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_modifers/buffergeometry_utils.dart';

class WebglInteractivePoints extends StatefulWidget {
  const WebglInteractivePoints({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglInteractivePoints> {
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

  late final three.Points particles;
  final double particleSize = 20;

  final raycaster = three.Raycaster();
  final three.Vector2 pointer = three.Vector2();
  int? intersected;

  Future<void> setup() async {
    threeJs.scene =three.Scene();

    threeJs.camera =three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.z = 250;
    three.BufferGeometry boxGeometry = three.BoxGeometry( 200, 200, 200, 16, 16, 16 );

    // if normal and uv attributes are not removed, mergeVertices() can't consolidate indentical vertices with different normal/uv data

    boxGeometry.deleteAttributeFromString( 'normal' );
    boxGeometry.deleteAttributeFromString( 'uv' );
    boxGeometry = BufferGeometryUtils.mergeVertices( boxGeometry );

    final positionAttribute = boxGeometry.getAttributeFromString( 'position' );

    final List<double> colors = [];
    final List<double> sizes = [];

    final color = three.Color();

    for ( int i = 0, l = positionAttribute.count; i < l; i ++ ) {
      colors.addAll([0,0,0]);
      color.setHSL( 0.01 + 0.1 * ( i / l ), 1.0, 0.5 );
      color.toNumArray( colors, i * 3 );

      sizes.add(particleSize * 0.5);
    }

    final geometry =three.BufferGeometry();
    geometry.setAttributeFromString( 'position', positionAttribute );
    geometry.setAttributeFromString( 'customColor',three.Float32BufferAttribute.fromList( colors, 3 ) );
    geometry.setAttributeFromString( 'size',three.Float32BufferAttribute.fromList( sizes, 1 ) );

    //

    final material = three.ShaderMaterial.fromMap( <String,dynamic>{
      'uniforms': {
        'color': { 'value':three.Color( 0xffffff ) },
        'pointTexture': { 'value': await three.TextureLoader().fromAsset( 'assets/textures/sprites/disc.png' ) },
        'alphaTest': { 'value': 0.9 }
      },
      'vertexShader': '''
        attribute float size;
        attribute vec3 customColor;

        varying vec3 vColor;

        void main() {

          vColor = customColor;

          vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );

          gl_PointSize = size * ( 300.0 / -mvPosition.z );

          gl_Position = projectionMatrix * mvPosition;

        }
      ''',
      'fragmentShader': '''
        uniform vec3 color;
        uniform sampler2D pointTexture;
        uniform float alphaTest;

        varying vec3 vColor;

        void main() {

          gl_FragColor = vec4( color * vColor, 1.0 );

          gl_FragColor = gl_FragColor * texture2D( pointTexture, gl_PointCoord );

          if ( gl_FragColor.a < alphaTest ) discard;

        }
      '''
    } );

    particles = three.Points( geometry, material );
    threeJs.scene.add( particles );

    threeJs.domElement.addEventListener( three.PeripheralType.pointerHover, onPointerMove );
    threeJs.addAnimationEvent(render);
  }

  void onPointerMove(three.WebPointerEvent event ) {
    pointer.x = ( event.clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( event.clientY / threeJs.height ) * 2 + 1;
  }

  void render([double? dt]){
    particles.rotation.x += 0.0005;
    particles.rotation.y += 0.001;

    final geometry = particles.geometry!;
    final attributes = geometry.attributes;

    raycaster.setFromCamera( pointer, threeJs.camera );
    final intersects = raycaster.intersectObject( particles,false );

    if ( intersects.isNotEmpty ) {
      if ( intersected != intersects[ 0 ].index) {
        attributes['size'].array[ intersected??0 ] = particleSize;
        intersected = intersects[ 0 ].index;

        attributes['size'].array[ intersected ] = particleSize * 1.25;
        attributes['size'].needsUpdate = true;
      }
    } 
    else if ( intersected != null ) {
      attributes['size'].array[ intersected ] = particleSize;
      attributes['size'].needsUpdate = true;
      intersected = null;
    }
  }
}
