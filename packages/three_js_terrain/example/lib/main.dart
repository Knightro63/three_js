import 'dart:typed_data';

import 'package:css/css.dart';
import 'package:example/change_image.dart';
import 'package:example/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'dart:math' as math;
import 'dart:async';
import 'package:three_js_terrain/three_js_terrain.dart' as terrain;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CSS.darkTheme,
      home: const TerrainPage(),
    );
  }
}

class TerrainPage extends StatefulWidget {
  const TerrainPage({super.key});
  @override
  State<TerrainPage> createState() => _TerrainPageState();
}

class _TerrainPageState extends State<TerrainPage> {
  late three.ThreeJS threeJs;
  late three.OrbitControls orbit;
  late three.FirstPersonControls controls;
  late three.PerspectiveCamera cameraPersp;
  late Gui gui;
  three.Material? blend;
  late Uint8List heightmap;
  
  @override
  void initState() {
    gui = Gui((){
      setState(() {
        
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
    threeJs.dispose();
    controls.dispose();
    orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          if(heightMapImage != null)Positioned(
            top: 20,
            left: 20,
            child: Image.memory(
              heightMapImage!,
              width: 120,
              fit: BoxFit.fitHeight,
            )
          ),
          if(heightMapImage != null)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render(context)
            )
          )
        ]
      )
    );
  }

  late three.DirectionalLight skyLight;
  late three.Mesh water;
  late three.DirectionalLight light;
  late three.Mesh skyDome;
  late three.Mesh sand;
  three.Object3D? terrainScene;
  Uint8List? heightMapImage;

  Future<void> setup() async{
    threeJs.scene = three.Scene();
    //threeJs.scene.fog = three.FogExp2(0x868293, 0.0007);

    threeJs.camera = three.PerspectiveCamera(60, threeJs.width / threeJs.height, 1, 10000);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.position.x = 449;
    threeJs.camera.position.y = 311;
    threeJs.camera.position.z = 376;
    threeJs.camera.rotation.x = -52 * math.pi / 180;
    threeJs.camera.rotation.y = 35 * math.pi / 180;
    threeJs.camera.rotation.z = 37 * math.pi / 180;

    orbit = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    //setupControls();
    
    await getHeightMapFromImage();
    await setupWorld();
    await settings();
    setupGui();

    threeJs.addAnimationEvent((dt){
      orbit.update();
    });
  }

  void setupControls() {
    final fpsCamera = three.PerspectiveCamera(60, threeJs.width / threeJs.height, 1, 10000);
    threeJs.scene.add(fpsCamera);
    controls = three.FirstPersonControls(camera: fpsCamera, listenableKey: threeJs.globalKey);
    controls.enabled = false;
    controls.movementSpeed = 100;
    controls.lookSpeed = 0.075;
  }
  void setupGui(){
    gui.addFolder('Heightmap')
    ..open()
    ..addDropDown(
      guiSettings,
      'heightmap', 
      ['Brownian', 'Cosine', 'CosineLayers', 'DiamondSquare', 'Fault', 'heightmap.png', 'Hill', 'HillIsland', 'influences', 'Particles', 'Perlin', 'PerlinDiamond', 'PerlinLayers', 'Simplex', 'SimplexLayers', 'Value', 'Weierstrass', 'Worley'],
    ).onFinishChange((){regenerate(blend);})
    ..addDropDown(
      guiSettings,
      'easing', 
      ['Linear', 'EaseIn', 'EaseInWeak', 'EaseOut', 'EaseInOut', 'InEaseOut']
    ).onFinishChange((){regenerate(blend);})
    ..addDropDown(
      guiSettings,
      'smoothing', 
      ['Conservative (0.5)', 'Conservative (1)', 'Conservative (10)', 'Gaussian (0.5, 7)', 'Gaussian (1.0, 7)', 'Gaussian (1.5, 7)', 'Gaussian (1.0, 5)', 'Gaussian (1.0, 11)', 'GaussianBox', 'Mean (0)', 'Mean (1)', 'Mean (8)', 'Median', 'None']
    ).onChange((val) {
      applySmoothing(val, lastOptions);
      scatterMeshes();
      if (lastOptions.heightmap != null) {
        terrain.Terrain.toHeightmap(terrainScene!.children[0].geometry!.attributes['position'].array.toDartList(), lastOptions);
      }
    })
    ..addSlider(guiSettings,'segments', 7, 127).onFinishChange((){regenerate(blend);})
    ..addSlider(guiSettings,'steps', 1, 8).onFinishChange((){regenerate(blend);})
    ..addCheckBox(guiSettings,'turbulent').onFinishChange((){regenerate(blend);});

    var decoFolder = gui.addFolder('Decoration');
    decoFolder.addDropDown(guiSettings,'texture', ['Blended', 'Grayscale', 'Wireframe']).onFinishChange((){regenerate(blend);});
    decoFolder.addDropDown(guiSettings,'scattering', ['Altitude', 'Linear', 'Cosine', 'CosineLayers', 'DiamondSquare', 'Particles', 'Perlin', 'PerlinAltitude', 'Simplex', 'Value', 'Weierstrass', 'Worley']).onFinishChange(scatterMeshes);
    decoFolder.addSlider(guiSettings,'spread', 0, 100)..step(1)..onFinishChange(scatterMeshes);
    decoFolder.addColor(guiSettings,'lightColor').onChange((val) {
      skyLight.color?.setFromHex32(val);
    });
    var sizeFolder = gui.addFolder('Size');
    sizeFolder.addSlider(guiSettings,'size', 1024, 3072)..step(256)..onFinishChange((){regenerate(blend);});
    sizeFolder.addSlider(guiSettings,'maxHeight', 2, 300)..step(2)..onFinishChange((){regenerate(blend);});
    sizeFolder.addSlider(guiSettings,'ratio', 0.2, 2)..step(0.05)..onFinishChange((){regenerate(blend);});

    var edgesFolder = gui.addFolder('Edges');
    edgesFolder.addDropDown(guiSettings,'edgeType', ['Box', 'Radial']).onFinishChange((){regenerate(blend);});
    edgesFolder.addDropDown(guiSettings,'edgeDirection', ['Normal', 'Up', 'Down']).onFinishChange((){regenerate(blend);});
    edgesFolder.addDropDown(guiSettings,'edgeCurve', ['Linear', 'EaseIn', 'EaseOut', 'EaseInOut']).onFinishChange((){regenerate(blend);});
    edgesFolder.addSlider(guiSettings,'edgeDistance', 0, 512)..step(32)..onFinishChange((){regenerate(blend);});

    gui.addFolder('Other')
    ..addFunction('Scatter meshes').onFinishChange((){scatterMeshes();})
    ..addFunction('Regenerate').onFinishChange((){regenerate(blend);});
  }
  Future<void> setupWorld() async{
    three.TextureLoader().fromAsset('assets/sky1.jpg').then((t1) {
      t1?.minFilter = three.LinearFilter; // Texture is not a power-of-two size; use smoother interpolation.
      skyDome = three.Mesh(
        three.SphereGeometry(8192, 16, 16, 0, math.pi*2, 0, math.pi*0.5),
        three.MeshBasicMaterial.fromMap({'map': t1, 'side': three.BackSide, 'fog': false})
      );
      skyDome.position.y = -99;
      threeJs.scene.add(skyDome);
    });

    water = three.Mesh(
      three.PlaneGeometry(16384+1024, 16384+1024, 16, 16),
      three.MeshLambertMaterial.fromMap({'color': 0x006ba0, 'transparent': true, 'opacity': 0.6})
    );
    water.position.y = -99;
    water.rotation.x = -0.5 * math.pi;
    threeJs.scene.add(water);

    skyLight = three.DirectionalLight(0xe8bdb0, 1.5);
    skyLight.position.setValues(2950, 2625, -160); // Sun on the sky texture
    threeJs.scene.add(skyLight);

    light = three.DirectionalLight(0xc3eaff, 0.75);
    light.position.setValues(-1, -0.5, -1);
    threeJs.scene.add(light);
  }

  three.Object3D buildTree() {
    final green = three.MeshLambertMaterial.fromMap({ 'color': 0x2d4c1e });

    final c0 = three.Mesh(
      CylinderGeometry(2, 2, 12, 6, 1, true),
      three.MeshLambertMaterial.fromMap({ 'color': 0x3d2817 }) // brown
    );
    c0.position.setY(6);

    final c1 = three.Mesh(CylinderGeometry(0, 10, 14, 8), green);
    c1.position.setY(18);
    final c2 = three.Mesh(CylinderGeometry(0, 9, 13, 8), green);
    c2.position.setY(25);
    final c3 = three.Mesh(CylinderGeometry(0, 8, 12, 8), green);
    c3.position.setY(32);

    final s = three.Object3D();
    s.add(c0);
    s.add(c1);
    s.add(c2);
    s.add(c3);
    s.scale.setValues(5, 1.25, 5);

    return s;
  }

  void applySmoothing(smoothing, terrain.TerrainOptions o) {
    three.Object3D m = terrainScene!.children[0];
    Float32List g = terrain.Terrain.toArray1D(m.geometry!.attributes['position'].array.toDartList());
    if (smoothing == 'Conservative (0.5)') terrain.Terrain.smoothConservative(g, o, 0.5);
    if (smoothing == 'Conservative (1)') terrain.Terrain.smoothConservative(g, o, 1);
    if (smoothing == 'Conservative (10)'){ terrain.Terrain.smoothConservative(g, o, 10);}
    else if (smoothing == 'Gaussian (0.5, 7)'){ terrain.Gaussian(g, o, 0.5, 7);}
    else if (smoothing == 'Gaussian (1.0, 7)'){ terrain.Gaussian(g, o, 1, 7);}
    else if (smoothing == 'Gaussian (1.5, 7)'){ terrain.Gaussian(g, o, 1.5, 7);}
    else if (smoothing == 'Gaussian (1.0, 5)'){ terrain.Gaussian(g, o, 1, 5);}
    else if (smoothing == 'Gaussian (1.0, 11)'){ terrain.Gaussian(g, o, 1, 11);}
    else if (smoothing == 'GaussianBox'){ terrain.GaussianBoxBlur(g, o, 1, 3);}
    else if (smoothing == 'Mean (0)'){ terrain.Terrain.smooth(g, o, 0);}
    else if (smoothing == 'Mean (1)'){ terrain.Terrain.smooth(g, o, 1);}
    else if (smoothing == 'Mean (8)'){ terrain.Terrain.smooth(g, o, 8);}
    else if (smoothing == 'Median'){ terrain.Terrain.smoothMedian(g, o);}
    terrain.Terrain.fromArray1D(m.geometry!.attributes['position'].array.toDartList(), g);
    terrain.Terrain.normalize(m, o);
  }

  void customInfluences(Float32List g, terrain.TerrainOptions options) {
    final clonedOptions = terrain.TerrainOptions();
    for (final opt in options.keys) {
      if (options.containsKey(opt)) {
        clonedOptions[opt] = options[opt];
      }
    }
    clonedOptions.maxHeight = options.maxHeight! * 0.67;
    clonedOptions.minHeight = options.minHeight! * 0.67;
    terrain. Generators.diamondSquare(g, clonedOptions);

    var radius = math.min(options.xSize, options.ySize) * 0.21,
        height = options.maxHeight! * 0.8;
    terrain.Terrain.influence(
      g, options,
      terrain.Terrain.influences[terrain.InfluenceType.hill],
      0.25, 0.25,
      radius, height,
      three.AdditiveBlending,
      terrain.Easing.linear
    );
    terrain.Terrain.influence(
      g, options,
      terrain.Terrain.influences[terrain.InfluenceType.mesa],
      0.75, 0.75,
      radius, height,
      three.SubtractiveBlending,
      terrain.Easing.easeInStrong
    );
    terrain.Terrain.influence(
      g, options,
      terrain.Terrain.influences[terrain.InfluenceType.flat],
      0.75, 0.25,
      radius, options.maxHeight,
      three.NormalBlending,
      terrain.Easing.easeIn
    );
    terrain.Terrain.influence(
      g, options,
      terrain.Terrain.influences[terrain.InfluenceType.volcano],
      0.25, 0.75,
      radius, options.maxHeight,
      three.NormalBlending,
      terrain.Easing.easeInStrong
    );
  }

  terrain.TerrainOptions lastOptions = terrain.TerrainOptions();
  three.Object3D? decoScene;
  void after(Float32List vertices, terrain.TerrainOptions options) {
    if (guiSettings['edgeDirection'] != 'Normal') {
      (guiSettings['edgeType'] == 'Box' ? terrain.Terrain.edges : terrain.Terrain.radialEdges)(
        vertices,
        options,
        guiSettings['edgeDirection'] == 'Up' ? true : false,
        guiSettings['edgeType'] == 'Box' ? guiSettings['edgeDistance'] : math.min(options.xSize, options.ySize) * 0.5 - guiSettings['edgeDistance'],
        terrain.Easing.fromString(guiSettings['edgeCurve'])
      );
    }
  }

  Map<String,dynamic> guiSettings = {
    'lightColor': 0xe8bdb0,
    'easing': 'Linear',
    'heightmap': 'Perlin',
    'smoothing': 'None',
    'maxHeight': 200.0,
    'segments': 63.0,
    'steps': 1.0,
    'turbulent': false,
    'size': 1024.0,
    'sky': true,
    'texture': 'Blended',
    'edgeDirection': 'Normal',
    'edgeType': 'Box',
    'edgeDistance': 256.0,
    'edgeCurve': 'EaseInOut',
    'ratio': 1.0,
    'flightMode':false,//useFPS;
    'spread': 60.0,
    'scattering':'Linear',//'PerlinAltitude';
  };

  Future<void> getHeightMapFromImage() async{
    final ByteData fileData = await rootBundle.load('assets/heightmap.png');
    final bytes = fileData.buffer.asUint8List();
    img.Image? image = img.decodeImage(bytes);
    heightmap = image!.getBytes();
  }

  Future<void> settings() async{
    guiSettings['lightColor'] = skyLight.color!.getHex();
    // var elevationGraph = document.getElementById('elevation-graph'),
    //     slopeGraph = document.getElementById('slope-graph'),
    //     analyticsValues = document.getElementsByClassName('value');

    three.TextureLoader loader = three.TextureLoader();
    final t1 = await loader.fromAsset('assets/sand1.jpg');
    t1?.wrapS = t1.wrapT = three.RepeatWrapping;
    sand = three.Mesh(
      three.PlaneGeometry(16384+1024, 16384+1024, 64, 64),
      three.MeshLambertMaterial.fromMap({'map': t1})
    );
    sand.position.y = -101;
    sand.rotation.x = -0.5 * math.pi;
    threeJs.scene.add(sand);

    final t2 = await loader.fromAsset('assets/grass1.jpg');
    final t3 = await loader.fromAsset('assets/stone1.jpg');
    final t4 = await loader.fromAsset('assets/snow1.jpg');

    blend = terrain.Terrain.generateBlendedMaterial([
      terrain.TerrainTextures(texture: t1!),
      terrain.TerrainTextures(texture: t2!, levels: [-80, -35, 20, 50]),
      terrain.TerrainTextures(texture: t3!, levels: [20, 50, 60, 85]),
      terrain.TerrainTextures(texture: t4!, glsl: '1.0 - smoothstep(65.0 + smoothstep(-256.0, 256.0, vPosition.x) * 10.0, 80.0, vPosition.z)'),
      terrain.TerrainTextures(texture: t3, glsl: 'slope > 0.7853981633974483 ? 0.2 : 1.0 - smoothstep(0.47123889803846897, 0.7853981633974483, slope) + 0.2'), // between 27 and 45 degrees
    ]);

    regenerate(blend);
    scatterMeshes();
  }

  void scatterMeshes() {
    var mesh = buildTree();
      var s = guiSettings['segments'].toInt(),
          sprd,
          randomness;
      var o = terrain.TerrainOptions(
        xSegments: s,
        ySegments: (s * guiSettings['ratio']).round(),
      );
      if (guiSettings['scattering'] == 'Linear') {
        sprd = guiSettings['spread'] * 0.0005;
        randomness = (k){return math.Random().nextDouble();};
      }
      else if (guiSettings['scattering'] == 'Altitude') {
        sprd = altitudeSpread;
      }
      else if (guiSettings['scattering'] == 'PerlinAltitude') {
        sprd = ((){
          var h = terrain.Terrain.scatterHelper(terrain.Generators.perlin, o, 2, 0.125)(),
              hs = terrain.Easing.inEaseOut(guiSettings['spread'] * 0.01);
          return (three.Vector3 v, double k, three.Vector3 v2, int i) {
            var rv = h[k.toInt()],
                place = false;
            if (rv < hs) {
              place = true;
            }
            else if (rv < hs + 0.2) {
              place = terrain.Easing.easeInOut((rv - hs) * 5) * hs < math.Random().nextDouble();
            }
            return math.Random().nextDouble() < altitudeProbability(v.z) * 5 && place;
          };
        })();
      }
      else {
        sprd = terrain.Easing.inEaseOut(guiSettings['spread']*0.01) * (guiSettings['scattering'] == 'Worley' ? 1 : 0.5);
        final l = terrain.Terrain.scatterHelper(terrain.Terrain.fromString(guiSettings['scattering'])!, o, 2, 0.125);
        randomness = (k){return l()[k.toInt()];};
      }
      var geo = terrainScene!.children[0].geometry!;
      if(decoScene != null){
        terrainScene!.remove(decoScene!);
      }
      decoScene = terrain.Terrain.scatterMeshes(geo, terrain.ScatterOptions(
        mesh: mesh,
        w: s.toDouble(),
        h: (s * guiSettings['ratio']).roundToDouble(),
        spread: sprd is double ?sprd:0.025,
        spreadFunction: sprd is double ?null:sprd,
        smoothSpread: guiSettings['scattering'] == 'Linear' ? 0 : 0.2,
        randomness: randomness,
        maxSlope: 0.6283185307179586, // 36deg or 36 / 180 * Math.PI, about the angle of repose of earth
        maxTilt: 0.15707963267948966, //  9deg or  9 / 180 * Math.PI. Trees grow up regardless of slope but we can allow a small variation
      ));
      if (decoScene != null) {
        terrainScene!.add(decoScene);
      }
    }

  void regenerate(three.Material? blend){
    var mat = three.MeshBasicMaterial.fromMap({'color': 0x5566aa, 'wireframe': true});
    var gray = three.MeshPhongMaterial.fromMap({ 'color': 0x88aaaa, 'specular': 0x444455, 'shininess': 10 });

    var s = guiSettings['segments'].toInt(),//int.parse(segments, 10),
        h = guiSettings['heightmap'] == 'heightmap.png';
    var o = terrain.TerrainOptions(
      after: after,
      easing: terrain.Easing.fromString(guiSettings['easing'])!,
      heightmap: h? heightmap:guiSettings['heightmap'] == 'influences' ? customInfluences :terrain.Terrain.fromString(guiSettings['heightmap']),//heightMapImage,//h ? heightmapImage : (heightmap == 'influences' ? customInfluences : THREE.Terrain[heightmap]),
      material: guiSettings['texture'] == 'Wireframe' ? mat : (guiSettings['texture'] == 'Blended' ? blend : gray),
      maxHeight: guiSettings['maxHeight'] - 100,
      minHeight: -100,
      steps: guiSettings['steps'].toInt(),
      stretch: true,
      turbulent: guiSettings['turbulent'],
      xSize: guiSettings['size'].toDouble(),
      ySize: (guiSettings['size'] * guiSettings['ratio']).roundToDouble(),
      xSegments: s,
      ySegments: (s * guiSettings['ratio']).round(),
    );
    if(terrainScene != null){
      threeJs.scene.remove(terrainScene!);
    }
    terrainScene = terrain.Terrain.create(o);
    applySmoothing(guiSettings['smoothing'], o);
    threeJs.scene.add(terrainScene);
    skyDome.visible = sand.visible = water.visible = guiSettings['texture'] != 'Wireframe';
    // var he = document.getElementById('heightmap');
    // if (he != null) {
    //   o.heightmap = he;
      heightMapImage = terrain.Terrain.toHeightmap(terrainScene!.children[0].geometry!.attributes['position'].array.toDartList(), o);
    // }
    heightMapImage = rgba2bitmap(heightMapImage!, o.xSegments+1, o.ySegments+1);
    lastOptions = o;
    
    scatterMeshes();
  }
  double altitudeProbability(double z) {
    if (z > -80 && z < -50){ return terrain.Easing.easeInOut((z + 80) / (-50 + 80)) * guiSettings['spread'] * 0.002;}
    else if (z > -50 && z < 20) {return guiSettings['spread'] * 0.002;}
    else if (z > 20 && z < 50) {return terrain.Easing.easeInOut((z - 20) / (50 - 20)) * guiSettings['spread'] * 0.002;}
    return 0;
  }
  bool altitudeSpread(three.Vector3 v,double k,three.Vector3 v2,int i){//double v, double k) {
    return k % 4 == 0 && math.Random().nextDouble() < altitudeProbability(v.z);
  }
}
