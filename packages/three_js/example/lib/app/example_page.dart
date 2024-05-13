import 'package:flutter/material.dart';

import 'package:example/animations/misc_animation_keys.dart';
import 'package:example/animations/webgl_animation_cloth.dart';
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
import 'package:example/others/webgl_instancing_performance.dart';
import 'package:example/others/webgl_skinning_simple.dart';

import 'package:example/loaders/webgl_loader_fbx.dart';
import 'package:example/loaders/webgl_loader_gltf.dart';
import 'package:example/loaders/webgl_loader_gltf_test.dart';
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

import 'package:example/games/games_fps.dart';

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
    } else if (fileName == "webgl_loader_obj") {
      page = WebglLoaderObj(fileName: fileName);
    } else if (fileName == "webgl_materials_browser") {
      page = WebglMaterialsBrowser(fileName: fileName);
    } else if (fileName == "webgl_shadow_contact") {
      page = WebglShadowContact(fileName: fileName);
    } else if (fileName == "webgl_geometry_text") {
      page = WebglGeometryText(fileName: fileName);
    } else if (fileName == "webgl_geometry_shapes") {
      page = WebglGeometryShapes(fileName: fileName);
    } else if (fileName == "webgl_instancing_performance") {
      page = WebglInstancingPerformance(fileName: fileName);
    } else if (fileName == "webgl_shadowmap_viewer") {
      page = WebglShadowmapViewer(fileName: fileName);
    } else if (fileName == "webgl_loader_gltf") {
      page = WebglLoaderGltf(fileName: fileName);
    } else if (fileName == "webgl_loader_gltf_test") {
      page = webgl_loader_gltf_test(fileName: fileName);
    } else if (fileName == "webgl_loader_obj_mtl") {
      page = WebglLoaderObjMtl(fileName: fileName);
    } else if (fileName == "webgl_animation_keyframes") {
      page = WebglAnimationKeyframes(fileName: fileName);
    } else if (fileName == "webgl_loader_texture_basis") {
      page = WebglLoaderTextureBasis(fileName: fileName);
    } else if (fileName == "webgl_animation_multiple") {
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
    } else if (fileName == "webgl_geometries") {
      page = WebglGeometries(fileName: fileName);
    } else if (fileName == "webgl_animation_cloth") {
      page = webgl_animation_cloth(fileName: fileName);
    } else if (fileName == "webgl_materials") {
      page = WebglMaterials(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_blending") {
      page = WebglAnimationSkinningBlending(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_additive_blending") {
      page = WebglAnimationSkinningAdditiveBlending(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_morph") {
      page = WebglAnimationSkinningMorph(fileName: fileName);
    } else if (fileName == "webgl_camera") {
      page = WebglCamera(fileName: fileName);
    } else if (fileName == "webgl_geometry_colors") {
      page = WebglGeometryColors(fileName: fileName);
    } else if (fileName == "webgl_loader_svg") {
      page = WebglLoaderSvg(fileName: fileName);
    } else if (fileName == "webgl_helpers") {
      page = WebglHelpers(fileName: fileName);
    } else if (fileName == "webgl_morphtargets") {
      page = WebglMorphtargets(fileName: fileName);
    } else if (fileName == "webgl_morphtargets_sphere") {
      page = WebglMorphtargetsSphere(fileName: fileName);
    } else if (fileName == "webgl_morphtargets_horse") {
      page = WebglMorphtargetsHorse(fileName: fileName);
    } else if (fileName == "misc_controls_orbit") {
      page = MiscControlsOrbit(fileName: fileName);
    } else if (fileName == "misc_controls_trackball") {
      page = MiscControlsTrackball(fileName: fileName);
    } else if (fileName == "misc_controls_arcball") {
      page = MiscControlsArcball(fileName: fileName);
    } else if (fileName == "misc_controls_map") {
      page = MiscControlsMap(fileName: fileName);
    } else if (fileName == "webgl_loader_fbx") {
      page = WebglLoaderFbx(fileName: fileName);
    } else if (fileName == "multi_views") {
      page = MultiViews(fileName: fileName);
    }else if (fileName == "games_fps") {
      page = FPSGame(fileName: fileName);
    } 
    else {
      throw ("ExamplePage fileName $fileName is not support yet ");
    }

    return page;
  }
}
