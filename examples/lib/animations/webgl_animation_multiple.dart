import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationMultiple extends StatefulWidget {
  
  const WebglAnimationMultiple({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationMultiple> {
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
      settings: three.Settings(
        useSourceTexture: true,
      ),
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    controls.dispose();
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

  late three.OrbitControls controls;

  late List<Map<String, dynamic>> models;
  late List<Map<String, dynamic>> units;
  final List<three.AnimationMixer> mixers = []; // All the three.AnimationMixer objects for all the animations in the scene
  int numLoadedModels = 0;

  Future<void> setup() async {
    models = [
      {"name": "Soldier"},
      {"name": "Parrot"},
    ];

    // Here we define instances of the models that we want to place in the scene, their position, scale and the animations
    // that must be played.
    units = [
      {
        "modelName": "Soldier", // Will use the 3D model from file models/gltf/Soldier.glb
        "meshName": "vanguard_Mesh", // Name of the main mesh to animate
        "position": {
          "x": 0,
          "y": 0,
          "z": 0
        }, // Where to put the unit in the scene
        "scale": 1, // Scaling of the unit. 1.0 means: use original size, 0.1 means "10 times smaller", etc.
        "animationName": "Idle" // Name of animation to run
      },
      {
        "modelName": "Soldier",
        "meshName": "vanguard_Mesh",
        "position": {"x": 3, "y": 0, "z": 0},
        "scale": 2,
        "animationName": "Walk"
      },
      {
        "modelName": "Soldier",
        "meshName": "vanguard_Mesh",
        "position": {"x": 1, "y": 0, "z": 0},
        "scale": 1,
        "animationName": "Run"
      },
      {
        "modelName": "Parrot",
        "meshName": "mesh_0",
        "position": {"x": -4, "y": 0, "z": 0},
        "rotation": {"x": 0, "y": math.pi, "z": 0},
        "scale": 0.01,
        "animationName": "parrot_A_"
      },
      {
        "modelName": "Parrot",
        "meshName": "mesh_0",
        "position": {"x": -2, "y": 0, "z": 0},
        "rotation": {"x": 0, "y": math.pi / 2, "z": 0},
        "scale": 0.02,
        "animationName": null
      },
    ];

    setup2();
    loadModels();
  }

  void setup2() {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 10000);
    threeJs.camera.position.setValues(3, 6, -10);
    threeJs.camera.lookAt(three.Vector3(0, 1, 0));

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xa0a0a0);
    threeJs.scene.fog = three.Fog(0xa0a0a0, 10, 22);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.setValues(0, 20, 0);
    threeJs.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(-3, 10, -10);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 10;
    dirLight.shadow!.camera!.bottom = -10;
    dirLight.shadow!.camera!.left = -10;
    dirLight.shadow!.camera!.right = 10;
    dirLight.shadow!.camera!.near = 0.1;
    dirLight.shadow!.camera!.far = 40;
    threeJs.scene.add(dirLight);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    // ground
    final groundMesh = three.Mesh(three.PlaneGeometry(40, 40), three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": false}));

    groundMesh.rotation.x = -math.pi / 2;
    groundMesh.receiveShadow = true;
    threeJs.scene.add(groundMesh);
  }

  void loadModels() {
    for (int i = 0; i < models.length; ++i) {
      final m = models[i];

      loadGltfModel(m, () {
        ++numLoadedModels;

        if (numLoadedModels == models.length) {
          three.console.info("All models loaded, time to instantiate units...");
          instantiateUnits();
        }
      });
    }
  }

  void instantiateUnits() {
    int numSuccess = 0;

    for (int i = 0; i < units.length; ++i) {
      final u = units[i];
      final model = getModelByName(u["modelName"]);

      if (model != null) {
        final clonedScene = SkeletonUtils.clone(model["scene"]);

        if (clonedScene != null) {
          // three.Scene is cloned properly, let's find one mesh and launch animation for it
          final clonedMesh = clonedScene.getObjectByName(u["meshName"]);

          if (clonedMesh != null) {
            final mixer = startAnimation(
                clonedMesh,
                List<three.AnimationClip>.from(model["animations"]),
                u["animationName"]);

            // Save the animation mixer in the list, will need it in the animation loop
            mixers.add(mixer);
            numSuccess++;
          }
          threeJs.scene.add(clonedScene);

          if (u["position"] != null) {
            clonedScene.position.setValues(
                u["position"]["x"].toDouble(), u["position"]["y"].toDouble(), u["position"]["z"].toDouble());
          }

          if (u["scale"] != null) {
            clonedScene.scale.setValues(u["scale"].toDouble(), u["scale"].toDouble(), u["scale"].toDouble());
          }

          if (u["rotation"] != null) {
            clonedScene.rotation.x = u["rotation"]["x"].toDouble();
            clonedScene.rotation.y = u["rotation"]["y"].toDouble();
            clonedScene.rotation.z = u["rotation"]["z"].toDouble();
          }
        }
      } else {
        three.console.info("Can not find model ${u["modelName"]}");
      }
    }

    three.console.info(" Successfully instantiated $numSuccess units ");

    threeJs.addAnimationEvent((dt){
      for (int i = 0; i < mixers.length; ++i) {
        mixers[i].update(dt);
      }

      controls.update();
    });
  }

  three.AnimationMixer startAnimation(
    three.Object3D skinnedMesh, 
    List<three.AnimationClip> animations, 
    String animationName
  ) {
    final mixer = three.AnimationMixer(skinnedMesh);
    final clip = three.AnimationClip.findByName(animations, animationName);

    if (clip != null) {
      final action = mixer.clipAction(clip);
      action!.play();
    }

    return mixer;
  }

  Map<String, dynamic>? getModelByName(String name) {
    for (int i = 0; i < models.length; ++i) {
      if (models[i]["name"] == name) {
        return models[i];
      }
    }

    return null;
  }

  void loadGltfModel(model, onLoaded) {
    final loader = three.GLTFLoader();
    final modelName = "assets/models/gltf/${model["name"]}.gltf";

    loader.fromAsset(modelName).then((gltf) {
      final scene = gltf!.scene;

      model["animations"] = gltf.animations;
      model["scene"] = scene;

      gltf.scene.traverse((object) {
        object.frustumCulled = true;
        if (object is three.Mesh) {
          object.castShadow = true;
        }
      });

      three.console.info("Done loading model ${model["name"]} ");
      onLoaded();
    });
  }
}
