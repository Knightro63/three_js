import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationSkinningAdditiveBlending extends StatefulWidget {
  
  const WebglAnimationSkinningAdditiveBlending({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningAdditiveBlending> {
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
        outputEncoding: three.sRGBEncoding,
        useSourceTexture: true
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

  late three.AnimationMixer mixer;
  late three.OrbitControls controls;
  late three.Object3D model;

  final crossFadeControls = [];

  String currentBaseAction = 'idle';
  final allActions = [];
  final Map<String,dynamic> baseActions = {
    'idle': <String,dynamic>{ 'weight': 1.0  },
    'walk': <String,dynamic>{ 'weight': 0.0 },
    'run': <String,dynamic>{ 'weight': 0.0  }
  };
  final Map<String,dynamic> additiveActions = {
    'sneak_pose': <String,dynamic>{ 'weight': 0.0  },
    'sad_pose': <String,dynamic>{ 'weight': 0.0  },
    'agree': <String,dynamic>{ 'weight': 0.0  },
    'headShake': <String,dynamic>{ 'weight': 0.0  }
  };
  Map<String,dynamic> panelSettings = {};
  int numAnimations = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.setValues(-1, 3, 3);
    threeJs.camera.lookAt(three.Vector3(0, 1, 0));

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xa0a0a0);
    threeJs.scene.fog = three.Fog(0xa0a0a0, 10, 50);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444,2);
    hemiLight.position.setValues(0, 20, 0);
    threeJs.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(3, 10, 10);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 2;
    dirLight.shadow!.camera!.bottom = -2;
    dirLight.shadow!.camera!.left = -2;
    dirLight.shadow!.camera!.right = 2;
    dirLight.shadow!.camera!.near = 0.1;
    dirLight.shadow!.camera!.far = 40;
    threeJs.scene.add(dirLight);

    final mesh = three.Mesh(three.PlaneGeometry(100, 100),
        three.MeshPhongMaterial.fromMap({"color": 0x999999, "depthWrite": false}));
    mesh.rotation.x = -math.pi / 2;
    mesh.receiveShadow = true;
    threeJs.scene.add(mesh);

    final loader = three.GLTFLoader();
    final gltf = await loader.fromAsset('assets/models/gltf/Xbot.gltf');

    model = gltf!.scene;
    threeJs.scene.add(model);

    model.traverse((object) {
      if (object is three.Mesh) {
        object.castShadow = true;
      }
    });

    final skeleton = SkeletonHelper(model);
    skeleton.visible = true;
    threeJs.scene.add(skeleton);

    final animations = gltf.animations!;
    mixer = three.AnimationMixer(model);

    for (int i = 0; i != numAnimations; ++ i ) {
      three.AnimationClip clip = animations[ i ];
      final name = clip.name;

      if ( baseActions[ name ] ) {

        final action = mixer.clipAction( clip );
        activateAction( action! );
        baseActions[ name ].action = action;
        allActions.add( action );

      } else if ( additiveActions[ name ] ) {

        // Make the clip additive and remove the reference frame

        three.AnimationUtils().makeClipAdditive( clip );

        if ( clip.name.endsWith( '_pose' ) ) {
          clip = three.AnimationUtils().subclip( clip, clip.name, 2, 3);
        }

        final action = mixer.clipAction( clip );
        activateAction( action! );
        additiveActions[ name ].action = action;
        allActions.add( action );
      }
    }

    createPanel();

    threeJs.addAnimationEvent((dt){
      controls.update();
      for ( int i = 0; i != numAnimations; ++ i ) {
        final action = allActions[ i ];
        final clip = action.getClip();
        final settings = baseActions[ clip.name ] ?? additiveActions[ clip.name ];
        settings.weight = action.getEffectiveWeight();
      }
      mixer.update(dt);
    });
  }

  void createPanel() {
    final folder1 = panel.addFolder( 'Base Actions' );
    final folder2 = panel.addFolder( 'Additive Action Weights' );
    final folder3 = panel.addFolder( 'General Speed' );

    panelSettings = {
      'modify time scale': 1.0
    };

    final baseNames = ['None'];
    baseNames.addAll(baseActions.keys);

    for ( int i = 0, l = baseNames.length; i != l; ++ i ) {
      final name = baseNames[ i ];
      final settings = baseActions[ name ];
      panelSettings[ name ] = () {

        final currentSettings = baseActions[ currentBaseAction ];
        final currentAction = currentSettings != null? currentSettings['action'] : null;
        final action = settings != null? settings['action'] : null;

        if ( currentAction != action ) {
          prepareCrossFade( currentAction, action, 0.35 );
        }
      };

      crossFadeControls.add(folder1.addFunction(name)..onFinishChange(panelSettings[ name ]));
    }

    for (final name in additiveActions.keys ) {
      final settings = additiveActions[ name ];

      panelSettings[name] = settings!['weight'];
      folder2.addSlider( panelSettings, name, 0.0, 1.0 )..step(0.01 )..onChange(( weight ) {
        setWeight( settings['action'], weight );
        settings['weight'] = weight;
      } );

    }

    folder3.addSlider( panelSettings, 'modify time scale', 0.0, 1.5)..step(0.01 )..onChange( (x){return modifyTimeScale(x);} );

    folder1.open();
    folder2.open();
    folder3.open();

    // crossFadeControls.forEach((GuiWidget control ) {
    //   control.setInactive = () {
    //     control.domElement.classList.add( 'control-inactive' );
    //   };

    //   control.setActive = () {
    //     control.domElement.classList.remove( 'control-inactive' );
    //   };

    //   final settings = baseActions[ control.property ];

    //   if ( ! settings || ! settings.weight ) {
    //     control.setInactive();
    //   }
    // } );
  }

  void activateAction(three.AnimationAction action ) {
    final clip = action.getClip();
    final settings = baseActions[ clip.name ] ?? additiveActions[ clip.name ];
    setWeight( action, settings['weight'] );
    action.play();
  }

  void modifyTimeScale(double speed ) {
    mixer.timeScale = speed;
  }

  void prepareCrossFade( startAction, endAction, duration ) {

    // If the current action is 'idle', execute the crossfade immediately;
    // else wait until the current action has finished its current loop

    if ( currentBaseAction == 'idle' || ! startAction || ! endAction ) {
      executeCrossFade( startAction, endAction, duration );
    } else {
      synchronizeCrossFade( startAction, endAction, duration );
    }

    // Update control colors

    if ( endAction ) {
      final clip = endAction.getClip();
      currentBaseAction = clip.name;
    } else {
      currentBaseAction = 'None';
    }

    crossFadeControls.forEach(( control ) {
      final name = control.property;

      if ( name == currentBaseAction ) {
        control.setActive();
      } else {
        control.setInactive();
      }
    } );
  }

  void synchronizeCrossFade(three.AnimationAction startAction,three.AnimationAction  endAction, double duration ) {
    onLoopFinished( event ) {
      if ( event.action == startAction ) {
        mixer.removeEventListener( 'loop', onLoopFinished );
        executeCrossFade( startAction, endAction, duration );
      }
    }

    mixer.addEventListener( 'loop', onLoopFinished );
  }

  void executeCrossFade(three.AnimationAction? startAction,three.AnimationAction? endAction,double duration ) {
    // Not only the start action, but also the end action must get a weight of 1 before fading
    // (concerning the start action this is already guaranteed in this place)

    if ( endAction != null) {
      setWeight( endAction, 1 );
      endAction.time = 0;

      if ( startAction != null) {
        // Crossfade with warping
        startAction.crossFadeTo( endAction, duration, true );
      } else {
        // Fade in
        endAction.fadeIn( duration );
      }
    } else {
      // Fade out
      startAction?.fadeOut( duration );
    }
  }

  // This function is needed, since animationAction.crossFadeTo() disables its start action and sets
  // the start action's timeScale to ((start animation's duration) / (end animation's duration))

  void setWeight(three.AnimationAction action,double weight ) {
    action.enabled = true;
    action.setEffectiveTimeScale( 1 );
    action.setEffectiveWeight( weight );
  }
}
