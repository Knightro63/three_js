import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';
import 'package:three_js_controls/three_js_controls.dart';
import 'package:three_js_math/three_js_math.dart' as tmath;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglGeometries(),
    );
  }
}


class WebglGeometries extends StatefulWidget {
  const WebglGeometries({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometries> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  double dpr = 1.0;

  final int amount = 4;

  bool verbose = false;
  bool disposed = false;

  three.Clock clock = three.Clock();

  AnimationMixer? mixer;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three.PeripheralsState> _globalKey = GlobalKey<three.PeripheralsState>();

  late OrbitControls controls;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height - 60;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: _options);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
    });
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

  void render() {
    int _t = DateTime.now().millisecondsSinceEpoch;
    final _gl = three3dRender.gl;

    if(mixer == null) {
      return;
    }

    final delta = clock.getDelta();

    mixer!.update(delta);

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    _gl.flush();
    
    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  void initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };

    if(!kIsWeb){
      _options['logarithmicDepthBuffer'] = true;
    }

    renderer = three.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    if (!kIsWeb) {
      final pars = three.WebGLRenderTargetOptions({
        "minFilter": tmath.LinearFilter,
        "magFilter": tmath.LinearFilter,
        "format": tmath.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  void initScene() {
    initRenderer();
    initPage();
  }

  Future<void> initPage() async {
    scene = three.Scene();
    scene.background = tmath.Color.fromHex32( 0xa0a0a0 );
    scene.fog = three.Fog( tmath.Color.fromHex32( 0xa0a0a0 ), 200, 1000 );

    camera = three.PerspectiveCamera(60, width / height, 1, 2000);
    camera.position.setValues( 100, 200, 300 );

    // controls

    controls = OrbitControls(camera, _globalKey);

    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 100;
    controls.maxDistance = 500;

    controls.maxPolarAngle = math.pi / 2;



    final hemiLight = three.HemisphereLight( 0xffffff, 0x444444 );
    hemiLight.position.setValues( 0, 200, 0 );
    scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff );
    dirLight.position.setValues( 0, 200, 100 );
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 180;
    dirLight.shadow!.camera!.bottom = - 100;
    dirLight.shadow!.camera!.left = - 120;
    dirLight.shadow!.camera!.right = 120;
    scene.add( dirLight );

    // scene.add( new three.CameraHelper( dirLight.shadow!.camera ) );

    // ground
    // final mesh = new three.Mesh( new three.PlaneGeometry( 2000, 2000 ), new three.MeshPhongMaterial( { "color": 0x999999, "depthWrite": false } ) );
    // mesh.rotation.x = - three.Math.pi / 2;
    // mesh.receiveShadow = true;
    // scene.add( mesh );

    // final grid = new three.GridHelper( 2000, 20, 0x000000, 0x000000 );
    // grid.material.opacity = 0.2;
    // grid.material.transparent = true;
    // scene.add( grid );

    final textureLoader = TextureLoader();
    textureLoader.flipY = true;
    //final diffueTexture = await textureLoader.loadAsync("assets/models/fbx/model_tex_u1_v1_diffuse.jpg", null);
    //final normalTexture = await textureLoader.loadAsync("assets/models/fbx/model_tex_u1_v1_normal.jpg", null);

    // model
    final loader = FBXLoader(width: width.toInt(), height: height.toInt());
    
    // final object = await loader.loadAsync( 'assets/models/fbx/Samba Dancing.fbx');
    //final object = await loader.fromAsset( 'assets/stanford-bunny.fbx');
    final object = await loader.fromAsset( 'assets/SambaDancing.fbx');
    loader.dispose();
    textureLoader.dispose();
    mixer = AnimationMixer(object!);

    final action = mixer!.clipAction(object.animations[1]);
    action!.play();

    object.traverse( ( child ) {

      if ( child is three.Mesh ) {

        child.castShadow = true;
        child.receiveShadow = true;
      }

    } );

    scene.add( object );

    animate();
  }

  void animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: Stack(
            children: [
              three.Peripherals(
                  key: _globalKey,
                  builder: (BuildContext context) {
                    return Container(
                        width: width,
                        height: height,
                        color: Colors.black,
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
                        }));
                  }),
            ],
          ),
        ),
      ],
    );
  }
}

