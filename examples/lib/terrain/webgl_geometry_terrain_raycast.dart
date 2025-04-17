import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglGeometryTerrainRaycast extends StatefulWidget {
  
  const WebglGeometryTerrainRaycast({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglGeometryTerrainRaycast> {
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

  final worldWidth = 256, worldDepth = 256;
  late final three.OrbitControls controls;
  late final three.Mesh mesh;
  late final three.CanvasTexture texture;

  late three.Mesh helper;

  final raycaster = three.Raycaster();
  final pointer = three.Vector2();

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 1, 10000 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xefd1b5 );
    //threeJs.scene.fog = three.FogExp2( 0xefd1b5, 0.00025 );

    final data = generateHeight( worldWidth, worldDepth );

    threeJs.camera.position.setValues( 100, 3500, 2500 );
    threeJs.camera.lookAt(three.Vector3( - 100, 810, - 800 ));

    final geometry = three.PlaneGeometry( 7500, 7500, worldWidth - 1, worldDepth - 1 );
    geometry.rotateX( - math.pi / 2 );

    final vertices = geometry.attributes['position'].array;

    // for (int i = 0, j = 0, l = vertices.length; i < l; i ++, j += 3 ) {
    //   vertices[ j + 1 ] = data[ i ] * 10.0;
    // }
    int j = 0;
    for (int i = 0; j < vertices.length; i++) {
      vertices[j+1] = data[i] * 10.0;
      j+=3;
    }
    texture = three.CanvasTexture( generateTexture( data, worldWidth, worldDepth ) );
    texture.wrapS = three.ClampToEdgeWrapping;
    texture.wrapT = three.ClampToEdgeWrapping;
    texture.colorSpace = three.SRGBColorSpace;

    mesh = three.Mesh( geometry, three.MeshBasicMaterial.fromMap( { 'map': texture } ) );
    threeJs.scene.add(mesh);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });

    final geometryHelper = ConeGeometry( 20, 100, 3 );
    geometryHelper.translate( 0, 50, 0 );
    geometryHelper.rotateX( math.pi / 2 );
    helper = three.Mesh( geometryHelper, three.MeshNormalMaterial() );
    threeJs.scene.add( helper );

    threeJs.domElement.addEventListener(three.PeripheralType.pointerHover, onPointerMove );
  }

  three.Uint8Array generateHeight(int width,int height ) {
    double seed = math.pi / 4;
    double random() {
      final x = math.sin( seed ++ ) * 10000;
      return x -  x.floor();
    }

    int size = width * height;
    final data = three.Uint8Array( size );
    final perlin = ImprovedNoise();
    double z = random() * 100;

    double quality = 1;

    for (int j = 0; j < 4; j ++ ) {
      for (int i = 0; i < size; i ++ ) {
        final x = i % width;
        final y = ( i / width ).truncate();
        data[ i ] += ( perlin.noise( x / quality, y / quality, z ) * quality * 1.75 ).abs().toInt();
      }

      quality *= 5;
    }

    return data;
  }

  three.ImageElement generateTexture(three.Uint8Array data,int width,int height ) {
    final vector3 = three.Vector3( 0, 0, 0 );
    final sun = three.Vector3( 1, 1, 1 );
    sun.normalize();

    final imageData = three.Uint8Array.fromList(List.filled(width*height*4, 255));

    for (int i = 0, j = 0; i < imageData.length; i += 4, j ++ ) {
      vector3.x = data[ j - 2 ] - data[ j + 2 ] *1.0;
      vector3.y = 2;
      vector3.z = data[ j - width * 2 ] - data[ j + width * 2 ] *1.0;
      vector3.normalize();

      final shade = vector3.dot( sun );

      imageData[ i ] = (( 96 + shade * 128 ) * ( 0.5 + data[ j ] * 0.007 )).toInt();
      imageData[ i + 1 ] = (( 32 + shade * 96 ) * ( 0.5 + data[ j ] * 0.007 )).toInt();
      imageData[ i + 2 ] = (( shade * 96 ) * ( 0.5 + data[ j ] * 0.007 )).toInt();
    }

    // for (int i = 0, l = imageData.length; i < l; i += 4 ) {
    //   final v = ( math.Random().nextDouble() * 5 ).truncate();
    //   imageData[ i ] += v;
    //   imageData[ i + 1 ] += v;
    //   imageData[ i + 2 ] += v;
    // }

    final canvasScaled = three.ImageElement(
      width: width,
      height: height,
      data: imageData
    );

    return canvasScaled;
  }

  void onPointerMove( event ) {
    pointer.x = ( event.clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( event.clientY / threeJs.height ) * 2 + 1;
    raycaster.setFromCamera( pointer, threeJs.camera );

    // See if the ray from the camera into the world hits one of our meshes
    final intersects = raycaster.intersectObject( mesh,false);

    // Toggle rotation bool for meshes that we clicked
    if ( intersects.isNotEmpty) {
      helper.position.setValues( 0, 0, 0 );
      helper.lookAt( intersects[ 0 ].face!.normal );
      helper.position.setFrom( intersects[ 0 ].point! );
    }
  }
}
