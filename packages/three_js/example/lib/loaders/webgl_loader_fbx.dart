import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;

class webgl_loader_fbx extends StatefulWidget {
  String fileName;
  webgl_loader_fbx({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_loader_fbx> {
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

  var AMOUNT = 4;

  bool verbose = false;
  bool disposed = false;

  three.Clock clock = three.Clock();

  three.AnimationMixer? mixer;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  final GlobalKey<three.PeripheralsState> _globalKey =
      GlobalKey<three.PeripheralsState>();

  late three.OrbitControls controls;

  @override
  void initState() {
    super.initState();
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

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
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

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;
    final _gl = three3dRender.gl;

    if(mixer == null) {
      return;
    }

    var delta = clock.getDelta();

    mixer!.update(delta);

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    _gl.flush();

    // var pixels = _gl.readCurrentPixels(0, 0, 10, 10);
    // print(" --------------pixels............. ");
    // print(pixels);

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
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
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    var ASPECTRATIO = width / height;

    var WIDTH = (width / AMOUNT) * dpr;
    var HEIGHT = (height / AMOUNT) * dpr;

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xcccccc);
    scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    camera = three.PerspectiveCamera(60, width / height, 1, 2000);
    camera.position.setValues( 100, 200, 300 );

    // controls

    controls = three.OrbitControls(camera, _globalKey);

    controls.enableDamping =
        true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 100;
    controls.maxDistance = 500;

    controls.maxPolarAngle = math.pi / 2;

    scene = three.Scene();
    scene.background = three.Color.fromHex32( 0xa0a0a0 );
    scene.fog = three.Fog( three.Color.fromHex32( 0xa0a0a0 ), 200, 1000 );

    var hemiLight = three.HemisphereLight( 0xffffff, 0x444444 );
    hemiLight.position.setValues( 0, 200, 0 );
    scene.add( hemiLight );

    var dirLight = three.DirectionalLight( 0xffffff );
    dirLight.position.setValues( 0, 200, 100 );
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 180;
    dirLight.shadow!.camera!.bottom = - 100;
    dirLight.shadow!.camera!.left = - 120;
    dirLight.shadow!.camera!.right = 120;
    scene.add( dirLight );

    // scene.add( new three.CameraHelper( dirLight.shadow!.camera ) );

    // ground
    // var mesh = new three.Mesh( new three.PlaneGeometry( 2000, 2000 ), new three.MeshPhongMaterial( { "color": 0x999999, "depthWrite": false } ) );
    // mesh.rotation.x = - math.pi / 2;
    // mesh.receiveShadow = true;
    // scene.add( mesh );

    // var grid = new three.GridHelper( 2000, 20, 0x000000, 0x000000 );
    // grid.material.opacity = 0.2;
    // grid.material.transparent = true;
    // scene.add( grid );

    var textureLoader = three.TextureLoader(null);
    textureLoader.flipY = true;
    //var diffueTexture = await textureLoader.loadAsync("assets/models/fbx/model_tex_u1_v1_diffuse.jpg", null);
    //var normalTexture = await textureLoader.loadAsync("assets/models/fbx/model_tex_u1_v1_normal.jpg", null);

    // model
    var loader = three.FBXLoader(width: width.toInt(), height: height.toInt());
    // var object = await loader.loadAsync( 'assets/models/fbx/Samba Dancing.fbx');
    var object = await loader.fromAsset( 'assets/models/fbx/SambaDancing.fbx');
    mixer = three.AnimationMixer(object!);

    var action = mixer!.clipAction( object.animations[ 1 ] );
    action!.play();

    object!.traverse( ( child ) {

      if ( child is three.Mesh ) {

        child.castShadow = true;
        child.receiveShadow = true;
      }

    } );

    scene.add( object );

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
