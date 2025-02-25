import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:flutter/services.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExampleApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FlutterGame(),
    );
  }
}

class FlutterGame extends StatefulWidget {
  const FlutterGame({super.key});

  @override
  _FlutterGameState createState() => _FlutterGameState();
}

class _FlutterGameState extends State<FlutterGame> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    joystick?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  Map<LogicalKeyboardKey,bool> keyStates = {
    LogicalKeyboardKey.space: false,
    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
  };

  double gravity = 30;
  int stepsPerFrame = 5;
  three.Joystick? joystick;
  
  Future<void> setup() async {
    joystick = threeJs.width < 850?three.Joystick(
      size: 150,
      margin: const EdgeInsets.only(left: 35, bottom: 35),
      screenSize: Size(threeJs.width, threeJs.height), 
      listenableKey: threeJs.globalKey
    ):null;
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 10);

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xffffff, 0.3);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.1);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    three.GLTFLoader loader = three.GLTFLoader(flipY: true).setPath('assets/');

    final sky = await loader.fromAsset( 'sky_sphere.glb' );
    threeJs.scene.add(sky!.scene);

    final groundGLB = await loader.fromAsset('ground.glb');
    final ground = groundGLB!.scene;
    ground.rotation.y = 90*(math.pi/180);
    threeJs.scene.add(ground);

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

    final coin = await loader.fromAsset('coin.glb');
    List<Coin> coins = []; 
    for(final pos in coinPositions){
      final object = coin!.scene.clone();
      coins.add(Coin(pos,object));
      threeJs.scene.add(object);
    }

    final dash = await loader.fromAsset('dash.glb');
    Player player = Player(
      dash!.scene,dash.animations!,
      threeJs.camera,
      threeJs.globalKey,
      joystick
    );
    threeJs.scene.add(dash.scene);

    threeJs.addAnimationEvent((dt){
      joystick?.update();
      player.update(dt);
      for(final coin in coins){
        coin.update(player.position, dt);
      }
    });
    
    threeJs.renderer?.autoClear = false; // To allow render overlay on top of sprited sphere
    if(joystick != null){
      threeJs.postProcessor = ([double? dt]){
        threeJs.renderer!.setViewport(0,0,threeJs.width,threeJs.height);
        threeJs.renderer!.clear();
        threeJs.renderer!.render( threeJs.scene, threeJs.camera );
        threeJs.renderer!.clearDepth();
        threeJs.renderer!.render( joystick!.scene, joystick!.camera);
      };
    }
  }
}

class Coin {
  three.Vector3 position;
  bool collected = false;

  three.Vector3 startAnimPosition = three.Vector3.zero();
  double collectAnimation = 0;

  late three.Object3D object;

  Coin(this.position, this.object){
    object.position = position;
  }

  void update(three.Vector3 playerPosition, double dt) {
    if (collected && collectAnimation == 1) {
      object.visible = false;
      return;
    }

    if (!collected) {
      double distance = playerPosition.clone().sub(position).length;
      if (distance < 2.2) {
        collected = true;
        startAnimPosition = position;
      }
    }
    if (collected) {
      collectAnimation = math.min(1, collectAnimation + dt * 2);
      object.position.y = startAnimPosition.y + math.sin(collectAnimation * 5) * 0.4;
      object.rotation.y *= 5;
    }
    object.rotation.y += 0.07;
  }
}

enum PlayerAction{blink,idle,walk,run}

class Player{
  three.Joystick? joystick;
  three.Vector3 get position => object.position;
  late three.Object3D object;
  late three.AnimationMixer mixer;
  late List animations;

  late final three.Vector3 playerVelocity;
  bool playerOnFloor = false;

  PlayerAction currentAction = PlayerAction.idle;
  late three.ThirdPersonControls tpsControl;
  Map<PlayerAction,three.AnimationAction> actions = {};

  Player(
    this.object, 
    this.animations, three.Camera camera, 
    GlobalKey<three.PeripheralsState> globalKey,
    [this.joystick]
  ){
    mixer = three.AnimationMixer(object);
    actions = {
      PlayerAction.blink: mixer.clipAction(animations[0])!,
      PlayerAction.idle: mixer.clipAction(animations[2])!,
      PlayerAction.walk: mixer.clipAction(animations[4])!,
      PlayerAction.run: mixer.clipAction(animations[3])!
    };

    for(final act in actions.keys){
			actions[act]!.enabled = true;
      actions[act]!.setEffectiveTimeScale( 1 );
      double weight = 0;
      if(act == PlayerAction.idle){
        weight = 1;
      }
      actions[act]!.setEffectiveWeight( weight );
      actions[act]!.play();
    }

    camera.rotation.x = math.sin(-60*(math.pi/180));

    tpsControl = three.ThirdPersonControls(
      camera: camera, 
      listenableKey: globalKey,
      object: object,
      offset: three.Vector3(5,15,10),
      movementSpeed: 5
    );

    playerVelocity = tpsControl.velocity;
  }

  void deactivateActions(){
    for(final act in actions.keys){
      actions[act]!.setEffectiveWeight( 0 );
    }
  }

  void updateAction(PlayerAction action){
    if(currentAction == action) return;
    currentAction = action;
    deactivateActions();
    actions[action]!.setEffectiveWeight( 1 );
  }

  void _updateDirection(){
    tpsControl.moveBackward= false;
    tpsControl.moveLeft = false;
    tpsControl.moveForward = false;
    tpsControl.moveRight = false;

    object.rotation.y = -joystick!.radians-math.pi/2;
    if(joystick!.isMoving){
      tpsControl.moveForward = true;
      tpsControl.movementSpeed = joystick!.intensity*5;
    }
    else{
      tpsControl.movementSpeed = 5;
    }
  }
  void update(double dt) {
    tpsControl.update(dt);
    if(joystick != null){
      _updateDirection();
    }

    if(tpsControl.isMoving){
      if(tpsControl.movementSpeed > 4){
        updateAction(PlayerAction.run);
      }
      else{
        updateAction(PlayerAction.walk);
      }
    }
    else{
      updateAction(PlayerAction.idle);
    }

    mixer.update(dt);
  }

  void dispose() {
    tpsControl.clearListeners();
  }
}