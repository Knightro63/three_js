import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:three_js/three_js.dart' as three;

class webgl_loader_gltf_2 extends StatefulWidget {
  String fileName;
  webgl_loader_gltf_2({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_loader_gltf_2> {
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

  var amount = 4;

  bool verbose = false;
  bool disposed = false;

  bool loaded = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  three.AnimationMixer? mixer;
  three.Clock clock = three.Clock();

  dynamic? sourceTexture;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

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
          clickRender();
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
              Container(
                  width: width,
                  height: height,
                  color: Colors.black,
                  child: Builder(builder: (BuildContext context) {
                    if (kIsWeb) {
                      return three3dRender.isInitialized
                          ? HtmlElementView(
                              viewType: three3dRender.textureId!.toString())
                          : Container();
                    } else {
                      return three3dRender.isInitialized
                          ? Texture(textureId: three3dRender.textureId!)
                          : Container();
                    }
                  })),
            ],
          ),
        ),
      ],
    );
  }

  clickRender() {
    animate();
  }

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;

    final _gl = three3dRender.gl;

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

  initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
      renderTarget = three.WebGLMultisampleRenderTarget(
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
    camera = three.PerspectiveCamera(45, width / height, 1, 2200);
    camera.position.setValues(3, 6, -10);

    // scene

    scene = three.Scene();

    var ambientLight = three.AmbientLight(0xffffff, 0.9);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, -20);

    scene.add(pointLight);
    scene.add(camera);

    camera.lookAt(scene.position);

    var loader = three.GLTFLoader().setPath('assets/models/gltf/');

    // var result = await loader.loadAsync( 'Parrot.gltf');
    var result = await loader.fromAsset('Soldier.gltf');

    print(" gltf load sucess result: $result  ");

    object = result!.scene;

    // object.updateMatrixWorld(true);

    // object.traverse( ( child ) {
    //   if ( child.isMesh ) {
    // child.material.map = texture;
    //   }
    // } );

    // var skeleton = new three.SkeletonHelper( object );
    // skeleton.visible = true;
    // scene.add( skeleton );

    object.scale.setValues(2, 2, 2);
    object.rotation.set(0, 180 * math.pi/ 180.0, 0);

    // var clonedMesh = object.getObjectByName( "vanguard_Mesh" );

    // mixer = new three.AnimationMixer(clonedMesh );

    // var clip = three.AnimationClip.findByName( List<three.AnimationClip>.from(result["animations"]), "Walk" );
    // if ( clip != null ) {

    //   var action = mixer.clipAction( clip );
    //   action.play();

    // }

    scene.add(object);

    // scene.overrideMaterial = new three.MeshBasicMaterial();

    loaded = true;

    animate();
  }

  animate() {
    print("before animate render mounted: $mounted loaded: $loaded");

    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    print(" animate render ");

    var delta = clock.getDelta();

    mixer?.update(delta);

    render();

    // Future.delayed(Duration(milliseconds: 40), () {
    //   animate();
    // });
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
