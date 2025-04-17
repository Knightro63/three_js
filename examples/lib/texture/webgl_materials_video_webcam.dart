import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:example/src/camera/input_image.dart';
import 'package:flutter/foundation.dart';

import '../src/camera/camera_insert.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMaterialsVideoWebcam extends StatefulWidget {
  
  const WebglMaterialsVideoWebcam({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglMaterialsVideoWebcam> {
  List<int> data = List.filled(60, 0, growable: true);
  Timer? timer;
  InsertCamera camera = InsertCamera(androidSimMac: false);
  bool loading = true;
  three.ThreeJS? threeJs;
  three.CanvasTexture? texture;
  late three.Uint8Array image;
  Size imageSize = const Size(640,480);

  @override
  void initState() {

    camera.setupCameras().then((value) async{
      setState(() {
        loading = false;
      });
      await camera.startLiveFeed((InputImage i){
        if(threeJs == null){
          imageSize = i.metadata!.size;
          image = three.Uint8Array((imageSize.width*imageSize.height*4).toInt());
          threeJs = three.ThreeJS(
            onSetupComplete: (){setState(() {});},
            setup: setup,
            settings: three.Settings(
              useOpenGL: true
            )
          );
          timer = Timer.periodic(const Duration(seconds: 1), (t){
            setState(() {
              data.removeAt(0);
              data.add(threeJs!.clock.fps);
            });
          });
        }
        if(i.bytes != null){
          image.set(i.bytes!);
          texture?.needsUpdate = true;//updateVideo();
        }
      });
    });

    super.initState();
  }
  @override
  void dispose() {
    timer?.cancel();
    image.dispose();
    camera.dispose();
    threeJs?.dispose();
    three.loading.clear();
    controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if(threeJs != null)threeJs!.build(),
          if(threeJs != null)Statistics(data: data),
          loading?Container():CameraSetup(
            camera: camera, 
            size: const Size(1,1)
          ),
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs!.camera = three.PerspectiveCamera( 60, threeJs!.width / threeJs!.height, 0.1, 100 );
    threeJs!.camera.position.z = 0.01;

    threeJs!.scene = three.Scene();
    texture = three.CanvasTexture(three.ImageElement(
      width: imageSize.width,
      height: imageSize.height,
      data: image
    ));
    texture?.colorSpace = three.SRGBColorSpace;
    
    final geometry = three.PlaneGeometry( 16, 9 );
    geometry.scale( 0.5, 0.5, 0.5 );
    geometry.rotateX(math.pi);

    late final three.Material material;
    if(!kIsWeb && !Platform.isWindows && !Platform.isAndroid){
      final Map<String,dynamic> uniforms = {
        'texture1': { 'value': texture },
        'uvScale': { 'value': three.Vector2( 1.0, 1.0 ) },
      };

      const String vertexShader = '''
        uniform vec2 uvScale;
        varying vec2 vUv;

        void main(){
          vUv = uvScale * uv;
          vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
          gl_Position = projectionMatrix * mvPosition;
        }
      ''';
      const String fragmentShader = '''
        varying vec2 vUv;
        uniform sampler2D texture1;
        void main(void){
          vec4 textureColor = texture2D(texture1, vUv.st);
          gl_FragColor = vec4(textureColor.b,textureColor.g,textureColor.r,1.0);
        }
      ''';

      material = three.ShaderMaterial.fromMap( {
        'side': three.DoubleSide,
        'uniforms': uniforms,
        'vertexShader': vertexShader,
        'fragmentShader': fragmentShader
      } );
    }
    else{
      material = three.MeshBasicMaterial.fromMap( { 'map': texture, 'side': three.DoubleSide } );
    }

    material.needsUpdate = true;

    const count = 128;
    const radius = 32;

    for (int i = 1, l = count; i <= l; i ++ ) {
      final phi = math.acos( - 1 + ( 2 * i ) / l );
      final theta = math.sqrt( l * math.pi ) * phi;

      final mesh = three.Mesh( geometry, material );
      mesh.position.setFromSphericalCoords( radius, phi, theta );
      mesh.lookAt( threeJs!.camera.position );
      threeJs!.scene.add( mesh );
    }

    controls = three.OrbitControls( threeJs!.camera, threeJs!.globalKey );
    controls.enableZoom = false;
    controls.enablePan = false;

    threeJs!.addAnimationEvent((dt){
      controls.update();
    });
  }
}
