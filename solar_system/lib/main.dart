import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:css/css.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/torus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SolarSystem(),
    );
  }
}

class SolarObjects{
  String name;
  three.Mesh mesh;
  double yRotation;
  double speed;
  double distance;
  double radius;
  double actualAngle;
  late List<SolarObjects> satelites;

  SolarObjects({
    required this.name,
    required this.mesh,
    required this.yRotation,
    required this.speed,
    this.distance = 0,
    this.radius = 0,
    required this.actualAngle,
    List<SolarObjects>? satelites,
  }){
    this.satelites = satelites ?? [];
  }
}

class SolarSystem extends StatefulWidget {
  const SolarSystem({super.key});
  @override
  _SolarSystem createState() => _SolarSystem();
}

class _SolarSystem extends State<SolarSystem> {
  late three.ThreeJS threeJs;
  LsiThemes theme = LsiThemes.dark;
  late three.OrbitControls controls;

  @override
  void initState(){
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose(){
    controls.dispose();
    threeJs.dispose();
    super.dispose();
  }

  final List<SolarObjects> objects = [];
  final List rings = [];
  final List rocks = [];
  final List groups = [];
  three.Object3D? rocksGroup;
  three.Object3D? orbitGroup;

  int duration = 5000; // ms
  int currentTime = DateTime.now().millisecondsSinceEpoch;
  double orbitDistance = 0;
  double objsSize = 0.75;

  Future<void> setup() async{
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color(0.03, 0.03, 0.09);

    /****************************************************************************
     * Camera
     */
    // Add  a camera so we can view the scene
    //PerspectiveCamera( fov : Number, aspect : Number, near : Number, far : Number )
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.5, 4000);
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.camera.position.setValues(0, 25, 250);
    threeJs.camera.rotation.x = -0.35;

    controls.minDistance = 31;
    controls.maxDistance = 1300;
    controls.update();

    /****************************************************************************
     * Light
     */
    // Add a directional light to show off the objects
    final pointLight = three.PointLight( 0xffffff, 2 );
    threeJs.camera.add( pointLight );
    threeJs.scene.add(threeJs.camera);
    threeJs.camera.lookAt(threeJs.scene.position);
    threeJs.scene.add(three.AmbientLight(0xffffcc,2));


    // final light2 = three.PointLight(0xffffff, 1, 1000, 0.02);
    // //move light
    // light2.name = "SUNLIGHT";
    // // light2.position.set(lightPositionX, lightPositionY, lightPositionZ);
    // light2.castShadow = true; // default false
    // light2.visible = true;
    // light2.shadow?.bias = 0.0001;
    // light2.shadow?.mapSize.width = 4096; // default
    // light2.shadow?.mapSize.height = 4096; // default
    // //light2.shadow?.darkness = 0.1;
    // light2.shadow?.camera?.near = 1000000;
    // light2.shadow?.camera?.far = 3e9; // default
    // // light2.color.setHSL(0.5, 0.7, 0.8);

    // //shadow.camera.fov and rotation shows the shadow.
    // // light2.shadow.camera.fov = -270;
    // light2.rotation.set(0, math.pi, 0);

    // threeJs.scene.add(light2);

    final three.TextureLoader textureLoader = three.TextureLoader(flipY: true);

    /****************************************************************************
     * Textures and materials
     */
    // Sun
    final sunMaterial = three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/sunMap.jpg"),
    });

    // Mercury
    final mercuryMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/mercurymap.jpg"),
      'bumpMap': await textureLoader.fromAsset("assets/planets/mercurybump.jpg"),
      'bumpScale': 0.05
    });

    // Venus
    final venusMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/venusmap.jpg"),
      'bumpMap': await textureLoader.fromAsset("assets/planets/venusbump.jpg"),
      'bumpScale': 0.05
    });

    // Earth
    final earthMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/earthmap1k.jpg"),
      'bumpMap': await textureLoader.fromAsset("assets/planets/earthbump1k.jpg"),
      'bumpScale': 0.05
    });

    // Mars
    final marsMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/marsmap1k.jpg"),
      'bumpMap': await textureLoader.fromAsset("assets/planets/marsbump1k.jpg"),
      'bumpScale': 0.05
    });

    // Jupiter
    final jupiterMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/jupiter2_1k.jpg")
    });

    // Saturn
    final saturnMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/saturnmap.jpg")
    });

    // Uranus
    final uranusMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/uranusmap.jpg")
    });

    // Neptune
    final neptuneMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/neptunemap.jpg")
    });

    // Pluto
    final plutoMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/plutomap1k.jpg"),
      'bumpMap': await textureLoader.fromAsset("assets/planets/plutobump1k.jpg"),
      'bumpScale': 0.05
    });

    // Moon
    final moonMaterial = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/moonmap1k.jpg"),
      'bumpMap': await textureLoader.fromAsset("assets/planets/moonbump1k.jpg"),
      'bumpScale': 0.05
    });

    // Jupiter Moon 1
    final jupterMoon1Material = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/jupiterMoon.jpg")
    });

    // Jupiter Moon 2
    final jupterMoon2Material = three.MeshPhongMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/planets/jupiterMoon2.jpg")
    });

    // Phobos
    final phobosMaterial = three.MeshPhongMaterial.fromMap({
      'color': 0x707070,
      'bumpMap': await textureLoader.fromAsset("assets/planets/phobosbump.jpg"),
      'bumpScale': 0.1
    });

    // Deimos
    final deimosMaterial = three.MeshPhongMaterial.fromMap({
      'color': 0x707070,
      'bumpMap': await textureLoader.fromAsset("assets/planets/deimosbump.jpg"),
      'bumpScale': 0.1
    });

    final three.GroupMaterial bgMatArray = three.GroupMaterial();

    bgMatArray.add(three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/stars/corona_ft.png")
    }));
    bgMatArray.add(three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/stars/corona_bk.png")
    }));
    bgMatArray.add(three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/stars/corona_up.png")
    }));
    bgMatArray.add(three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/stars/corona_dn.png")
    }));
    bgMatArray.add(three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/stars/corona_rt.png")
    }));
    bgMatArray.add(three.MeshBasicMaterial.fromMap({
      'map': await textureLoader.fromAsset("assets/stars/corona_lf.png")
    }));

    for (int i = 0; i < 6; i++) {
      bgMatArray.children[i].side = three.BackSide;
    }

    final skyboxGeo = three.BoxGeometry(3500, 3500, 3500);
    final skybox = three.Mesh(skyboxGeo, bgMatArray);
    threeJs.scene.add(skybox);
    /****************************************************************************
     * Geometry
     */

    //Create the first group (Sun group)
    addGroup(three.Vector3(0,0,0));
    //Static group
    orbitGroup = three.Object3D();
    orbitGroup?.position.setValues(0, 0, 0);
    rocksGroup = three.Object3D();
    rocksGroup?.position.setValues(0, 0, 0);

    // Create the Sun
    addPlanet('Sun', sunMaterial, 30, 0.002, 0);

    //Add orbit
    addOrbit(40);
    // Create Mercury
    addPlanet('Mercury', mercuryMaterial, 0.5, 0.016, 1.57);

    //Add orbit
    addOrbit(7);
    // Create Venus
    addPlanet('Venus', venusMaterial, 1.65, 0.0044, 1.17);

    //Add orbit
    addOrbit(8.4);
    // Create Earth
    final earthMeshT = addPlanet('Earth', earthMaterial, 2, 1, 1);
    addSatelite('moon', moonMaterial, 0.3, 0, 1.5, 2.5, earthMeshT);
    //Add orbit
    addOrbit(6.65);
    // Create mars
    final marshMeshT = addPlanet('Mars', marsMaterial, 1, 0.96, 0.805);
    addSatelite('Phobos', phobosMaterial, 0.1, -0.04, 1, 1.4, marshMeshT);
    addSatelite('Deimos', deimosMaterial, 0.05, 0.036, 0.2, 2.6, marshMeshT);
    //Add orbit
    addOrbit(30);
    addAsteroidBelt(200);
    //Add orbit
    addOrbit(30);
    // Create Jupiter
    final jupiterhMeshT = addPlanet('Jupiter', jupiterMaterial, 15, 0.16, 0.43);
    addSatelite('Io', jupterMoon1Material, 0.3, 0.05, 2, 16, jupiterhMeshT);
    addSatelite('Europa', jupterMoon2Material, 0.15, 0.1, 1.5, 16.5, jupiterhMeshT);
    addSatelite('Ganymede', jupterMoon1Material, 0.75, 0.17, 1, 17.5, jupiterhMeshT);
    addSatelite('Callisto', jupterMoon2Material, 0.55, 0.25, 0.8, 19, jupiterhMeshT);
    //Add orbit
    addOrbit(56);
    // Create Saturn
    addPlanet('Saturn', saturnMaterial, 7, 1.26, 0.325);

    //Add orbit
    addOrbit(66);
    // Create Uraus
    addPlanet('Uraus', uranusMaterial, 4, 1.4, 0.228);

    //Add orbit
    addOrbit(107);
    // Create Neptune
    addPlanet('Neptune', neptuneMaterial, 4.5, 1.5, 0.182);

    //Add orbit
    addOrbit(100);
    // Create Pluto
    final plutoMeshT = addPlanet('Pluto', plutoMaterial, 2, 1.68, 0.058);
    addSatelite('PlutoMoon1', jupterMoon1Material, 0.3, 0.4,2,2.8,plutoMeshT);
    addSatelite('PlutoMoon1', jupterMoon1Material, 0.2, 0.3,1.54,3.5,plutoMeshT);


    // Add all planets to scene
    threeJs.scene.add(groups[0]);
    groups[0].add(orbitGroup);
    groups[0].add(rocksGroup);
    /****************************************************************************
     * Events
     */
    // add mouse handling so we can rotate the scene
    //addMouseHandler(canvas, groups[0]);

    threeJs.addAnimationEvent((dt){
      animate();
    });
  }

  void addGroup(three.Vector3 pos) {
    // Create a group to hold all the objects
    final newGroup = three.Object3D();
    newGroup.position.setValues(pos.x, pos.y, pos.z);
    groups.add(newGroup);
  }

  SolarObjects addPlanet(String name, three.Material material, double size, double yRotation, double speed) {
    if (groups.isEmpty) addGroup(three.Vector3());
    // Create new Geometry
    final geometry = three.SphereGeometry(size, 24, 24);
    final newMesh = three.Mesh(geometry, material);

    final randAngle = math.Random().nextDouble() * math.pi * 2;
    final xT = math.cos(randAngle) * orbitDistance;
    final zT = math.sin(randAngle) * orbitDistance;
    // Create new group
    addGroup(three.Vector3(xT,0,zT));
    //newMesh.position.set(xT, 0, zT);
    newMesh.position.setValues(0, 0, 0);
    final newObject = SolarObjects(
      name: name,
      mesh: newMesh,
      yRotation: yRotation,
      speed: speed,
      radius: orbitDistance,
      actualAngle: randAngle,
      satelites: []
    );
    objects.add(newObject);
    // Add to the group
    groups[0].add(groups[groups.length - 1]);
    groups[groups.length - 1].add(objects[objects.length - 1].mesh);
    return newObject;
  }

  void addOrbit(double distance) {
      orbitDistance += distance;
      var newObj = TorusGeometry(orbitDistance, 0.15, 14, 150);
      var newMaterial = three.MeshBasicMaterial.fromMap({
        'color': 0xc4c4c4,
        'side': three.DoubleSide
      });
      var newMesh = three.Mesh(newObj, newMaterial);
      newMesh.rotation.x = math.pi / 2;
      rings.add(newMesh);
      orbitGroup?.add(newMesh);
  }

  void addSatelite(String name, three.Material material, double size, double yRotation, double speed, double distance, SolarObjects planetObj) {
    if (groups.isNotEmpty && objects.isEmpty) return;

    //Creating Satelite
    final geometry = three.SphereGeometry(size, 18, 18);
    final newMesh = three.Mesh(geometry, material);

    final randAngle = math.Random().nextDouble() * math.pi * 2;
    final xT = math.cos(randAngle) * distance;
    final zT = math.sin(randAngle) * distance;
    newMesh.position.setValues(xT, 0, zT);

    final newObject = SolarObjects(
      name: name,
      mesh: newMesh,
      yRotation: yRotation,
      speed: speed,
      distance: distance,
      actualAngle: randAngle
    );

    planetObj.satelites.add(newObject);
    planetObj.mesh.parent?.add(newMesh);
  }

  void addAsteroidBelt(asteroidsNum) {
    // Creating Ateroid
    final newMat = three.MeshPhongMaterial.fromMap({
      'color': 0x7a7a7a
    });

    for (int i = 0; i < asteroidsNum; i++) {
      // Random values
      final randSize = (math.Random().nextDouble() * 0.75) +0.35;
      final randAngle = math.Random().nextDouble() * math.pi * 2;
      final plusOrMinus = math.Random().nextDouble() < 0.5 ? false : true;
      // Geometry
      final geometry = three.SphereGeometry(randSize, 4, 4);
      // Mesh
      final newMesh = three.Mesh(geometry, newMat);
      double xT = math.cos(randAngle) * orbitDistance;
      double zT = math.sin(randAngle) * orbitDistance;
      double yT = (math.Random().nextDouble() * 1.5);
      if (plusOrMinus){
        yT *= -1;
        xT = xT + (math.Random().nextDouble() * -2);
        yT = yT + (math.Random().nextDouble() * -2);
      } else{
        xT = xT + (math.Random().nextDouble() * 2);
        yT = yT + (math.Random().nextDouble() * 2);
      }
      newMesh.position.setValues(xT, yT, zT);
      rocks.add(newMesh);
      rocksGroup?.add(newMesh);
    }
  }

  void animate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deltat = now - currentTime;
    currentTime = now;
    final fract = deltat / duration;
    final deltaAngle = math.pi * 2 * fract;

    // Base rotation about its Y axis
    for (int i = 0; i < objects.length; i++) {
      objects[i].mesh.rotation.y += 1 * deltaAngle * objects[i].yRotation;

      for (int j = 0; j < objects[i].satelites.length; j++) {
        objects[i].satelites[j].mesh.rotation.y += 1 * deltaAngle * objects[i].satelites[j].yRotation;
      }
    }

    // Base revolution about its Y axis
    for (int i = 1; i < objects.length; i++) {
      objects[i].mesh.parent?.position.x = math.cos(math.pi * 2 * objects[i].actualAngle) * objects[i].radius;
      objects[i].mesh.parent?.position.z = math.sin(math.pi * 2 * objects[i].actualAngle) * objects[i].radius;
      objects[i].actualAngle = objects[i].actualAngle + (0.005 * deltaAngle * objects[i].speed);

      for (int j = 0; j < objects[i].satelites.length; j++) {
        objects[i].satelites[j].mesh.position.x = math.cos(math.pi * 2 * objects[i].satelites[j].actualAngle) * objects[i].satelites[j].distance;
        objects[i].satelites[j].mesh.position.z = math.sin(math.pi * 2 * objects[i].satelites[j].actualAngle) * objects[i].satelites[j].distance;
        objects[i].satelites[j].actualAngle = objects[i].satelites[j].actualAngle - (0.1 * deltaAngle * objects[i].satelites[j].speed);
      }
    }

    // Asteroids revolution
    rocksGroup?.rotation.y += deltaAngle * 0.02;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      theme: CSS.changeTheme(theme),
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child:Theme(
          data: CSS.changeTheme(theme),
          child: threeJs.build()
        )
      )
    );
  }
}