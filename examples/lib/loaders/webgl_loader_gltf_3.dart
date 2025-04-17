import 'dart:async';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';


class WebglLoaderGltf3 extends StatefulWidget {
  const WebglLoaderGltf3({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderGltf3> {
  static final _textKey = GlobalKey<FormState>();

  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
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
        clearAlpha: 0,
        clearColor: 0xffffff,
        useOpenGL: useOpenGL
      ),
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    controls.dispose();
    threeJs.dispose();
    three.loading.clear();

    focusNode.dispose();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            width: MediaQuery.of(context).size.width,
            height: 240,
            alignment: Alignment.center,
            child: TextField(
              key: _textKey,
              keyboardType: TextInputType.multiline,
              autofocus: false,
              focusNode: focusNode,
              //textAlignVertical: TextAlignVertical.center,
              onTap: (){
                FocusScope.of(context).requestFocus(focusNode);
              },
              onChanged: (t){
                print(t);
              },
              onEditingComplete:(){
                print('did Complete');
              },
              controller: controller,
              style: Theme.of(context).primaryTextTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                //labelText: label,
                filled: true,
                fillColor: Theme.of(context).splashColor,
                contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                  borderSide: BorderSide(
                      width: 0, 
                      style: BorderStyle.none,
                  ),
                ),
                hintStyle: Theme.of(context).primaryTextTheme.bodyMedium!.copyWith(color: Colors.grey),
                hintText: 'Type Text Here'
              ),
            )
          )
        ],
      ) 
    );
  }

  late three.OrbitControls controls;
  late three.AnimationMixer mixer;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues( 0,1,10);
    threeJs.camera.lookAt(threeJs.scene.position);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final pointLight = three.PointLight(0xffffff, 0.8);
    pointLight.position.setValues(0, 0, 10);
    threeJs.scene.add(pointLight);

    three.RGBELoader rgbeLoader = three.RGBELoader(flipY: true);
    rgbeLoader.setPath('assets/textures/equirectangular/');
    final hdrTexture = await rgbeLoader.fromAsset('royal_esplanade_1k.hdr');
    hdrTexture?.mapping = three.EquirectangularReflectionMapping;
    
    threeJs.scene.background = hdrTexture;
    threeJs.scene.environment = hdrTexture;

    threeJs.scene.add( three.AmbientLight( 0xffffff ) );

    three.GLTFLoader loader = three.GLTFLoader().setPath('assets/models/gltf/');
    final result = await loader.fromAsset('Xbot.gltf');

    final object = result!.scene;
    object.scale.setValues(2, 2, 2);

    final skeleton = SkeletonHelper(object);
    skeleton.visible = true;
    threeJs.scene.add(skeleton);

    mixer = three.AnimationMixer(object);

    final clip = result.animations?[1];
    if (clip != null) {
      final action = mixer.clipAction(clip);
      action?.play();
    }

    threeJs.scene.add(object);
  
    threeJs.addAnimationEvent((dt){
      controls.update();
      mixer.update(dt);
    });
  }
}
