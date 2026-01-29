import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';

class WebglPlanetGenerator extends StatefulWidget {
  const WebglPlanetGenerator({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglPlanetGenerator> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui gui;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    gui = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
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
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render(context)
            )
          )
        ],
      ) 
    );
  }

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    // https://opengameart.org/content/night-sky-skybox-generator
    threeJs.scene.background = three.CubeTextureLoader()
      .fromAssetList( [
        'assets/textures/planet_generator/xpos.png',
        'assets/textures/planet_generator/xneg.png',
        'assets/textures/planet_generator/ypos.png',
        'assets/textures/planet_generator/yneg.png',
        'assets/textures/planet_generator/zpos.png',
        'assets/textures/planet_generator/zneg.png'
      ]);
          
    threeJs.camera = three.PerspectiveCamera(75, threeJs.width / threeJs.height, 0.1, 1000);
    final controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    threeJs.camera.position.z = 50;

    final texLoader = three.TextureLoader();
    final cloudTex = await texLoader.fromAsset('assets/textures/planet_generator/cloud.png');

    PlanetGenerator planet = PlanetGenerator(
      atmosphere: Atmosphere(cloudTexture: cloudTex)
    );
    threeJs.scene.add(planet);

    threeJs.addAnimationEvent((dt) {
      planet.atmosphere?.material?.uniforms['time']['value'] += dt;
      planet.atmosphere?.rotation.y += 0.0002;
      controls.update();
    });

    createUI(planet);
  }

  void createUI(PlanetGenerator planet) {
    final planetParams = planet.planetParams.json;
    final atmosphereParams = planet.atmosphereParams?.json;
    Atmosphere? atmosphere = planet.atmosphere;

    final terrainFolder = gui.addFolder('Terrain')..open();
    terrainFolder.onChange((name,value){
      if(name == 'type'){
        planet.material?.uniforms[name]['value'] = int.parse(value);
      }
      else if(name == 'Terrain'){
        planet.material?.uniforms['octaves']['value'] = value;
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
      atmosphere?.update();
    });
    terrainFolder.addDropDown(planetParams, 'type', ['1', '2', '3'])..name = 'Type';
    terrainFolder.addSlider(planetParams, 'amplitude', 0.01, 1.5,0.01)..name ='Amplitude';
    terrainFolder.addSlider(planetParams, 'sharpness', 0, 5,0.1)..name = 'Sharpness';
    terrainFolder.addSlider(planetParams, 'offset', -2, 2,0.1)..name = 'Offset';
    terrainFolder.addSlider(planetParams, 'period', 0.1, 3,0.1)..name = 'Period';
    terrainFolder.addSlider(planetParams, 'persistence', 0, 1,0.1)..name = 'Persistence';
    terrainFolder.addSlider(planetParams, 'lacunarity', 1, 3,0.1)..name = 'Lacunarity';
    terrainFolder.addSlider(planetParams, 'octaves', 1, 10, 1)..name = 'Octaves';

    //final layersFolder = gui.addFolder('Layers').close();
    final layer1Folder = gui.addFolder('Layer 1');
    layer1Folder.addColor(planetParams, 'color1')..name = 'Color'..onChange((value){
      planet.material?.uniforms['color1']['value'] = three.Color.fromHex32(value);
    });

    final layer2Folder = gui.addFolder('Layer 2');
    layer2Folder.onChange((name,value){
      print(name);
      if(name == 'Layer 2'){
        planet.material?.uniforms['color2']['value'] = three.Color.fromHex32(value);
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
    });
    layer2Folder.addSlider(planetParams, 'transition2', 0, 3, 0.1)..name = 'Transition Point';
    layer2Folder.addSlider(planetParams, 'blend12', 0, 1, 0.1)..name = 'Blend Factor (1->2)';
    layer2Folder.addColor(planetParams, 'color2')..name = 'Red';

    final layer3Folder = gui.addFolder('Layer 3');
    layer3Folder.onChange((name,value){
      if(name == 'Layer 3'){
        planet.material?.uniforms['color3']['value'] = three.Color.fromHex32(value);
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
    });
    layer3Folder.addSlider(planetParams, 'transition3', 0, 3,0.1)..name = 'Transition Point';
    layer3Folder.addSlider(planetParams, 'blend23', 0, 1,0.1)..name = 'Blend Factor (2->3)';
    layer3Folder.addColor(planetParams, 'color3')..name = 'Color';

    final layer4Folder = gui.addFolder('Layer 4');
    layer4Folder.onChange((name,value){
      if(name == 'Layer 4'){
        planet.material?.uniforms['color4']['value'] = three.Color.fromHex32(value);
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
    });
    layer4Folder.addSlider(planetParams, 'transition4', 0, 3, 0.1)..name = 'Transition Point';
    layer4Folder.addSlider(planetParams, 'blend34', 0, 1, 0.1)..name = 'Blend Factor (3->4)';
    layer4Folder.addColor(planetParams, 'color4')..name = 'Color';

    final layer5Folder = gui.addFolder('Layer 5');
    layer5Folder.onChange((name,value){
      if(name == 'Layer 5'){
        planet.material?.uniforms['color5']['value'] = three.Color.fromHex32(value);
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
    });
    layer5Folder.addSlider(planetParams, 'transition5', 0, 3, 0.1)..name = 'Transition Point';
    layer5Folder.addSlider(planetParams, 'blend45', 0, 1, 0.1)..name = 'Blend Factor (4->5)';
    layer5Folder.addColor(planetParams, 'color5')..name = 'Color';
    
    if(planet.atmosphere != null){
      final atmosphereFolder = gui.addFolder('Atmosphere')..open()..onChange((name,value){
        if(name == 'Atmosphere'){
          planet.atmosphere?.material?.uniforms['speed']['value'] = value;
        }
        else{
          if(name == 'particles'||name == 'minParticleSize'||name == 'maxParticleSize'){
            planet.atmosphere?.material?.uniforms[name]['value'] = value.toInt();
          }
          else{
            planet.atmosphere?.material?.uniforms[name]['value'] = value;
          }
        }
        atmosphere?.update();
      });
      atmosphereFolder.addSlider(atmosphereParams!, 'thickness', 0.1, 5, 0.1)..name = 'Thickness';
      atmosphereFolder.addSlider(atmosphereParams, 'particles', 1, 50000, 1)..name = 'Particle Count';
      atmosphereFolder.addSlider(atmosphereParams, 'minParticleSize', 0, 200)..name = 'Min Particle Size';
      atmosphereFolder.addSlider(atmosphereParams, 'maxParticleSize', 0, 200)..name = 'Max Particle Size';
      atmosphereFolder.addSlider(atmosphereParams, 'density', -2, 2, 0.1)..name = 'Density';
      atmosphereFolder.addSlider(atmosphereParams, 'opacity', 0, 1, 0.1)..name = 'Opacity';
      atmosphereFolder.addSlider(atmosphereParams, 'scale', 1, 30)..name = 'Scale';
      atmosphereFolder.addSlider(atmosphereParams, 'speed', 0, 0.1, 0.001)..name = 'Speed';

      final atmosphereColorFolder = gui.addFolder('Color')..open();
      atmosphereColorFolder.addColor(atmosphereParams, 'color')..name = 'Color'..onChange((value){
        planet.atmosphere?.material?.uniforms['color']['value'] = three.Color.fromHex32(value);
        atmosphere?.update();
      });
    }

    final lightingFolder = gui.addFolder('Lighting')..open();
    lightingFolder.onChange((name,value){
      if(name == 'Lighting'){
        planet.material?.uniforms['shininess']['value'] = value;
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
    });  
    lightingFolder.addSlider(planetParams, 'ambientIntensity', 0, 5,0.1)..name = 'Ambient';
    lightingFolder.addSlider(planetParams, 'diffuseIntensity', 0, 5,0.1)..name = 'Diffuse';
    lightingFolder.addSlider(planetParams, 'specularIntensity', 0, 5,0.1)..name = 'Specular';
    lightingFolder.addSlider(planetParams, 'shininess', 0, 25,0.1)..name = 'Shininess';

    // final lightDirFolder = gui.addFolder('Direction')..onChange((name,value){
    //   planet.material?.uniforms['lightDirection']['value'][name] = value;
    // });
    // lightDirFolder.addSlider(planetParams['lightDirection']['value'], 'lightDirection', -1, 1,0.1)..name = 'X';
    // lightDirFolder.addSlider(planetParams['lightDirection']['value'], 'y', -1, 1,0.1)..name = 'Y';
    // lightDirFolder.addSlider(planetParams['lightDirection']['value'], 'z', -1, 1,0.1)..name = 'Z';

    final lightColorFolder = gui.addFolder('Color');
    lightColorFolder.addColor(planetParams, 'lightColor')..name = 'Color'..onChange((value){
      planet.material?.uniforms['lightColor']['value'] = three.Color.fromHex32(value);
    });

    final bumpMapFolder = gui.addFolder('Bump Mapping')..open();
    bumpMapFolder.onChange((name,value){
      if(name == 'Bump Mapping'){
        planet.material?.uniforms['bumpOffset']['value'] = value;
      }
      else{
        planet.material?.uniforms[name]['value'] = value;
      }
    });
    bumpMapFolder.addSlider(planetParams, 'bumpStrength', 0, 2,0.1)..name = 'Bump Strength';
    bumpMapFolder.addSlider(planetParams, 'bumpOffset', 0.0, 0.1,0.0001)..name = 'Bump Offset';
  }
}
