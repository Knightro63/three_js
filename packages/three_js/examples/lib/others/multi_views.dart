import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter_angle/flutter_angle.dart';
import 'package:three_js/three_js.dart' as three;

class MultiViews extends StatefulWidget {
  
  const MultiViews({super.key});

  @override
  createState() => _MyAppState();
}

class _MyAppState extends State<MultiViews> {
  three.WebGLRenderer? renderer;
  late FlutterAngleTexture three3dRender;

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> init() async {
    if(!kIsWeb) {
      await FlutterAngle.initOpenGL();
      three3dRender = await FlutterAngle.createTexture(
        AngleOptions(
          width: 1024, 
          height: 1024, 
          dpr: 1
        )
      );

      Map<String, dynamic> options = {
        "width": 1024,
        "height": 1024,
        "gl": three3dRender.getContext(),
        "antialias": true,
      };
      renderer = three.WebGLRenderer(options);
      renderer!.autoClear = true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: FutureBuilder<bool>(
        future: init(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          else{
            return SingleChildScrollView(
              child: _build(context)
            );
          }
        }
      ),
    );

  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        MultiViews1(renderer: renderer),
        Container(height: 2, color: Colors.red,),
        MultiViews2(renderer: renderer)
      ],
    );
  }

}

class MultiViews1 extends StatefulWidget {
  final three.WebGLRenderer? renderer;
  const MultiViews1({super.key, this.renderer});

  @override
  createState() => _multi_views1_State();
}
class _multi_views1_State extends State<MultiViews1> {
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
      size: const Size(300,300),
      renderer: widget.renderer,
      rendererUpdate: (){
        if (!kIsWeb) threeJs.renderer!.setRenderTarget(threeJs.renderTarget);
      }
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 100);

    // scene
    threeJs.scene = three.Scene();

    three.AmbientLight ambientLight = three.AmbientLight(0xffffff, 0.9);
    threeJs.scene.add(ambientLight);

    three.PointLight pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    three.BoxGeometry geometry = three.BoxGeometry(20, 20, 20);
    three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({"color": 0xff0000});

    final object = three.Mesh(geometry, material);
    threeJs.scene.add(object);

    threeJs.addAnimationEvent((dt){
      object.rotation.x = object.rotation.x + 0.01;
    });
  }
}

class MultiViews2 extends StatefulWidget {
  final three.WebGLRenderer? renderer;
  const MultiViews2({super.key, this.renderer});

  @override
  createState() => _multi_views2_State();
}
class _multi_views2_State extends State<MultiViews2> {
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
      size: const Size(300,300),
      renderer: widget.renderer,
      rendererUpdate: (){
        if (!kIsWeb) threeJs.renderer!.setRenderTarget(threeJs.renderTarget);
      }
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  late three.Mesh mesh;
  late three.Object3D object;
  late three.Texture texture;
  three.AnimationMixer? mixer;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 100);


    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color(1, 1, 0);

    three.AmbientLight ambientLight = three.AmbientLight(0xffffff, 0.9);
    threeJs.scene.add(ambientLight);

    three.PointLight pointLight = three.PointLight(0xffffff, 0.8);
    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);
    threeJs.camera.lookAt(threeJs.scene.position);

    three.BoxGeometry geometry = three.BoxGeometry(10, 10, 20);
    three.MeshBasicMaterial material = three.MeshBasicMaterial();

    object = three.Mesh(geometry, material);
    threeJs.scene.add(object);
    threeJs.addAnimationEvent((dt){
      object.rotation.y = object.rotation.y + 0.02;
      object.rotation.x = object.rotation.x + 0.01;
      mixer?.update(dt);
    });
  }
}
