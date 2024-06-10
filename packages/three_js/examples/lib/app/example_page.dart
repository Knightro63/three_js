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
import 'package:example/instancing/webgl_instancing_raycasting.dart';
import 'package:example/instancing/webgl_instancing_scatter.dart';
import 'package:example/loaders/webgl_loader_fbx_nurbs.dart';
import 'package:example/loaders/webgl_loader_gcode.dart';
import 'package:example/loaders/webgl_loader_glb.dart';
import 'package:example/loaders/webgl_loader_ply.dart';
import 'package:example/loaders/webgl_loader_stl.dart';
import 'package:example/loaders/webgl_loader_usdz.dart';
import 'package:example/loaders/webgl_loader_vox.dart';
import 'package:example/loaders/webgl_loader_xyz.dart';
import 'package:example/others/webgl_interactive_voxelpainter.dart';
import 'package:example/others/webgl_lod.dart';
import 'package:example/volume/webgl_ubo_arrays.dart';
import 'package:example/shadow/webgl_lensflars.dart';
import 'package:example/shadow/webgl_lights_rectarealight.dart';
import 'package:example/shadow/webgl_lights_spotlight.dart';
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

//import 'package:example/games/games_fps.dart';

@immutable
class ExamplePage extends StatefulWidget {
  final String? id;
  const ExamplePage({super.key, this.id});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExamplePage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;

    String fileName = widget.id!;

    if (fileName == "webgl_camera_array") {
      page = WebglCameraArray(fileName: fileName);
    } 

    else if (fileName == "webgl_materials_browser") {
      page = WebglMaterialsBrowser(fileName: fileName);
    } 
    else if (fileName == "webgl_shadow_contact") {
      page = WebglShadowContact(fileName: fileName);
    } 
    else if(fileName == 'webgl_shadowmap_vsm'){
      page = WebglShadowmapVsm(fileName: fileName);
    }
    else if(fileName == 'webgl_shadowmap_csm'){
      page = WebglShadowmapCsm(fileName: fileName);
    }
    else if(fileName == 'webgl_lights_spotlight'){
      page = WebglLightsSpotlight(fileName: fileName);
    }
    else if (fileName == "webgl_geometry_text") {
      page = WebglGeometryText(fileName: fileName);
    } else if (fileName == "webgl_geometry_shapes") {
      page = WebglGeometryShapes(fileName: fileName);
    } 
    else if(fileName == "webgl_geometry_extrude_shapes"){
      page = WebglGeometryExtrudeShapes(fileName: fileName);
    }
    else if(fileName == "webgl_geometry_dynamic"){
      page = WebglGeometryDynamic(fileName: fileName);
    }
    else if(fileName == "webgl_geometry_extrude_splines"){
      page = WebglGeometryExtrudeSplines(fileName: fileName);
    }
    else if(fileName == 'webgl_decals'){
      page = WebglDecals(fileName: fileName);
    }
    // else if(fileName == "webgl_nodes_points"){
    //   page = ;
    // }
    else if(fileName == "webgl_sprites"){
      page = WebglSprites(fileName: fileName);
    }
    else if(fileName == 'webgl_points_sprites'){
      page = WebglPointsSprites(fileName: fileName);
    }
    else if(fileName == 'webgl_instancing_scatter'){
      page = WebglInstancingScatter(fileName: fileName);
    }
    else if (fileName == "webgl_instancing_performance") {
      page = WebglInstancingPerformance(fileName: fileName);
    } else if(fileName == "webgl_instancing_raycast"){
      page = WebglInstancingRaycast(fileName: fileName);
    } else if(fileName == "webgl_instancing_dynamic"){
      page = WebglInstancingDynamic(fileName: fileName);
    } 
    else if(fileName == "webgl_interactive_voxelpainter"){
      page = WebglInteractiveVoxelpainter(fileName: fileName);
    } 
    else if(fileName == "webgl_gpgpu_protoplanet"){
      page = WebglGpgpuProtoplanet(fileName: fileName);
    }
    else if (fileName == "webgl_shadowmap_viewer") {
      page = WebglShadowmapViewer(fileName: fileName);
    }
    else if(fileName == "webgl_shadowmap_pointlight"){
      page = WebglShadowmapPointlight(fileName: fileName);
    }
    else if (fileName == "webgl_loader_texture_basis") {
      page = WebglLoaderTextureBasis(fileName: fileName);
    } 
    else if(fileName == "webgl_loader_ply"){
      page = WebglLoaderPly(fileName: fileName);
    }
    else if(fileName == "webgl_loader_stl"){
      page = WebglLoaderStl(fileName: fileName);
    }
    else if(fileName == "webgl_loader_vox"){
      page = WebglLoaderVox(fileName: fileName);
    }
    else if (fileName == "webgl_loader_svg") {
      page = WebglLoaderSvg(fileName: fileName);
    } 
    else if (fileName == "webgl_loader_fbx") {
      page = WebglLoaderFbx(fileName: fileName);
    } 
    else if(fileName == "webgl_loader_fbx_nurbs"){
      page = WebglLoaderFbxNurbs(fileName: fileName);
    }
    else if (fileName == "webgl_loader_gltf") {
      page = WebglLoaderGltf(fileName: fileName);
    } 
    else if (fileName == "webgl_loader_glb") {
      page = WebglLoaderGlb(fileName: fileName);
    }
    else if (fileName == "webgl_loader_obj") {
      page = WebglLoaderObj(fileName: fileName);
    }  
    else if (fileName == "webgl_loader_obj_mtl") {
      page = WebglLoaderObjMtl(fileName: fileName);
    } 
    else if(fileName == "webgl_loader_gcode"){
      page = WebglLoaderGcode(fileName: fileName);
    }
    else if(fileName == "webgl_loader_usdz"){
      page = WebglLoaderUsdz(fileName: fileName);
    }
    else if(fileName == "webgl_loader_xyz"){
      page = WebglLoaderXyz(fileName: fileName);
    }
    else if (fileName == "webgl_animation_keyframes") {
      page = WebglAnimationKeyframes(fileName: fileName);
    } 

    else if (fileName == "webgl_animation_multiple") {
      page = WebglAnimationMultiple(fileName: fileName);
    } else if (fileName == "webgl_skinning_simple") {
      page = WebglSkinningSimple(fileName: fileName);
    } else if (fileName == "misc_animation_keys") {
      page = MiscAnimationKeys(fileName: fileName);
    } else if (fileName == "webgl_clipping_intersection") {
      page = WebglClippingIntersection(fileName: fileName);
    } else if (fileName == "webgl_clipping_advanced") {
      page = WebglClippingAdvanced(fileName: fileName);
    } else if (fileName == "webgl_clipping_stencil") {
      page = WebglClippingStencil(fileName: fileName);
    } else if (fileName == "webgl_clipping") {
      page = WebglClipping(fileName: fileName);
    } 
    else if (fileName == "webgl_geometries") {
      page = WebglGeometries(fileName: fileName);
    } 
    else if(fileName == "webgl_buffergeometry_custom_attributes_particles"){
      page = WebglBuffergeometryCustomAttributesParticles(fileName: fileName);
    }
    else if (fileName == "webgl_materials") {
      page = WebglMaterials(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_blending") {
      page = WebglAnimationSkinningBlending(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_additive_blending") {
      page = WebglAnimationSkinningAdditiveBlending(fileName: fileName);
    } 
    // else if(fileName == "webgl_animation_skinning_ik"){
    //   page = ;
    // }
    else if (fileName == "webgl_animation_skinning_morph") {
      page = WebglAnimationSkinningMorph(fileName: fileName);
    } else if (fileName == "webgl_camera") {
      page = WebglCamera(fileName: fileName);
    } 
    else if (fileName == "webgl_geometry_colors") {
      page = WebglGeometryColors(fileName: fileName);
    }
    else if(fileName == 'webgl_simple_gi'){
      page = WebglSimpleGi(fileName: fileName);
    }
    else if(fileName == "webgl_lensflares"){
      page = WebglLensflars(fileName: fileName);
    }
    else if(fileName == "webgl_lights_rectarealight"){
      page = WebglLightsRectarealight(fileName: fileName);
    }
    else if(fileName == "webgl_postprocessing_sobel"){
      page = WebglPostprocessingSobel(fileName: fileName);
    }
    else if(fileName == "webgl_water"){
      page = WebglWater(fileName: fileName);
    }
    // else if(fileName == "webgl_geometry_csg"){

    // } 

    else if (fileName == "webgl_helpers") {
      page = WebglHelpers(fileName: fileName);
    }
    // else if(fileName == 'webgl_modifier_subdivision'){
    //   page = WebglModifierSubdivision(fileName: fileName);
    // }
    else if (fileName == "webgl_morphtargets") {
      page = WebglMorphtargets(fileName: fileName);
    } else if (fileName == "webgl_morphtargets_sphere") {
      page = WebglMorphtargetsSphere(fileName: fileName);
    } else if (fileName == "webgl_morphtargets_horse") {
      page = WebglMorphtargetsHorse(fileName: fileName);
    } 
    // else if(fileName == 'webgl_morphtargets_face'){
    //   page = WebglMorphtargetsFace(fileName: fileName);
    // } 
    else if (fileName == "misc_controls_orbit") {
      page = MiscControlsOrbit(fileName: fileName);
    } else if (fileName == "misc_controls_trackball") {
      page = MiscControlsTrackball(fileName: fileName);
    } else if (fileName == "misc_controls_arcball") {
      page = MiscControlsArcball(fileName: fileName);
    } else if (fileName == "misc_controls_map") {
      page = MiscControlsMap(fileName: fileName);
    }else if (fileName == "misc_controls_pointerlock") {
      page = MiscControlsPointerlock(fileName: fileName);
    } else if (fileName == "misc_controls_fly") {
      page = MiscControlsFly(fileName: fileName);
    }else if (fileName == "misc_controls_transform") {
      page = MiscControlsTransform(fileName: fileName);
    } 
    else if (fileName == "multi_views") {
      page = MultiViews(fileName: fileName);
    }else if (fileName == "games_fps") {
      page = FPSGame2(fileName: fileName);
    }
    else if (fileName == "flutter_game") {
      page = FlutterGame(fileName: fileName);
    }
    else if(fileName == "webgl_lod"){
      page = WebglLod(fileName: fileName);
    }
    else if (fileName == "marching_cubes") {
      page = Marching(fileName: fileName);
    }
    else if(fileName == 'webgl_shader_lava'){
      page = WebglShaderLava(fileName: fileName);
    }
    else if (fileName == "webgl_volume_perlin") {
      page = WebglVolumePerlin(fileName: fileName);
    }
    else if (fileName == "webgl_volume_cloud") {
      page = WebglVolumeCloud(fileName: fileName);
    }
    else if(fileName == 'webgl_volume_instancing'){
      page = WebglVolumeInstancing(fileName: fileName);
    }
    else if (fileName == "webgl_ubo_arrays") {
      page = WebglUboArrays(fileName: fileName);
    }
    else {
      throw ("ExamplePage fileName $fileName is not support yet ");
    }

    return page;
  }
}
