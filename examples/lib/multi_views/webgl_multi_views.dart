import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglMultiViews extends StatefulWidget {
  
  const WebglMultiViews({super.key});

  @override
  createState() => _MyAppState();
}

class _MyAppState extends State<WebglMultiViews> {
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

  final List<Map<String,dynamic>>views = [
    {
      'left': 0,
      'bottom': 0,
      'width': 0.5,
      'height': 1.0,
      'background': three.Color().setRGB( 0.5, 0.5, 0.7, three.ColorSpace.srgb ),
      'eye': <double>[ 0.0, 300.0, 1800.0 ],
      'up': <double>[ 0.0, 1.0, 0.0 ],
      'fov': 30.0,
      'updateCamera': ( camera, scene, mouseX ) {
        camera.position.x += mouseX * 0.05;
        camera.position.x = math.max<double>( math.min( camera.position.x, 2000.0 ), - 2000.0 );
        camera.lookAt( scene.position );
      }
    },
    {
      'left': 0.5,
      'bottom': 0,
      'width': 0.5,
      'height': 0.5,
      'background': three.Color().setRGB( 0.7, 0.5, 0.5, three.ColorSpace.srgb ),
      'eye': <double>[ 0, 1800, 0 ],
      'up': <double>[ 0, 0, 1 ],
      'fov': 45.0,
      'updateCamera': ( camera, scene, mouseX ) {

        camera.position.x -= mouseX * 0.05;
        camera.position.x = math.max<double>( math.min( camera.position.x, 2000.0 ), - 2000.0 );
        camera.lookAt( camera.position.clone().setY( 0.0 ) );

      }
    },
    {
      'left': 0.5,
      'bottom': 0.5,
      'width': 0.5,
      'height': 0.5,
      'background': three.Color().setRGB( 0.5, 0.7, 0.7, three.ColorSpace.srgb ),
      'eye': <double>[ 1400, 800, 1400 ],
      'up': <double>[ 0, 1, 0 ],
      'fov': 60.0,
      'updateCamera': ( camera, scene, mouseX ) {

        camera.position.y -= mouseX * 0.05;
        camera.position.y = math.max<double>( math.min( camera.position.y, 1600.0 ), - 1600.0 );
        camera.lookAt( scene.position );

      }
    }
  ];

  Future<void> setup() async {
    for (int ii = 0; ii < views.length; ++ ii ) {
      final view = views[ ii ];
      threeJs.camera = three.PerspectiveCamera( view['fov'], threeJs.width / threeJs.height, 1, 10000 );
      threeJs.camera.position.copyFromArray( view['eye'] );
      threeJs.camera.up.copyFromArray( view['up'] );
      view['camera'] = threeJs.camera;
    }

    threeJs.scene = three.Scene();

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 0, 0, 1 );
    threeJs.scene.add( light );

    //final shadowTexture = three.CanvasTexture( canvas );

    final shadowMaterial = three.MeshBasicMaterial.fromMap( {  'transparent': true } );//'map': shadowTexture,
    final shadowGeo = three.PlaneGeometry( 300, 300, 1, 1 );

    three.Mesh shadowMesh;

    shadowMesh = three.Mesh( shadowGeo, shadowMaterial );
    shadowMesh.position.y = - 250;
    shadowMesh.rotation.x = - math.pi / 2;
    threeJs.scene.add( shadowMesh );

    shadowMesh = three.Mesh( shadowGeo, shadowMaterial );
    shadowMesh.position.x = - 400;
    shadowMesh.position.y = - 250;
    shadowMesh.rotation.x = - math.pi / 2;
    threeJs.scene.add( shadowMesh );

    shadowMesh = three.Mesh( shadowGeo, shadowMaterial );
    shadowMesh.position.x = 400;
    shadowMesh.position.y = - 250;
    shadowMesh.rotation.x = - math.pi / 2;
    threeJs.scene.add( shadowMesh );

    const radius = 200.0;

    final geometry1 = IcosahedronGeometry( radius, 1 );

    final count = geometry1.attributes['position'].count;
    geometry1.setAttributeFromString( 'color', three.Float32BufferAttribute( three.Float32Array( count * 3 ), 3 ) );

    final geometry2 = geometry1.clone();
    final geometry3 = geometry1.clone();

    final color = three.Color();
    final positions1 = geometry1.attributes['position'];
    final positions2 = geometry2.attributes['position'];
    final positions3 = geometry3.attributes['position'];
    final colors1 = geometry1.attributes['color'];
    final colors2 = geometry2.attributes['color'];
    final colors3 = geometry3.attributes['color'];

    for (int i = 0; i < count; i ++ ) {

      color.setHSL( ( positions1.getY( i ) / radius + 1 ) / 2, 1.0, 0.5, three.ColorSpace.srgb );
      colors1.setXYZ( i, color.red, color.green, color.blue );

      color.setHSL( 0, ( positions2.getY( i ) / radius + 1 ) / 2, 0.5, three.ColorSpace.srgb);
      colors2.setXYZ( i, color.red, color.green, color.blue );

      color.setRGB( 1, 0.8 - ( positions3.getY( i ) / radius + 1 ) / 2, 0, three.ColorSpace.srgb );
      colors3.setXYZ( i, color.red, color.green, color.blue );

    }

    final material = three.MeshPhongMaterial.fromMap( {
      'color': 0xffffff,
      'flatShading': true,
      'vertexColors': true,
      'shininess': 0
    } );

    final wireframeMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x000000, 'wireframe': true, 'transparent': true } );

    three.Mesh mesh = three.Mesh( geometry1, material );
    three.Mesh wireframe = three.Mesh( geometry1, wireframeMaterial );
    mesh.add( wireframe );
    mesh.position.x = - 400;
    mesh.rotation.x = - 1.87;
    threeJs.scene.add( mesh );

    mesh = three.Mesh( geometry2, material );
    wireframe = three.Mesh( geometry2, wireframeMaterial );
    mesh.add( wireframe );
    mesh.position.x = 400;
    threeJs.scene.add( mesh );

    mesh = three.Mesh( geometry3, material );
    wireframe = three.Mesh( geometry3, wireframeMaterial );
    mesh.add( wireframe );
    threeJs.scene.add( mesh );

    threeJs.postProcessor = ([dt]){
      render();
    };

    threeJs.domElement.addEventListener( three.PeripheralType.pointermove, onDocumentMouseMove );
  }

  double mouseX = 0;
  void onDocumentMouseMove( event ) {
    mouseX = ( event.clientX - threeJs.width / 2 );
    //mouseY = ( event.clientY - threeJs.height / 2 );
  }
  void render() {
    for (int ii = 0; ii < views.length; ++ ii ) {

      final view = views[ ii ];
      final camera = view['camera'];

      view['updateCamera']( camera, threeJs.scene, mouseX);

      final left = ( threeJs.width * view['left'] );
      final bottom = ( threeJs.height * view['bottom'] );
      final width = ( threeJs.width * view['width'] );
      final height = ( threeJs.height * view['height'] );

      threeJs.renderer!.setViewport( left, bottom, width, height );
      threeJs.renderer!.setScissor( left, bottom, width, height );
      threeJs.renderer!.setScissorTest( true );
      threeJs.renderer!.setClearColor( view['background'] );

      camera.aspect = width / height;
      camera.updateProjectionMatrix();

      threeJs.renderer!.render( threeJs.scene, camera );
    }
  }
}