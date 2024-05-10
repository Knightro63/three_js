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

//import 'package:example/games/games_fps2.dart';

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
      page = webgl_materials_browser(fileName: fileName);
    } else if (fileName == "webgl_shadow_contact") {
      page = WebglShadowContact(fileName: fileName);
    } else if (fileName == "webgl_geometry_text") {
      page = webgl_geometry_text(fileName: fileName);
    } else if (fileName == "webgl_geometry_shapes") {
      page = webgl_geometry_shapes(fileName: fileName);
    } else if (fileName == "webgl_instancing_performance") {
      page = webgl_instancing_performance(fileName: fileName);
    } else if (fileName == "webgl_shadowmap_viewer") {
      page = webgl_shadowmap_viewer(fileName: fileName);
    } else if (fileName == "webgl_loader_gltf") {
      page = webgl_loader_gltf(fileName: fileName);
    } else if (fileName == "webgl_loader_gltf_test") {
      page = webgl_loader_gltf_test(fileName: fileName);
    } else if (fileName == "webgl_loader_obj_mtl") {
      page = webgl_loader_obj_mtl(fileName: fileName);
    } else if (fileName == "webgl_animation_keyframes") {
      page = webgl_animation_keyframes(fileName: fileName);
    } else if (fileName == "webgl_loader_texture_basis") {
      page = webgl_loader_texture_basis(fileName: fileName);
    } else if (fileName == "webgl_animation_multiple") {
      page = webgl_animation_multiple(fileName: fileName);
    } else if (fileName == "webgl_skinning_simple") {
      page = webgl_skinning_simple(fileName: fileName);
    } else if (fileName == "misc_animation_keys") {
      page = misc_animation_keys(fileName: fileName);
    } else if (fileName == "webgl_clipping_intersection") {
      page = webgl_clipping_intersection(fileName: fileName);
    } else if (fileName == "webgl_clipping_advanced") {
      page = webgl_clipping_advanced(fileName: fileName);
    } else if (fileName == "webgl_clipping_stencil") {
      page = webgl_clipping_stencil(fileName: fileName);
    } else if (fileName == "webgl_clipping") {
      page = webgl_clipping(fileName: fileName);
    } else if (fileName == "webgl_geometries") {
      page = webgl_geometries(fileName: fileName);
    } else if (fileName == "webgl_animation_cloth") {
      page = webgl_animation_cloth(fileName: fileName);
    } else if (fileName == "webgl_materials") {
      page = webgl_materials(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_blending") {
      page = webgl_animation_skinning_blending(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_additive_blending") {
      page = webgl_animation_skinning_additive_blending(fileName: fileName);
    } else if (fileName == "webgl_animation_skinning_morph") {
      page = WebglAnimationSkinningMorph(fileName: fileName);
    } else if (fileName == "webgl_camera") {
      page = WebglCamera(fileName: fileName);
    } else if (fileName == "webgl_geometry_colors") {
      page = webgl_geometry_colors(fileName: fileName);
    } else if (fileName == "webgl_loader_svg") {
      page = webgl_loader_svg(fileName: fileName);
    } else if (fileName == "webgl_helpers") {
      page = webgl_helpers(fileName: fileName);
    } else if (fileName == "webgl_morphtargets") {
      page = webgl_morphtargets(fileName: fileName);
    } else if (fileName == "webgl_morphtargets_sphere") {
      page = webgl_morphtargets_sphere(fileName: fileName);
    } else if (fileName == "webgl_morphtargets_horse") {
      page = webgl_morphtargets_horse(fileName: fileName);
    } else if (fileName == "misc_controls_orbit") {
      page = misc_controls_orbit(fileName: fileName);
    } else if (fileName == "misc_controls_trackball") {
      page = misc_controls_trackball(fileName: fileName);
    } else if (fileName == "misc_controls_arcball") {
      page = misc_controls_arcball(fileName: fileName);
    } else if (fileName == "misc_controls_map") {
      page = misc_controls_map(fileName: fileName);
    } else if (fileName == "webgl_loader_fbx") {
      page = webgl_loader_fbx(fileName: fileName);
    } else if (fileName == "multi_views") {
      page = multi_views(fileName: fileName);
    }
    // else if (fileName == "games_fps") {
    //   page = TestGame(fileName: fileName);
    // } 
    else {
      throw ("ExamplePage fileName $fileName is not support yet ");
    }

    return page;
  }
}
