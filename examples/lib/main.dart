import 'dart:io';
import 'package:example/audio/orientation.dart';
import 'package:example/audio/sandbox.dart';
import 'package:example/audio/timing.dart';
import 'package:example/controls/misc_controls_device_orientation.dart';
import 'package:example/controls/misc_controls_fly.dart';
import 'package:example/controls/misc_controls_pointerlock.dart';
import 'package:example/controls/misc_controls_transform.dart';
import 'package:example/games/flutter_game.dart';
import 'package:example/games/games_fps2.dart';
import 'package:example/geometry/marching_cubes.dart';
import 'package:example/geometry/webgl_buffergeometry_custom_attributes_particles.dart';
import 'package:example/geometry/webgl_decals.dart';
import 'package:example/geometry/webgl_geometry_dynamic.dart';
import 'package:example/geometry/webgl_geometry_extrude_shapes.dart';
import 'package:example/geometry/webgl_geometry_extrude_splines.dart';
import 'package:example/geometry/webgl_points_sprites.dart';
import 'package:example/geometry/webgl_sprites.dart';
import 'package:example/instancing/webgl_gpgpu_protoplanet.dart';
import 'package:example/instancing/webgl_instancing_dynamic.dart';
import 'package:example/instancing/webgl_instancing_morph.dart';
import 'package:example/instancing/webgl_instancing_raycasting.dart';
import 'package:example/instancing/webgl_instancing_scatter.dart';
import 'package:example/lights/webgl_lightprobe_cube_camera.dart';
import 'package:example/loaders/webgl_loader_collada.dart';
import 'package:example/loaders/webgl_loader_collada_kinematics.dart';
import 'package:example/loaders/webgl_loader_collada_skinning.dart';
import 'package:example/loaders/webgl_loader_fbx_nurbs.dart';
import 'package:example/loaders/webgl_loader_gcode.dart';
import 'package:example/loaders/webgl_loader_glb.dart';
import 'package:example/loaders/webgl_loader_md2.dart';
import 'package:example/loaders/webgl_loader_ply.dart';
import 'package:example/loaders/webgl_loader_scn.dart';
import 'package:example/loaders/webgl_loader_stl.dart';
import 'package:example/loaders/webgl_loader_usdz.dart';
import 'package:example/loaders/webgl_loader_vox.dart';
import 'package:example/loaders/webgl_loader_xyz.dart';
import 'package:example/material/webgl_materials_modified.dart';
import 'package:example/modifers/webgl_modifier_simplifier.dart';
import 'package:example/modifers/webgl_modifier_subdivision.dart';
import 'package:example/others/webgl_buffergeometry_instancing_billboards.dart';
import 'package:example/others/webgl_custom_attributes_lines.dart';
import 'package:example/others/webgl_interactive_voxelpainter.dart';
import 'package:example/others/webgl_lod.dart';
import 'package:example/others/webgl_portal.dart';
import 'package:example/src/files_json.dart';
import 'package:example/terrain/webgl_geometry_terrain.dart';
import 'package:example/terrain/webgl_geometry_terrain_raycast.dart';
import 'package:example/volume/webgl_ubo_arrays.dart';
import 'package:example/shadow/webgl_lensflars.dart';
import 'package:example/lights/webgl_lights_rectarealight.dart';
import 'package:example/lights/webgl_lights_spotlight.dart';
import 'package:example/shadow/webgl_postprocessing_sobel.dart';
import 'package:example/shadow/webgl_shader_lava.dart';
import 'package:example/shadow/webgl_shadowmap_csm.dart';
import 'package:example/shadow/webgl_shadowmap_pointlight.dart';
import 'package:example/shadow/webgl_shadowmap_vsm.dart';
import 'package:example/shadow/webgl_simple_gi.dart';
import 'package:example/shadow/webgl_water.dart';
import 'package:example/volume/webgl_volume_cloud.dart';
import 'package:example/volume/webgl_volume_instancing.dart';
import 'package:example/volume/webgl_volume_perlin.dart';
import 'package:flutter/material.dart';

import 'package:example/animations/misc_animation_keys.dart';
import 'package:example/animations/webgl_animation_keyframes.dart';
import 'package:example/animations/webgl_animation_multiple.dart';
import 'package:example/animations/webgl_animation_skinning_additive_blending.dart';
import 'package:example/animations/webgl_animation_skinning_blending.dart';
import 'package:example/animations/webgl_animation_skinning_morph.dart';

import 'package:example/camera/webgl_camera.dart';
import 'package:example/camera/webgl_camera_array.dart';

import 'package:example/clipping/webgl_clipping.dart';
import 'package:example/clipping/webgl_clipping_advanced.dart';
import 'package:example/clipping/webgl_clipping_intersection.dart';
import 'package:example/clipping/webgl_clipping_stencil.dart';

import 'package:example/geometry/webgl_geometries.dart';
import 'package:example/geometry/webgl_geometry_colors.dart';
import 'package:example/geometry/webgl_geometry_shapes.dart';
import 'package:example/geometry/webgl_geometry_text.dart';

import 'package:example/others/multi_views.dart';
import 'package:example/others/webgl_helpers.dart';
import 'package:example/instancing/webgl_instancing_performance.dart';
import 'package:example/morphtargets/webgl_skinning_simple.dart';

import 'package:example/loaders/webgl_loader_fbx.dart';
import 'package:example/loaders/webgl_loader_gltf.dart';
import 'package:example/loaders/webgl_loader_obj.dart';
import 'package:example/loaders/webgl_loader_obj_mtl.dart';
import 'package:example/loaders/webgl_loader_texture_basis.dart';
import 'package:example/loaders/webgl_loader_svg.dart';

import 'package:example/material/webgl_materials.dart';
import 'package:example/material/webgl_materials_browser.dart';

import 'package:example/morphtargets/webgl_morphtargets.dart';
import 'package:example/morphtargets/webgl_morphtargets_horse.dart';
import 'package:example/morphtargets/webgl_morphtargets_sphere.dart';

import 'package:example/shadow/webgl_shadow_contact.dart';
import 'package:example/shadow/webgl_shadowmap_viewer.dart';

import 'package:example/controls/misc_controls_arcball.dart';
import 'package:example/controls/misc_controls_map.dart';
import 'package:example/controls/misc_controls_orbit.dart';
import 'package:example/controls/misc_controls_trackball.dart';

import 'package:css/css.dart';
import 'package:flutter/foundation.dart';

import 'src/plugins/plugin.dart';
void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}
class MyApp extends StatefulWidget{
  const MyApp({super.key,}) ;

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  String onPage = '';
  double pageLocation = 0;

  void callback(String page, [double? location]){
    onPage = page;
    if(location != null){
      pageLocation = location;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
      _navKey.currentState!.popAndPushNamed('/$page');
      setState(() {});
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    widthInifity = MediaQuery.of(context).size.width;
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Three_JS',
        theme: CSS.darkTheme,
        home: Scaffold(
          appBar: (kIsWeb||!Platform.isAndroid) && onPage != ''? PreferredSize(
            preferredSize: Size(widthInifity,65),
            child:AppBar(callback: callback,page: onPage,)
          ):null,
          body: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Three_JS',
            theme: CSS.darkTheme,
            navigatorKey: _navKey,
            routes: {
              '/':(BuildContext context) {
                return Examples(
                  callback: callback,
                  prevLocation: pageLocation,
                );
              },
              '/timing':(BuildContext context) {
                return const AudioTiming();
              },
              '/orientation':(BuildContext context) {
                return const AudioOrientation();
              },
              '/sandbox':(BuildContext context) {
                return const AudioSandbox();
              },
              '/webgl_camera_array':(BuildContext context) {
                return const WebglCameraArray();
              },
              '/webgl_materials_browser':(BuildContext context) {
                return const WebglMaterialsBrowser();
              },
              '/webgl_shadow_contact':(BuildContext context) {
                return const WebglShadowContact();
              },
              '/webgl_shadowmap_vsm':(BuildContext context) {
                return const WebglShadowmapVsm();
              },
              '/webgl_shadowmap_csm':(BuildContext context) {
                return const WebglShadowmapCsm();
              },
              '/webgl_lights_spotlight':(BuildContext context) {
                return const WebglLightsSpotlight();
              },
              '/webgl_lightprobe_cube_camera':(BuildContext context) {
                return const WebglLightprobeCubeCamera();
              },
              '/webgl_geometry_text':(BuildContext context) {
                return const WebglGeometryText();
              },
              '/webgl_geometry_shapes':(BuildContext context) {
                return const WebglGeometryShapes();
              },
              '/webgl_geometry_extrude_shapes':(BuildContext context) {
                return const WebglGeometryExtrudeShapes();
              },
              '/webgl_geometry_dynamic':(BuildContext context) {
                return const WebglGeometryDynamic();
              },
              '/webgl_geometry_extrude_splines':(BuildContext context) {
                return const WebglGeometryExtrudeSplines();
              },
              '/webgl_decals':(BuildContext context) {
                return const WebglDecals();
              },
              '/webgl_sprites':(BuildContext context) {
                return const WebglSprites();
              },
              '/webgl_points_sprites':(BuildContext context) {
                return const WebglPointsSprites();
              },
              '/webgl_instancing_scatter':(BuildContext context) {
                return const WebglInstancingScatter();
              },
              '/webgl_instancing_performance':(BuildContext context) {
                return const WebglInstancingPerformance();
              },
              '/webgl_instancing_raycast':(BuildContext context) {
                return const WebglInstancingRaycast();
              },
              '/webgl_instancing_dynamic':(BuildContext context) {
                return const WebglInstancingDynamic();
              },
              '/webgl_instancing_morph':(BuildContext context) {
                return const WebglInstancingMorph();
              },
              '/webgl_interactive_voxelpainter':(BuildContext context) {
                return const WebglInteractiveVoxelpainter();
              },
              '/webgl_gpgpu_protoplanet':(BuildContext context) {
                return const WebglGpgpuProtoplanet();
              },
              '/webgl_shadowmap_viewer':(BuildContext context) {
                return const WebglShadowmapViewer();
              },
              '/webgl_shadowmap_pointlight':(BuildContext context) {
                return const WebglShadowmapPointlight();
              },
              '/webgl_geometry_terrain':(BuildContext context) {
                return const WebglGeometryTerrain();
              },
              '/webgl_geometry_terrain_raycast':(BuildContext context) {
                return const WebglGeometryTerrainRaycast();
              },
              '/webgl_loader_texture_basis':(BuildContext context) {
                return const WebglLoaderTextureBasis();
              },
              '/webgl_loader_collada':(BuildContext context) {
                return const WebglLoaderCollada();
              },
              '/webgl_loader_collada_skinning':(BuildContext context) {
                return const WebglLoaderColladaSkinning();
              },
              '/webgl_loader_collada_kinematics':(BuildContext context) {
                return const WebglLoaderColladaKinematics();
              },
              '/webgl_loader_ply':(BuildContext context) {
                return const WebglLoaderPly();
              },
              '/webgl_loader_stl':(BuildContext context) {
                return const WebglLoaderStl();
              },
              '/webgl_loader_vox':(BuildContext context) {
                return const WebglLoaderVox();
              },
              '/webgl_loader_svg':(BuildContext context) {
                return const WebglLoaderSvg();
              },
              '/webgl_loader_fbx':(BuildContext context) {
                return const WebglLoaderFbx();
              },
              '/webgl_loader_fbx_nurbs':(BuildContext context) {
                return const WebglLoaderFbxNurbs();
              },
              '/webgl_loader_gltf':(BuildContext context) {
                return const WebglLoaderGltf();
              },
              '/webgl_loader_glb':(BuildContext context) {
                return const WebglLoaderGlb();
              },
              '/webgl_loader_md2':(BuildContext context) {
                return const WebglLoaderMd2();
              },
              '/webgl_loader_obj':(BuildContext context) {
                return const WebglLoaderObj();
              },
              '/webgl_loader_obj_mtl':(BuildContext context) {
                return const WebglLoaderObjMtl();
              },
              '/webgl_loader_gcode':(BuildContext context) {
                return const WebglLoaderGcode();
              },
              '/webgl_loader_scn':(BuildContext context) {
                return const WebglLoaderSCN();
              },
              '/webgl_loader_usdz':(BuildContext context) {
                return const WebglLoaderUsdz();
              },
              '/webgl_loader_xyz':(BuildContext context) {
                return const WebglLoaderXyz();
              },
              '/webgl_animation_keyframes':(BuildContext context) {
                return const WebglAnimationKeyframes();
              },
              '/webgl_animation_multiple':(BuildContext context) {
                return const WebglAnimationMultiple();
              },
              '/webgl_skinning_simple':(BuildContext context) {
                return const WebglSkinningSimple();
              },
              '/misc_animation_keys':(BuildContext context) {
                return const MiscAnimationKeys();
              },
              '/webgl_clipping_intersection':(BuildContext context) {
                return const WebglClippingIntersection();
              },
              '/webgl_clipping_advanced':(BuildContext context) {
                return const WebglClippingAdvanced();
              },
              '/webgl_clipping_stencil':(BuildContext context) {
                return const WebglClippingStencil();
              },
              '/webgl_clipping':(BuildContext context) {
                return const WebglClipping();
              },
              '/webgl_geometries':(BuildContext context) {
                return const WebglGeometries();
              },
              '/webgl_buffergeometry_custom_attributes_particles':(BuildContext context) {
                return const WebglBuffergeometryCustomAttributesParticles();
              },
              '/webgl_buffergeometry_instancing_billboards':(BuildContext context) {
                return const WebglBuffergeometryInstancingBillboards();
              },
              '/webgl_custom_attributes_lines':(BuildContext context) {
                return const WebglCustomAttributesLines();
              },
              '/webgl_materials':(BuildContext context) {
                return const WebglMaterials();
              },
              '/webgl_materials_modified':(BuildContext context) {
                return const WebglMaterialsModified();
              },
              '/webgl_animation_skinning_blending':(BuildContext context) {
                return const WebglAnimationSkinningBlending();
              },
              '/webgl_animation_skinning_additive_blending':(BuildContext context) {
                return const WebglAnimationSkinningAdditiveBlending();
              },
              '/webgl_animation_skinning_morph':(BuildContext context) {
                return const WebglAnimationSkinningMorph();
              },
              '/webgl_camera':(BuildContext context) {
                return const WebglCamera();
              },
              '/webgl_geometry_colors':(BuildContext context) {
                return const WebglGeometryColors();
              },
              '/webgl_simple_gi':(BuildContext context) {
                return const WebglSimpleGi();
              },
              '/webgl_lensflares':(BuildContext context) {
                return const WebglLensflars();
              },
              '/webgl_lights_rectarealight':(BuildContext context) {
                return const WebglLightsRectarealight();
              },
              '/webgl_postprocessing_sobel':(BuildContext context) {
                return const WebglPostprocessingSobel();
              },
              '/webgl_water':(BuildContext context) {
                return const WebglWater();
              },
              '/webgl_helpers':(BuildContext context) {
                return const WebglHelpers();
              },
              '/webgl_portal':(BuildContext context) {
                return const WebglPortal();
              },
              '/webgl_modifier_subdivision':(BuildContext context) {
                return const WebglModifierSubdivision();
              },
              '/webgl_modifier_simplifier':(BuildContext context) {
                return const WebglModifierSimplifier();
              },
              '/webgl_morphtargets':(BuildContext context) {
                return const WebglMorphtargets();
              },
              '/webgl_morphtargets_sphere':(BuildContext context) {
                return const WebglMorphtargetsSphere();
              },
              '/webgl_morphtargets_horse':(BuildContext context) {
                return const WebglMorphtargetsHorse();
              },
              '/misc_controls_orbit':(BuildContext context) {
                return const MiscControlsOrbit();
              },
              '/misc_controls_trackball':(BuildContext context) {
                return const MiscControlsTrackball();
              },
              '/misc_controls_arcball':(BuildContext context) {
                return const MiscControlsArcball();
              },
              '/misc_controls_map':(BuildContext context) {
                return const MiscControlsMap();
              },
              '/misc_controls_pointerlock':(BuildContext context) {
                return const MiscControlsPointerlock();
              },
              '/misc_controls_fly':(BuildContext context) {
                return const MiscControlsFly();
              },
              '/misc_controls_transform':(BuildContext context) {
                return const MiscControlsTransform();
              },
              '/misc_controls_device_orientation':(BuildContext context){
                return const MiscControlsDeviceOrientation();
              },
              '/multi_views':(BuildContext context) {
                return const MultiViews();
              },
              '/games_fps':(BuildContext context) {
                return const FPSGame2();
              },
              '/flutter_game':(BuildContext context) {
                return const FlutterGame();
              },
              '/webgl_lod':(BuildContext context) {
                return const WebglLod();
              },
              '/marching_cubes':(BuildContext context) {
                return const Marching();
              },
              '/webgl_shader_lava':(BuildContext context) {
                return const WebglShaderLava();
              },
              '/webgl_volume_perlin':(BuildContext context) {
                return const WebglVolumePerlin();
              },
              '/webgl_volume_cloud':(BuildContext context) {
                return const WebglVolumeCloud();
              },
              '/webgl_volume_instancing':(BuildContext context) {
                return const WebglVolumeInstancing();
              },
              '/webgl_ubo_arrays':(BuildContext context) {
                return const WebglUboArrays();
              },
            }
          ),
        )
      )
    );
  }
}

@immutable
class AppBar extends StatelessWidget{
  const AppBar({
    super.key,
    required this.page,
    required this.callback
  });
  final String page;
  final void Function(String page,[double? loc]) callback;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(left: 10),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          InkWell(
            onTap: (){
              callback('');
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded
            ),
          ),
          const SizedBox(width: 20,),
          Text(
            (page[0]+page.substring(1)).replaceAll('_', ' ').toUpperCase(),
            style: Theme.of(context).primaryTextTheme.bodyMedium,
          )
        ],
      ),
    );
  }
}

class Examples extends StatefulWidget{
  const Examples({
    super.key,
    required this.callback,
    required this.prevLocation
  });

  final void Function(String page,[double? location]) callback;
  final double prevLocation;

  @override
  ExamplesPageState createState() => ExamplesPageState();
}

class ExamplesPageState extends State<Examples> {
  double deviceHeight = double.infinity;
  double deviceWidth = double.infinity;
  ScrollController controller = ScrollController();

  List<Widget> displayExamples(){
    List<Widget> widgets = [];

    double response = CSS.responsive(width: 480);

    for(int i = 0;i < filesJson.length;i++){
      widgets.add(
        InkWell(
          onTap: (){
            widget.callback(filesJson[i],controller.offset);
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            width: response-65,
            height: response,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ]
            ),
            child: Column(
              children:[
                Container(
                  width: response,
                  height: response-65,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: ExactAssetImage('assets/screenshots/${filesJson[i]}.jpg'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(topRight:Radius.circular(10),topLeft:Radius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  filesJson[i].replaceAll('_',' ').toUpperCase(),
                  style: Theme.of(context).primaryTextTheme.bodyMedium,
                )
              ]
            )
          )
        )
      );
    }

    return widgets;
  }

  @override
  void initState(){
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
      controller.jumpTo(widget.prevLocation);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      controller: controller,
      child: Wrap(
        runAlignment: WrapAlignment.spaceBetween,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: displayExamples(),
      )
    );
  }
}