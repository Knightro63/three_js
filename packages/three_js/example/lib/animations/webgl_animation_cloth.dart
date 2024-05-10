import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class webgl_animation_cloth extends StatefulWidget {
  String fileName;

  webgl_animation_cloth({Key? key, required this.fileName}) : super(key: key);

  @override
  createState() => _State();
}

double restDistance = 25;

int xSegs = 10;
int ySegs = 10;

final DRAG = 1 - 0.03;

final DAMPING = 0.03;
final MASS = 0.1;

class _State extends State<webgl_animation_cloth> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  late three.AnimationMixer mixer;
  three.Clock clock = three.Clock();
  three.OrbitControls? controls;

  double dpr = 1.0;

  final AMOUNT = 4;

  int startTime = 0;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic sourceTexture;

  bool loaded = false;

  late three.Object3D model;

  late ParametricGeometry clothGeometry;

  Map<String, dynamic> params = {"enableWind": true, "showBall": true};

  List pins = [];

  final windForce = three.Vector3(0, 0, 0);

  final ballPosition = three.Vector3(0, -45, 0);
  final ballSize = 60.0; //40

  final tmpForce = three.Vector3();
  final diff = three.Vector3();

  late Cloth cloth;

  final GRAVITY = 981 * 1.4;
  final gravity = three.Vector3(0, -981 * 1.4, 0).scale(0.1);

  final TIMESTEP = 18 / 1000;
  final TIMESTEP_SQ = (18 / 1000) * (18 / 1000);

  late three.Mesh sphere;

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
                  child: Container(
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
                      }))),
            ],
          ),
        ),
      ],
    );
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

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
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
    renderer!.shadowMap.enabled = true;

    if (!kIsWeb) {
      final pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
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

  // plane( width, height ) {

  //   return ( u, v, target ) {

  //     final x = ( u - 0.5 ) * width;
  //     final y = ( v + 0.5 ) * height;
  //     final z = 0;

  //     target.set( x, y, z );

  //   };

  // }

  // final clothFunction = plane( restDistance * xSegs, restDistance * ySegs );

  satisfyConstraints(p1, p2, distance) {
    diff.sub2(p2.position, p1.position);
    final currentDist = diff.length;
    if (currentDist == 0) return; // prevents division by 0
    final correction = diff.scale(1 - distance / currentDist);
    final correctionHalf = correction.scale(0.5);
    p1.position.add(correctionHalf);
    p2.position.sub(correctionHalf);
  }

  simulate(now) {
    final windStrength = math.cos(now / 7000) * 20 + 40;

    windForce.setValues(math.sin(now / 2000), math.cos(now / 3000),math.sin(now / 1000));
    windForce.normalize();
    windForce.scale(windStrength);

    // Aerodynamics forces

    final particles = cloth.particles;

    if (params["enableWind"]) {
      final normal = three.Vector3();
      final indices = clothGeometry.index!;
      final normals = clothGeometry.attributes["normal"];

      for (int i = 0, il = indices.count; i < il; i += 3) {
        for (int j = 0; j < 3; j++) {
          int indx = indices.getX(i + j)!.toInt();
          normal.fromBuffer(normals, indx);
          tmpForce
              .setFrom(normal)
              .normalize()
              .scale(normal.dot(windForce));
          particles[indx].addForce(tmpForce);
        }
      }
    }

    for (int i = 0, il = particles.length; i < il; i++) {
      final particle = particles[i];
      particle.addForce(gravity);

      particle.integrate(TIMESTEP_SQ);
    }

    // Start Constraints

    final constraints = cloth.constraints;
    final il = constraints.length;

    for (int i = 0; i < il; i++) {
      final constraint = constraints[i];
      satisfyConstraints(constraint[0], constraint[1], constraint[2]);
    }

    // Ball Constraints

    ballPosition.z = -math.sin(now / 600) * 90; //+ 40;
    ballPosition.x = math.cos(now / 400) * 70;

    if (params["showBall"]) {
      sphere.visible = true;

      for (int i = 0, il = particles.length; i < il; i++) {
        final particle = particles[i];
        final pos = particle.position;
        diff.sub2(pos, ballPosition);
        if (diff.length < ballSize) {
          // collided
          diff.normalize().scale(ballSize);
          pos.setFrom(ballPosition).add(diff);
        }
      }
    } else {
      sphere.visible = false;
    }

    // Floor Constraints

    for (int i = 0, il = particles.length; i < il; i++) {
      final particle = particles[i];
      final pos = particle.position;
      if (pos.y < -250) {
        pos.y = -250;
      }
    }

    // Pin Constraints

    for (int i = 0, il = pins.length; i < il; i++) {
      final xy = pins[i];
      final p = particles[xy];
      p.position.setFrom(p.original);
      p.previous.setFrom(p.original);
    }
  }

  initPage() async {
    /* testing cloth simulation */

    cloth = Cloth(xSegs, ySegs);

    final pinsFormation = [];
    pins = [6];

    pinsFormation.add(pins);

    pins = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    pinsFormation.add(pins);

    pins = [0];
    pinsFormation.add(pins);

    pins = []; // cut the rope ;)
    pinsFormation.add(pins);

    pins = [0, cloth.w]; // classic 2 pins
    pinsFormation.add(pins);

    pins = pinsFormation[1];

    togglePins() {
      // pins = pinsFormation[ ~ ~ ( math.random() * pinsFormation.length ) ];
    }

    // scene

    scene = three.Scene();
    scene.background = three.Color.fromHex32(0xcce0ff);
    scene.fog = three.Fog(three.Color.fromHex32(0xcce0ff), 500, 10000);

    // camera

    camera = three.PerspectiveCamera(30, width / height, 1, 10000);
    camera.position.setValues(1000, 50, 1500);

    // lights

    camera.lookAt(scene.position);

    scene.add(three.AmbientLight(0x666666, 1));

    final light = three.DirectionalLight(0xdfebff, 1);
    light.position.setValues(50, 200, 100);
    light.position.scale(1.3);

    light.castShadow = true;

    light.shadow!.mapSize.width = 1024;
    light.shadow!.mapSize.height = 1024;

    final d = 300.0;

    light.shadow!.camera!.left = -d;
    light.shadow!.camera!.right = d;
    light.shadow!.camera!.top = d;
    light.shadow!.camera!.bottom = -d;

    light.shadow!.camera!.far = 1000;

    scene.add(light);

    // cloth material

    final loader = three.TextureLoader();
    final clothTexture = await loader.fromAsset('assets/textures/patterns/circuit_pattern.png');
    // clothTexture.anisotropy = 16;

    final clothMaterial = three.MeshLambertMaterial.fromMap({"alphaMap": clothTexture, "side": three.DoubleSide, "alphaTest": 0.5});

    // cloth geometry

    clothGeometry = ParametricGeometry(clothFunction, cloth.w, cloth.h);

    // cloth mesh

    object = three.Mesh(clothGeometry, clothMaterial);
    object.position.setValues(0, 0, 0);
    object.castShadow = true;
    scene.add(object);

    // sphere

    final ballGeo = three.SphereGeometry(ballSize, 32, 16);
    final ballMaterial = three.MeshLambertMaterial();

    sphere = three.Mesh(ballGeo, ballMaterial);
    sphere.castShadow = true;
    sphere.receiveShadow = true;
    sphere.visible = false;
    scene.add(sphere);

    // ground

    final groundTexture = await loader.fromAsset('assets/textures/terrain/grasslight-big.jpg');
    groundTexture!.wrapS = groundTexture.wrapT = three.RepeatWrapping;
    groundTexture.repeat.setValues(25, 25);
    groundTexture.anisotropy = 16;
    groundTexture.encoding = three.sRGBEncoding;

    final groundMaterial = three.MeshLambertMaterial.fromMap({"map": groundTexture});

    three.Mesh mesh = three.Mesh(three.PlaneGeometry(20000, 20000), groundMaterial);
    mesh.position.y = -250;
    mesh.rotation.x = -math.pi / 2;
    mesh.receiveShadow = true;
    scene.add(mesh);

    // poles

    final poleGeo = three.BoxGeometry(5, 375, 5);
    final poleMat = three.MeshLambertMaterial();

    mesh = three.Mesh(poleGeo, poleMat);
    mesh.position.x = -125;
    mesh.position.y = -62;
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    scene.add(mesh);

    mesh = three.Mesh(poleGeo, poleMat);
    mesh.position.x = 125;
    mesh.position.y = -62;
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    scene.add(mesh);

    mesh = three.Mesh(three.BoxGeometry(255, 5, 5), poleMat);
    mesh.position.y = -250 + (750 / 2);
    mesh.position.x = 0;
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    scene.add(mesh);

    final gg = three.BoxGeometry(10, 10, 10);
    mesh = three.Mesh(gg, poleMat);
    mesh.position.y = -250;
    mesh.position.x = 125;
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    scene.add(mesh);

    mesh = three.Mesh(gg, poleMat);
    mesh.position.y = -250;
    mesh.position.x = -125;
    mesh.receiveShadow = true;
    mesh.castShadow = true;
    scene.add(mesh);

    loaded = true;
    startTime = DateTime.now().millisecondsSinceEpoch;

    animate();

    // scene.overrideMaterial = new three.MeshBasicMaterial();
  }

  clickRender() {
    print("clickRender..... ");
    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    final delta = clock.getDelta();

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    simulate(currentTime - startTime);

    final p = cloth.particles;

    for (int i = 0, il = p.length; i < il; i++) {
      final v = p[i].position;
      clothGeometry.attributes["position"].setXYZ(i, v.x, v.y, v.z);
    }

    clothGeometry.attributes["position"].needsUpdate = true;
    clothGeometry.computeVertexNormals();
    sphere.position.setFrom(ballPosition);

    render();

    Future.delayed(const Duration(milliseconds: 33), () {
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

class Particle {
  late three.Vector3 position;
  late three.Vector3 previous;
  late three.Vector3 original;
  late three.Vector3 a;

  dynamic mass;
  late num invMass;

  late three.Vector3 tmp;
  late three.Vector3 tmp2;

  Particle(x, y, z, mass) {
    position = three.Vector3();
    previous = three.Vector3();
    original = three.Vector3();
    a = three.Vector3(0, 0, 0); // acceleration
    this.mass = mass;
    invMass = 1 / mass;
    tmp = three.Vector3();
    tmp2 = three.Vector3();

    // init

    clothFunction(x, y, position); // position
    clothFunction(x, y, previous); // previous
    clothFunction(x, y, original);
  }

  // Force -> Acceleration

  addForce(force) {
    a.add(tmp2.setFrom(force).scale(invMass));
  }

  // Performs Verlet integration

  integrate(timesq) {
    final newPos = tmp.sub2(position, previous);
    newPos.scale(DRAG).add(position);
    newPos.add(a.scale(timesq));

    tmp = previous;
    previous = position;
    position = newPos;

    a.setValues(0, 0, 0);
  }
}

class Cloth {
  late int w;
  late int h;

  late List<Particle> particles;
  late List<dynamic> constraints;

  Cloth([this.w = 10, this.h = 10]) {
    List<Particle> particles = [];
    List<dynamic> constraints = [];

    // Create particles

    for (int v = 0; v <= h; v++) {
      for (int u = 0; u <= w; u++) {
        particles.add(Particle(u / w, v / h, 0, MASS));
      }
    }

    // Structural

    for (int v = 0; v < h; v++) {
      for (int u = 0; u < w; u++) {
        constraints.add(
            [particles[index(u, v)], particles[index(u, v + 1)], restDistance]);

        constraints.add(
            [particles[index(u, v)], particles[index(u + 1, v)], restDistance]);
      }
    }

    for (int u = w, v = 0; v < h; v++) {
      constraints.add(
          [particles[index(u, v)], particles[index(u, v + 1)], restDistance]);
    }

    for (int v = h, u = 0; u < w; u++) {
      constraints.add(
          [particles[index(u, v)], particles[index(u + 1, v)], restDistance]);
    }

    this.particles = particles;
    this.constraints = constraints;
  }

  index(u, v) {
    return u + v * (w + 1);
  }
}

clothFunction(u, v, target) {
  double width = restDistance * xSegs;
  double height = restDistance * ySegs;

  double x = (u - 0.5) * width;
  double y = (v + 0.5) * height;
  double z = 0.0;

  target.setValues(x, y, z);
}
