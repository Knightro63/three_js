import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglHexTiling extends StatefulWidget {
  const WebglHexTiling({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglHexTiling> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap:true,
        shadowMapType: three.PCFSoftShadowMap,
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 1.25,
        colorSpace: three.ColorSpace.linear
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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
              child: panel.render()
            )
          )
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    final List<String> materialsList = ['ore','blackStone','grayStone','cartoonLava'];
    final Map<String,dynamic> materials ={
      'ore': {
        'textureURL': "https://i.ameo.link/bd3.jpg",
        'textureNormalURL': "https://i.ameo.link/bd6.jpg",
        'nonTilingTextureScale': 16.0,
        'tilingTextureScale': 40.0,
      },
      'blackStone': {
        'textureURL': "https://i.ameo.link/bdd.jpg",
        'textureNormalURL': "https://i.ameo.link/bdf.jpg",
        'textureRoughnessURL': "https://i.ameo.link/bdg.jpg",
        'nonTilingTextureScale': 12.0,
        'tilingTextureScale': 22.0,
      },
      'grayStone': {
        'textureURL': "https://i.ameo.link/bfj.jpg",
        'textureNormalURL': "https://i.ameo.link/bfk.jpg",
        'textureRoughnessURL': "https://i.ameo.link/bfl.jpg",
        'nonTilingTextureScale': 22.0,
        'tilingTextureScale': 42.0,
      },
      'cartoonLava': {
        'textureURL': "https://i.ameo.link/bl9.jpg",
        'textureNormalURL': "https://i.ameo.link/bla.jpg",
        'textureRoughnessURL': "https://i.ameo.link/blb.jpg",
        'nonTilingTextureScale': 12 * 2.0,
        'tilingTextureScale': 24 * 2.0,
      },
    };

    final Map<String, Map<String,dynamic>> texturesCache = new Map();

    Future<Map<String,dynamic>> loadTextures(String key) async{
      final cached = texturesCache[key];
      if (cached != null) {
        return cached;
      }

      final textureLoader = three.TextureLoader();

      Future<Map<String,dynamic>> defPromise() async{
        final tilingTextureScale = materials[key]['tilingTextureScale']*1.0;
        final nonTilingTextureScale = materials[key]['nonTilingTextureScale']*1.0;
        final textureNormalURL = materials[key]['textureNormalURL'];
        final textureURL = materials[key]['textureURL'];
        final textureRoughnessURL = materials[key]['textureRoughnessURL'];

        final texture = await textureLoader.fromNetwork(Uri.parse(textureURL));
        final textureNormal = await textureLoader.fromNetwork(Uri.parse(textureNormalURL));
        final textureRoughness = textureRoughnessURL == null?null:await textureLoader.fromNetwork(Uri.parse(textureRoughnessURL));

        texture?.wrapS = three.RepeatWrapping;
        texture?.wrapT = three.RepeatWrapping;
        texture?.repeat.setValues(tilingTextureScale, tilingTextureScale);
        texture?.magFilter = three.NearestFilter;
        texture?.anisotropy = 16;
        // I find that this helps to make things look a bit sharper when using
        // the hex tile-breaking shader, but it's not necessary
        texture?.minFilter = three.NearestMipMapLinearFilter;

        textureNormal?.wrapS = three.RepeatWrapping;
        textureNormal?.wrapT = three.RepeatWrapping;
        textureNormal?.repeat.setValues(tilingTextureScale, tilingTextureScale);

        textureRoughness?.wrapS = three.RepeatWrapping;
        textureRoughness?.wrapT = three.RepeatWrapping;
        textureRoughness?.repeat.setValues(tilingTextureScale, tilingTextureScale);
        textureRoughness?.magFilter = three.NearestFilter;

        final Map<String,dynamic> enabledTextures = {
          'texture': texture,
          'textureNormal': textureNormal,
          'textureRoughness': textureRoughness,
        };
        final Map<String,dynamic> disabledTextures = {
          'texture': texture?.clone(),
          'textureNormal': textureNormal?.clone(),
          'textureRoughness': textureRoughness?.clone(),
        };

        disabledTextures['texture'].repeat.setValues(
          nonTilingTextureScale,
          nonTilingTextureScale
        );

        disabledTextures['textureNormal'].repeat.setValues(
          nonTilingTextureScale,
          nonTilingTextureScale
        );

        disabledTextures['textureRoughness']?.repeat?.setValues(
          nonTilingTextureScale,
          nonTilingTextureScale
        );

        return { 'enabled': enabledTextures, 'disabled': disabledTextures };
      };

      texturesCache[key] = await defPromise();
      return texturesCache[key]!;
    };

    
    final gltfLoader = three.GLTFLoader();
    final gltf = await gltfLoader.fromAsset("assets/models/gltf/terrain.glb");

    final Map<String,dynamic> uiParams = {
      'enabled': true,
    };
    final Map<String,dynamic> textureParams = {
      'normalScale': 1.7,
      'texture': "grayStone",
    };

    final textures = await loadTextures(textureParams['texture']);

    threeJs.scene = three.Scene();
    threeJs.camera = three.PerspectiveCamera(
      75,
      threeJs.width / threeJs.height,
      0.1,
      1000
    );
    threeJs.camera.position.setValues(20, 20, 20);

    final three.HexTilingParams hexTilingParams = three.HexTilingParams(
      patchScale: 2,
      useContrastCorrectedBlending: true,
      lookupSkipThreshold: 0.01,
      textureSampleCoefficientExponent: 8,
    );

    final noHexTilingMat = three.MeshPhysicalMaterial.fromMap({
      'name': "no-hex-tiling",
      'color': 0xff0000,//0xf0e3f6,
      'normalScale': three.Vector2(
        textureParams['normalScale'],
        textureParams['normalScale']
      ),
      'map': textures['disabled']['texture'],
      'normalMap': textures['disabled']['textureNormal'],
      'roughnessMap': textures['disabled']['textureRoughness'],
      'metalness': 0,
      'roughness': 1,
    });
    final hexTilingMat = three.HexTilingMaterial(
      hexTilingParams,
      {
        'name': "hex-tiling",
        'color': 0xf0e3f6,
        'normalScale': three.Vector2(
          textureParams['normalScale'],
          textureParams['normalScale']
        ),
        'map': textures['enabled']['texture'],
        'normalMap': textures['enabled']['textureNormal'],
        'roughnessMap': textures['enabled']['textureRoughness'],
        'metalness': 0,
        'roughness': 1,
      }
    );

    // load the terrain
    final terrain = gltf!.scene.getObjectByName("Landscape002");
    terrain!.material = hexTilingMat;
    threeJs.scene.add(terrain);

    final gui = panel.addFolder( 'GUI' )..open();
    gui.addCheckBox(uiParams, "enabled").onChange((value){
      if (value) {
        terrain.material = hexTilingMat;
      } else {
        terrain.material = noHexTilingMat;
      }
    });

    final hexFolder = panel.addFolder("Hex Tiling Params")..open();

    hexFolder.addSlider(hexTilingParams.json, "patchScale",0.02,6,0.01).onChange((value){(terrain.material as three.HexTilingMaterial).hexTiling?.patchScale = value;});
    hexFolder.addCheckBox(hexTilingParams.json, "useContrastCorrectedBlending")..name = 'useBlending'..onChange((value){(terrain.material as three.HexTilingMaterial).hexTiling?.useContrastCorrectedBlending = value;});
    hexFolder.addSlider(hexTilingParams.json, "lookupSkipThreshold", 0, 5,0.1)..name = 'skip'..onChange((value){(terrain.material as three.HexTilingMaterial).hexTiling?.lookupSkipThreshold = value;});
    hexFolder.addSlider(hexTilingParams.json, "textureSampleCoefficientExponent",0.5,32,0.1)..name = 'Exponent'..onChange((value){if(terrain.material is three.HexTilingMaterial)(terrain.material as three.HexTilingMaterial).hexTiling?.textureSampleCoefficientExponent = value;});

    final textureFolder = panel.addFolder("Texture Params")..open();
    textureFolder.addDropDown(textureParams, "texture", materialsList)
      .onChange((value) async{
        final textures = await loadTextures(value);

        hexTilingMat.map = textures['enabled']['texture'];
        hexTilingMat.normalMap = textures['enabled']['textureNormal'];
        hexTilingMat.roughnessMap = textures['enabled']['textureRoughness'] ?? null;

        noHexTilingMat.map = textures['disabled']['texture'];
        noHexTilingMat.normalMap = textures['disabled']['textureNormal'];
        noHexTilingMat.roughnessMap = textures['disabled']['textureRoughness'] ?? null;

        hexTilingMat.needsUpdate = true;
        noHexTilingMat.needsUpdate = true;
      });
    textureFolder.addSlider(textureParams, "normalScale",0,5,0.1).onChange((value){
        hexTilingMat.normalScale?.setValues(value, value);
        noHexTilingMat.normalScale?.setValues(value, value);
      });

    final light = three.DirectionalLight(0xf5efd5, 0.6);
    light.position.setValues(40, 24, 40);
    threeJs.scene.add(light);

    // Add a white sphere at the location of the light to indicate its position
    final lightSphere = three.Mesh(
      three.SphereGeometry(0.5, 32, 32),
      three.MeshBasicMaterial.fromMap({ 'color': 0xffffff })
    );
    lightSphere.castShadow = false;
    lightSphere.receiveShadow = false;
    lightSphere.position.setFrom(light.position);
    threeJs.scene.add(lightSphere);

    final ambientLight = three.AmbientLight(0x404040, 0.6); // soft white light
    threeJs.scene.add(ambientLight);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    controls.enableDamping = true;

    // configure shadows
    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
