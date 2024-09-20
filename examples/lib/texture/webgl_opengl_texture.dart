import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:flutter_angle/flutter_angle.dart';

class WebglOpenglTexture extends StatefulWidget {
  const WebglOpenglTexture({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglOpenglTexture> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late three.OrbitControls controls;

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

  Future<void> setup() async {
    const fov = 75.0;
    const aspect = 2.0; // the canvas default
    const near = 0.1;
    const far = 5.0;
    threeJs.camera = three.PerspectiveCamera(fov, aspect, near, far);
    threeJs.camera.position.z = 2;

    threeJs.scene = three.Scene();

    const boxWidth = 1.0;
    const boxHeight = 1.0;
    const boxDepth = 1.0;
    final geometry = three.BoxGeometry(boxWidth, boxHeight, boxDepth);
    
    final forceTextureInitialization = () {
      final material = three.MeshBasicMaterial();
      final geometry = three.PlaneGeometry();
      final scene = three.Scene();
      scene.add(three.Mesh(geometry, material));
      final camera = three.Camera();

      return (texture) {
        material.map = texture;
        threeJs.renderer!.render(scene, camera);
      };
    }();
    
    final cubes = []; // just an array we can use to rotate the cubes

    {
      final three.RenderingContext gl = threeJs.renderer!.getContext();
      final glTex = gl.createTexture();
      gl.bindTexture(WebGL.TEXTURE_2D, glTex);
      gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 2, 2, 0,
          WebGL.RGBA, WebGL.UNSIGNED_BYTE, Uint8Array.fromList([
            255, 0, 0, 255,
            0, 255, 0, 255,
            0, 0, 255, 255,
            255, 255, 0, 255,
          ]));
      gl.generateMipmap(WebGL.TEXTURE_2D);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);
    
      final texture = three.Texture();
      forceTextureInitialization(texture);
      final texProps = threeJs.renderer!.properties.get(texture);
      texProps['__webglTexture'] = glTex;
      
      final material = three.MeshBasicMaterial.fromMap({
        'map': texture,
      });
      final cube = three.Mesh(geometry, material);
      threeJs.scene.add(cube);
      cubes.add(cube); // add to our list of cubes to rotate
    }

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );

    threeJs.addAnimationEvent((dt){
      controls.update();
      cubes.forEach((cube){
        final speed = .2 + 1 * .1;
        final rot = dt * speed;
        cube.rotation.x = rot;
        cube.rotation.y = rot;
      });
    });
  }
}
