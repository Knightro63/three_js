import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:image/image.dart' as img;

class OpenglScreenshot extends StatefulWidget {
  const OpenglScreenshot({super.key});
  @override
  createState() => _State();
}

class _State extends State<OpenglScreenshot> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late final three.Uint8Array buffer;// = three.Uint8Array( SIZE2 * 4 );
  late final three.WebGLRenderTarget rt;// = three.WebGLRenderTarget( SIZE, SIZE );

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
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: InkWell(
        onTap: () async{
          try {
            final width = threeJs.width.toInt();
            final height = threeJs.height.toInt();

            threeJs.renderer?.setRenderTarget( rt );
            threeJs.renderer?.render( threeJs.scene, threeJs.camera );
            threeJs.renderer?.readRenderTargetPixels(rt, 0, 0, width, height, buffer);
            
            img.Image image = img.Image.fromBytes(
              width: width,
              height: height,
              bytes: buffer.toDartList().buffer,
              numChannels: 4,
              order: img.ChannelOrder.rgb
            );
            image = img.copyFlip(image, direction: img.FlipDirection.vertical);
            Uint8List pngBytes = img.encodePng(image);
            SaveFile.saveBytes(printName: 'opengl_test', fileType: 'png', bytes: pngBytes);
          }catch (e) {
            rethrow;
          }
        },
        child:Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.circular(45/2)
          ),
          child: Icon(
            Icons.camera_alt_outlined
          ),
        ),
      ),
      body: RepaintBoundary(
        child: threeJs.build(),
      )
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    buffer = three.Uint8Array( threeJs.width.toInt() * threeJs.height.toInt() * 4 );
    rt = three.WebGLRenderTarget( threeJs.width.toInt(), threeJs.height.toInt() );

    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.25, 20);
    threeJs.camera.position.setValues( - 0, 0, 2.7 );
    threeJs.camera.lookAt(threeJs.scene.position);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    three.RGBELoader rgbeLoader = three.RGBELoader();
    rgbeLoader.setPath('assets/textures/equirectangular/');
    final hdrTexture = await rgbeLoader.fromAsset('royal_esplanade_1k.hdr');
    hdrTexture?.mapping = three.EquirectangularReflectionMapping;
    
    threeJs.scene.background = hdrTexture;
    threeJs.scene.environment = hdrTexture;
    threeJs.scene.backgroundRotation = three.Euler(math.pi);
    threeJs.scene.environmentRotation = three.Euler(math.pi);
    
    threeJs.scene.add( three.AmbientLight( 0xffffff ) );

    three.GLTFLoader loader = three.GLTFLoader().setPath('assets/models/gltf/DamagedHelmet/glTF/');
    final result = await loader.fromAsset('DamagedHelmet.gltf');
    final object = result!.scene;
    threeJs.scene.add(object);
  
    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
