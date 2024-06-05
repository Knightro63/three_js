import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:flutter/services.dart';

class FlutterGame extends StatefulWidget {
  final String fileName;
  const FlutterGame({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<FlutterGame> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      // postProcessor: ([dt]){
      //   threeJs.renderer!.clear(true, true, true);
      // },
      settings: three.Settings(
        clearAlpha: 0,
        clearColor: 0xffffff
      ),
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    fpsControl.clearListeners();
    three.loading.clear();
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

  Map<LogicalKeyboardKey,bool> keyStates = {
    LogicalKeyboardKey.space: false,
    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
  };

  late three.FirstPersonControls fpsControl;
  late three.AnimationMixer mixer;
  late final three.Vector3 playerVelocity;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 10);
    fpsControl = three.FirstPersonControls(
      camera: threeJs.camera, 
      listenableKey: threeJs.globalKey,
      lookType: three.LookType.position,
      offset: three.Vector3(10,10,10)
    );
    playerVelocity = fpsControl.velocity;
    
    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xffffff, 0.3);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.1);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    three.GLTFLoader loader = three.GLTFLoader(flipY: true).setPath('assets/models/gltf/flutter/');

    //final result = await loader.fromAsset( 'coffeemat.glb' );
    var sky = await loader.fromAsset( 'sky_sphere.glb' );
    threeJs.scene.add(sky!.scene);
    var ground = await loader.fromAsset('ground.glb');
    threeJs.scene.add(ground!.scene);

    final List<three.Vector3> coinPositions = [
      three.Vector3(-1.4 - 0.8 * 0, 1.5, -6 - 2 * 0),
      three.Vector3(-1.4 - 0.8 * 1, 1.5, -6 - 2 * 1),
      three.Vector3(-1.4 - 0.8 * 2, 1.5, -6 - 2 * 2),
      three.Vector3(-1.4 - 0.8 * 3, 1.5, -6 - 2 * 3),
      //
      three.Vector3(-15 + 2 * 0, 1.5, 0.5 - 1.2 * 0),
      three.Vector3(-15 + 2 * 1, 1.5, 0.5 - 1.2 * 1),
      three.Vector3(-15 + 2 * 2, 1.5, 0.5 - 1.2 * 2),
      three.Vector3(-15 + 2 * 3, 1.5, 0.5 - 1.2 * 3),
      //
      three.Vector3(7 + 2 * 0, 1.5, -16 + 1.3 * 0),
      three.Vector3(7 + 2 * 1, 1.5, -16.5 + 1.3 * 1),
      three.Vector3(7 + 2 * 2, 1.5, -16.5 + 1.3 * 2),
      three.Vector3(7 + 2 * 3, 1.5, -16 + 1.3 * 3),
    ];

    var coin = await loader.fromAsset('coin.glb');

    List<Coin> coins = []; 
    for(final pos in coinPositions){
      coins.add(Coin(pos,coin!.scene));
      threeJs.scene.add(coin.scene);
    }
    var logo = await loader.fromAsset('flutter_logo.glb');
    threeJs.scene.add(logo!.scene);

    var dash = await loader.fromAsset('dash.glb');
    final object = dash!.scene;
    threeJs.scene.add(object);
    mixer = three.AnimationMixer(object);
    mixer.clipAction(dash.animations![4])!.play();

    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
      fpsControl.update(dt);
    });
  }
}

class Coin {
  three.Vector3 position;
  double rotation = 0;
  bool collected = false;

  three.Vector3 startAnimPosition = three.Vector3.zero();
  double collectAnimation = 0;

  late three.Object3D object;

  Coin(this.position, three.Object3D object){
    this.object = object.clone();
    object.position = position;
  }

  void update(three.Vector3 playerPosition, double deltaSeconds) {
    if (collected && collectAnimation == 1) {
      return;
    }

    if (!collected) {
      double distance = playerPosition.sub(position).length;
      if (distance < 2.2) {
        collected = true;
        startAnimPosition = position;
      }
    }
    if (collected) {
      collectAnimation = math.min(1, collectAnimation + deltaSeconds * 2);
      object.position.y = startAnimPosition.y + math.sin(collectAnimation * 5) * 0.4;
      rotation += deltaSeconds * 10;
    }

    rotation += deltaSeconds * 2;
  }
}

class Charcter{
  
}