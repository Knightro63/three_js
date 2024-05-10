import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class SphereData{
  SphereData({
    required this.mesh,
    required this.collider,
    required this.velocity
  });

  three.Mesh mesh;
  three.BoundingSphere collider;
  three.Vector3 velocity;
}

class TestGame extends StatefulWidget {
  const TestGame({
    Key? key,
    required this.fileName
  }) : super(key: key);

  final String fileName;

  @override
  _TestGamePageState createState() => _TestGamePageState();
}

class _TestGamePageState extends State<TestGame> {
  FocusNode node = FocusNode();
  late three.FirstPersonControls fpsControl;
  // gl values
  //late Object3D object;
  bool animationReady = false;
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderTarget? renderTarget;
  three.WebGLRenderer? renderer;
  int? fboId;
  late double width;
  late double height;
  Size? screenSize;
  late three.Scene scene;
  late three.Camera camera;
  double dpr = 1.0;
  bool verbose = false;
  bool disposed = false;
  final GlobalKey<three.PeripheralsState> _globalKey = GlobalKey<three.PeripheralsState>();
  dynamic sourceTexture;

  int stepsPerFrame = 5;
  three.Clock clock = three.Clock();

  double gravity = 30;

  List<SphereData> spheres = [];
  int sphereIdx = 0;

  Octree worldOctree = Octree();
  Capsule playerCollider = Capsule(three.Vector3( 0, 0.35, 0 ), three.Vector3( 0, 1, 0 ), 0.35);

  bool playerOnFloor = false;
  int mouseTime = 0;
  Map<LogicalKeyboardKey,bool> keyStates = {
    LogicalKeyboardKey.keyW: false,
    LogicalKeyboardKey.keyA: false,
    LogicalKeyboardKey.keyS: false,
    LogicalKeyboardKey.keyD: false,
    LogicalKeyboardKey.space: false,

    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
  };

  three.Vector3 vector1 = three.Vector3();
  three.Vector3 vector2 = three.Vector3();
  three.Vector3 vector3 = three.Vector3();

  late final three.Vector3 playerVelocity;

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    disposed = true;
    three3dRender.dispose();
    super.dispose();
  }
  
  void initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }
  void animate() {
    if (!mounted || disposed) {
      return;
    }
    double deltaTime = math.min(0.05, clock.getDelta())/stepsPerFrame;
    if(deltaTime != 0){
      for (int i = 0; i < stepsPerFrame; i ++) {
        fpsControl.update(deltaTime);
        updatePlayer(deltaTime);
        updateSpheres(deltaTime);
        teleportPlayerIfOob();
      }
    }
    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }
  Future<void> initPage() async {
    scene = three.Scene();
    scene.background = three.Color(0x88ccee);

    camera = three.PerspectiveCamera(70, width / height, 0.1, 1000);
    camera.rotation.order = three.RotationOrders.yxz;

    // lights
    three.HemisphereLight fillLight1 = three.HemisphereLight( 0x4488bb, 0x002244, 0.5 );
    fillLight1.position.setValues( 2, 1, 1 );
    scene.add(fillLight1);

    three.DirectionalLight directionalLight = three.DirectionalLight( 0xffffff, 0.8 );
    directionalLight.position.setValues( - 5, 25, - 1 );
    directionalLight.castShadow = true;

    directionalLight.shadow!.camera!.near = 0.01;
    directionalLight.shadow!.camera!.far = 500;
    directionalLight.shadow!.camera!.right = 30;
    directionalLight.shadow!.camera!.left = - 30;
    directionalLight.shadow!.camera!.top	= 30;
    directionalLight.shadow!.camera!.bottom = - 30;
    directionalLight.shadow!.mapSize.width = 1024;
    directionalLight.shadow!.mapSize.height = 1024;
    directionalLight.shadow!.radius = 4;
    directionalLight.shadow!.bias = - 0.00006;

    scene.add(directionalLight);

    three.GLTFLoader().setPath('assets/models/gltf/').fromAsset('collision-world.glb').then((gltf){
      three.Object3D object = gltf!.scene;
      scene.add(object);
      worldOctree.fromGraphNode(object);

      OctreeHelper helper = OctreeHelper(worldOctree);
      helper.visible = true;
      scene.add(helper);

      object.traverse((child){
        if(child.type == 'Mesh'){
          three.Object3D part = child;
          part.castShadow = true;
          part.visible = true;
          part.receiveShadow = true;
        }
      });
    });

    fpsControl = three.FirstPersonControls(camera, _globalKey);
    fpsControl.lookSpeed = 1/100;
    fpsControl.movementSpeed = 15.0;
    fpsControl.lookType = three.LookType.position;
    playerVelocity = fpsControl.velocity;
    fpsControl.domElement.addEventListener(three.PeripheralType.keyup, (event){
      if(event.keyId == 32){
        playerVelocity.y = 15;
      }
    }, false );
    fpsControl.domElement.addEventListener(three.PeripheralType.pointerup, (event){
      throwBall();
    }, false );
    animationReady = true;
  }
  void render() {
    final _gl = three3dRender.gl;
    renderer!.render(scene, camera);
    _gl.flush();
    if(!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }
  void initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
    };

    if(!kIsWeb && Platform.isAndroid){
      _options['logarithmicDepthBuffer'] = true;
    }

    renderer = three.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    if(!kIsWeb){
      three.WebGLRenderTargetOptions pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat,"samples": 8});
      renderTarget = three.WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget!.samples = 8;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
    else{
      renderTarget = null;
    }
  }
  void initScene() async{
    await initPage();
    initRenderer();
    animate();
  }
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": true,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
      'precision': 'highp'
    };
    await three3dRender.initialize(options: _options);

    setState(() {});

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
    });
  }

  void throwBall() {
    double sphereRadius = 0.2;
    IcosahedronGeometry sphereGeometry = IcosahedronGeometry( sphereRadius, 5 );
    three.MeshLambertMaterial sphereMaterial = three.MeshLambertMaterial.fromMap({'color': 0xbbbb44});

    final three.Mesh newsphere = three.Mesh( sphereGeometry, sphereMaterial );
    newsphere.castShadow = true;
    newsphere.receiveShadow = true;

    scene.add( newsphere );
    spheres.add(SphereData(
      mesh: newsphere,
      collider: three.BoundingSphere(three.Vector3( 0, - 100, 0 ), sphereRadius),
      velocity: three.Vector3()
    ));
    SphereData sphere = spheres.last;
    camera.getWorldDirection( fpsControl.targetPosition );
    sphere.collider.center.setFrom(playerCollider.end).addScaled( fpsControl.targetPosition, playerCollider.radius * 1.5 );
    // throw the ball with more force if we hold the button longer, and if we move forward
    double impulse = 15 + 15 * ( 1 - math.exp((mouseTime-DateTime.now().millisecondsSinceEpoch) * 0.001));
    sphere.velocity.setFrom( fpsControl.targetPosition ).scale( impulse );
    sphere.velocity.addScaled( playerVelocity, 2 );
    sphereIdx = ( sphereIdx + 1 ) % spheres.length;
  }
  
  void playerCollisions() {
    OctreeData? result = worldOctree.capsuleIntersect(playerCollider);
    playerOnFloor = false;
    if(result != null){
      playerOnFloor = result.normal.y > 0;
      if(!playerOnFloor) {
        playerVelocity.addScaled(
          result.normal, 
          -result.normal.dot(playerVelocity)
        );
      }
      if(result.depth > 0.02){
        playerCollider.translate(result.normal.scale(result.depth));
      }
    }
  }
  void updatePlayer(double deltaTime) {
    double damping = math.exp(-4 * deltaTime) -1;
    if(!playerOnFloor){
      playerVelocity.y -= gravity * deltaTime;
      // small air resistance
      damping *= 0.1;
    }

    playerVelocity.addScaled( playerVelocity, damping );
    three.Vector3 deltaPosition = playerVelocity.clone().scale( deltaTime );
    playerCollider.translate(deltaPosition);
    playerCollisions();
    camera.position.setFrom(playerCollider.end);
  }
  void playerSphereCollision(SphereData sphere) {
    three.Vector3 center = vector1.add2(playerCollider.start, playerCollider.end ).scale( 0.5 );
    final sphereCenter = sphere.collider.center;
    double r = playerCollider.radius + sphere.collider.radius;
    double r2 = r*r;

    // approximation: player = 3 spheres
    List<three.Vector3> temp = [playerCollider.start,playerCollider.end,center];
    for(three.Vector3 point in temp) {
      num d2 = point.distanceToSquared(sphereCenter);
      if ( d2 < r2 ) {
        three.Vector3 normal = vector1.sub2(point, sphereCenter).normalize();
        three.Vector3 v1 = vector2.setFrom( normal ).scale( normal.dot( playerVelocity ) );
        three.Vector3 v2 = vector3.setFrom( normal ).scale( normal.dot( sphere.velocity) );

        playerVelocity.add(v2).sub(v1);
        sphere.velocity.add(v1).sub(v2);

        double d = ( r - math.sqrt( d2 ) ) / 2;
        sphereCenter.addScaled( normal, - d );
      }
    }
  }
  
  void spheresCollisions() {
    for (int i = 0, length = spheres.length; i < length; i ++ ) {
      SphereData s1 = spheres[ i ];
      for (int j = i + 1; j < length; j ++ ) {
        SphereData s2 = spheres[ j ];
        num d2 = s1.collider.center.distanceToSquared(s2.collider.center);
        double r = s1.collider.radius + s2.collider.radius;
        double r2 = r * r;

        if ( d2 < r2 ) {
          three.Vector3 normal = vector1.sub2( s1.collider.center, s2.collider.center ).normalize();
          three.Vector3 v1 = vector2.setFrom( normal ).scale( normal.dot( s1.velocity));
          three.Vector3 v2 = vector3.setFrom( normal ).scale( normal.dot( s2.velocity));

          s1.velocity.add( v2 ).sub( v1 );
          s2.velocity.add( v1 ).sub( v2 );

          double d = ( r - math.sqrt( d2 ) ) / 2;

          s1.collider.center.addScaled( normal, d );
          s2.collider.center.addScaled( normal, - d );
        }
      }
    }
  }
  void updateSpheres(double deltaTime) {
    spheres.forEach((sphere) {
      sphere.collider.center.addScaled(sphere.velocity, deltaTime);
      OctreeData? result = worldOctree.sphereIntersect(sphere.collider);
      if(result != null) {
        sphere.velocity.addScaled( result.normal, - result.normal.dot( sphere.velocity) * 1.5 );
        sphere.collider.center.add( result.normal.scale( result.depth ) );
      } 
      else{
        sphere.velocity.y -= gravity * deltaTime;
      }

      double damping = math.exp(- 1.5*deltaTime) - 1;
      sphere.velocity.addScaled(sphere.velocity, damping);

      playerSphereCollision(sphere);
    });

    spheresCollisions();

    for (SphereData sphere in spheres){
      sphere.mesh.position.setFrom(sphere.collider.center);
    }
  }

  void teleportPlayerIfOob(){
    if(camera.position.y <= - 25){
      playerCollider.start.set(0,0.35,0);
      playerCollider.end.set(0,1,0);
      playerCollider.radius = 0.35;
      camera.position.setFrom(playerCollider.end);
      camera.rotation.set(0,0,0);
    }
  }

  Widget threeDart() {
    return Builder(builder: (BuildContext context) {
      initSize(context);
      return Container(
        width: screenSize!.width,
        height: screenSize!.height,
        color: Theme.of(context).canvasColor,
        child: three.Peripherals(
          key: _globalKey,
          builder: (BuildContext context) {
            FocusScope.of(context).requestFocus(node);
            return Container(
              width: width,
              height: height,
              color: Theme.of(context).canvasColor,
              child: Builder(builder: (BuildContext context) {
                if (kIsWeb) {
                  return three3dRender.isInitialized
                      ? HtmlElementView(
                          viewType:
                              three3dRender.textureId!.toString())
                      : Container();
                } else {
                  return three3dRender.isInitialized
                      ? Texture(textureId: three3dRender.textureId!)
                      : Container();
                }
              })
            );
          }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Stack(
        children: [
          threeDart(),
        ],
      )
    );
  }
}