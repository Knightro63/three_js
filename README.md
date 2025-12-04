# three_js

[![Pub Version](https://img.shields.io/pub/v/three_js)](https://pub.dev/packages/three_js)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63//three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A 3D rendering engine for dart (based on [three.js](https://github.com/mrdoob/three.js) and [three_dart](https://github.com/wasabia/three_dart)) that allows users to view, edit and manipulate their 3D objects. The current builds uses [angle](https://github.com/google/angle) for desktop and mobile, and WebGL2 for web applications.

## Features

![Gif of dash playing a game.](https://raw.githubusercontent.com/Knightro63/three_js/master/assets/flutter_game.gif)

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

## Requirements

**MacOS**
 - Minimum os Deployment Target: 10.15
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**iOS**
 - Minimum os Deployment Target: 13.0
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**iOS-Simulator**
 - Minimum os Deployment Target: 13.0
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**Android**
 - compileSdkVersion: 34
 - minSdk: 21
 - OpenGL supported
 - Vulkan supported

**Android Emulator**
 - compileSdkVersion: 34
 - minSdk: 21
 - OpenGL supported

**Windows**
 - Intel supported
 - AMD supported
 - Qualcom supported
 - Direct3D 11 supported
 - OpenGL supported

**Web**
 - WebGL2 supported. please add `<script src="https://cdn.jsdelivr.net/gh/Knightro63/flutter_angle/assets/gles_bindings.js"></script>` to your index.html to load the js_interop file.

**WASM**
 - WebGL2 supported. please add `<script src="https://cdn.jsdelivr.net/gh/Knightro63/flutter_angle/assets/gles_bindings.js"></script>` to your index.html to load the js_interop file.

**Linux**
 - Ubuntu supported (Tested on Linux Mint)
 - OpenGL supported

## Getting started

To get started add three_js to your pubspec.yaml file. Adding permissions for audio and video is required if using either item.
Please use [Permission Handler](https://pub.dev/packages/permission_handler) package to help with this.

## Usage

This project is a simple 3D rendering engine for flutter to view, edit, or manipulate 3D models.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js/example/), for more examples you can click [here](https://github.com/Knightro63/three_js/tree/main/examples/), and for a preview go [here](https://knightro63.github.io/three_js/).

## Know Issues

**All**
 - MD2 annimations do not work
 - Collada animations do not work
 - Collada kinnametics does not work
 - PMREM gives weird artifacts or is completely black

**MacOS**
 - N/A

**iOS**
 - Protoplanets does not function correctly

**Android**
 - Morphtargets does not work on some devices
 - Some RGBELoaders cause app to crash
 
**Windows**
 - Tonemapping turns screen black
 - Some RGBELoaders cause app to crash

**Web**
 - Lens Flare not working correctly
 - Simplify modifer has weird artifacts

 **WASM**
 - Simple GI does not work
 - Simplify modifer has weird artifacts

**Linux**
 - Tonemapping turns screen black
 - Postprocessing does not work
 - Track pad does not zoom out
 - Some RGBELoaders cause app to crash

## Libraries and Plugins

**Other Libs**
 - [Advanced Exporters](https://pub.dev/packages/three_js_advanced_exporters) a USDZ exporter to your three_js project.
 - [Audio](https://pub.dev/packages/three_js_audio) an audio api using flutters audioplayer from pub.dev do not use with any other audio package..
 - [Audio Latency](https://pub.dev/packages/three_js_audio_latency) an audio api using SoLoud from pub.dev do not use with any other audio package..
 - [BVH CSG](https://pub.dev/packages/three_js_bvh_csg) a bvh csg api for three_js.
 - [Exporters](https://pub.dev/packages/three_js_exporters) an api to add STL, OBJ or PLY exporter for three_js.
 - [Geometry](https://pub.dev/packages/three_js_geometry) an api to add complex geometries to three_js.
 - [Line](https://pub.dev/packages/three_js_line) an api to add more line types to three_js.
 - [Helpers](https://pub.dev/packages/three_js_helpers) an api to add helpers to three_js.
 - [Modifers](https://pub.dev/packages/three_js_modifers) an api to add simplify or subdivision to three_js.
 - [Post Processing](https://pub.dev/packages/three_js_postprocessing) a post processor to three_js.
 - [SVG](https://pub.dev/packages/three_js_svg) an api to add a svg importer and exporter to three_js.
 - [Three JS Loader](https://pub.dev/packages/three_js_tjs_loader) a loader to add three js json files to three_js.
 - [Transfrom Controls](https://pub.dev/packages/three_js_transform_controls) a transfor controller for 3d objects for three_js.
 - [Video Texture](https://pub.dev/packages/three_js_video_texture) an api to add videos and audio to three_js do not use with any other audio package.

**ADD-ONS**
 - [Omio](https://pub.dev/packages/oimo_physics) a physics engine for three_js.
 - [Cannon](https://pub.dev/packages/cannon_physics) a physics engine for three_js.
 - [Terrain](https://pub.dev/packages/three_js_terrain) a map generator for three_js.
 - [XR](https://pub.dev/packages/three_js_xr) a VR/AR/MR sdk for three_js. (web only)

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.

## Supported Features

All of the current webgl2 core features are supported at this time.<br>
GPU is currently under development, so it is currently not supported.<br>
Please review the following table for all the supported Modules. 

 - ✅ Currently Supported
 - ⚠️ Upon request
 - ❌ Not intended, unless a major update has been accomplished

| Module | Plugin | Web | Mobile | Desktop |
|-----------------------------------------------------------------------------------------------|--------|------------|---------|-----|
|  | <span style="color: #ff00ff;">**Animation**</span> |  |  |  |
| AnimationClipCreator |  | ⚠️ | ⚠️ | ⚠️ |
| CCDIKSolver |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Controls**</span> |  |  |  |
| [ArcballControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_transform_controls/lib/arcball_controls.dart) | [three_js_transform_controls](https://pub.dev/packages/three_js_transform_controls) | ✅ | ✅ | ✅ |
| [DragControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/drag_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [FirstPersonControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/first_person_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [FlyControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/fly_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [MapControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/orbit_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [OrbitControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/orbit_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [PointerLockControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/pointer_lock_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [TrackballControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_controls/lib/trackball_controls.dart) | [three_js_controls](https://pub.dev/packages/three_js_controls) | ✅ | ✅ | ✅ |
| [TransformControls](https://github.com/Knightro63/three_js/blob/main/packages/three_js_transform_controls/lib/transform_controls.dart) | [three_js_transform_controls](https://pub.dev/packages/three_js_transform_controls) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**CSM**</span> |  |  |  |
| [CSM](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/csm/csm.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| [CSMFrustum](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/csm/csm_frustum.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| [CSMHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/csm/csm_helper.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| [CSMShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/csm/csm_shader.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| CSMShadowNode |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Curves**</span> |  |  |  |
| [EXTRAS](https://github.com/Knightro63/three_js/blob/main/packages/three_js_curves/lib/curves/extra.dart) | [three_js_curves](https://pub.dev/packages/three_js_curves) | ✅ | ✅ | ✅ |
| [NURBSCurve](https://github.com/Knightro63/three_js/blob/main/packages/three_js_curves/lib/nurbs/nurbs_curve.dart) | [three_js_curves](https://pub.dev/packages/three_js_curves) | ✅ | ✅ | ✅ |
| [NURBSSurface](https://github.com/Knightro63/three_js/blob/main/packages/three_js_curves/lib/nurbs/nurbs_surface.dart) | [three_js_curves](https://pub.dev/packages/three_js_curves) | ✅ | ✅ | ✅ |
| [NURBSUtils](https://github.com/Knightro63/three_js/blob/main/packages/three_js_curves/lib/nurbs/nurbs_utils.dart) | [three_js_curves](https://pub.dev/packages/three_js_curves) | ✅ | ✅ | ✅ |
| NURBSVolume |  | ⚠️ | ⚠️ | ⚠️ |
|  | <span style="color: #ff00ff;">**Effects**</span> |  |  |  |
| AnaglyphEffect |  | ⚠️ | ⚠️ | ⚠️ |
| AsciiEffect |  | ⚠️ | ⚠️ | ⚠️ |
| OutlineEffect |  | ⚠️ | ⚠️ | ⚠️ |
| ParallaxBarrierEffect |  | ⚠️ | ⚠️ | ⚠️ |
| [StereoEffect](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/stero_effect.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Enviroments**</span> |  |  |  |
| [DebugEnvironment](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/enviroments/debug_environment.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| [RoomEnvironment](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/enviroments/room_environment.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Exporters**</span> |  |  |  |
| DRACOExporter |  | ❌ | ❌ | ❌ |
| EXRExporter |  | ❌ | ❌ | ❌ |
| GLTFExporter |  | ⚠️ | ⚠️ | ⚠️ |
| KTX2Exporter |  | ❌ | ❌ | ❌ |
| [OBJExporter](https://github.com/Knightro63/three_js/blob/main/packages/three_js_exporters/lib/obj_exporter.dart) | [three_js_simple_exporters](https://pub.dev/packages/three_js_exporters) | ✅ | ✅ | ✅ |
| [PLYExporter](https://github.com/Knightro63/three_js/blob/main/packages/three_js_exporters/lib/ply_exporter.dart) | [three_js_simple_exporters](https://pub.dev/packages/three_js_exporters) | ✅ | ✅ | ✅ |
| [STLExporter](https://github.com/Knightro63/three_js/blob/main/packages/three_js_exporters/lib/stl_exporter.dart) | [three_js_simple_exporters](https://pub.dev/packages/three_js_exporters) | ✅ | ✅ | ✅ |
| [USDZExporter](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_exporters/lib/usdz_exporter.dart) | [three_js_advanced_exporters](https://pub.dev/packages/three_js_advanced_exporters) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Geometry**</span> |  |  |  |
| [BoxLineGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_geometry/lib/box_line_geometry.dart) | [three_js_geometry](https://pub.dev/packages/three_js_geometry) | ✅ | ✅ | ✅ |
| [ConvexGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_geometry/lib/convex.dart) | [three_js_geometry](https://pub.dev/packages/three_js_geometry) | ✅ | ✅ | ✅ |
| [DecalGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_geometry/lib/decal_geometry.dart) | [three_js_geometry](https://pub.dev/packages/three_js_geometry) | ✅ | ✅ | ✅ |
| [ParametricFunctions](https://github.com/Knightro63/three_js/blob/main/packages/three_js_geometry/lib/parametric_gemoetries.dart) | [three_js_geometry](https://pub.dev/packages/three_js_geometry) | ✅ | ✅ | ✅ |
| [ParametricGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_geometry/lib/parametric.dart) | [three_js_geometry](https://pub.dev/packages/three_js_geometry) | ✅ | ✅ | ✅ |
| RoundedBoxGeometry |  | ⚠️ | ⚠️ | ⚠️ |
| TeapotGeometry |  | ⚠️ | ⚠️ | ⚠️ |
| [TextGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_text/lib/text/text.dart) | [three_js_text](https://pub.dev/packages/three_js_text) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Helpers**</span> |  |  |  |
| [LightProbeHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/light_probe_helper.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| LightProbeHelperGPU |  | ❌ | ❌ | ❌ |
| [OctreeHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/octree_helper.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| [PositionalAudioHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_core/lib/audio/positional_audio_helper.dart) | [three_js_core](https://pub.dev/packages/three_js_core) | ✅ | ✅ | ✅ |
| RapierHelper |  | ❌ | ❌ | ❌ |
| [RectAreaLightHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/rect_area_light_helper.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| TextureHelper |  | ⚠️ | ⚠️ | ⚠️ |
| [VertexNormalsHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/vertex_normals_helper.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| [VertexTangentsHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/vertex_tangents_helper.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| [ViewHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/view_helper.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Interactive**</span> |  |  |  |
| HTMLMesh |  | ❌ | ❌ | ❌ |
| [InteractiveGroup](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/other/interactive_group.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| [SelectionBox](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/selection/selection_box.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| [SelectionHelper](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/selection/selection_helper.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Lighting**</span> |  |  |  |
| TiledLighting |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Lights**</span> |  |  |  |
| [LightProbeGenerator](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/lights/light_probe_generator.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| RectAreaLightTexturesLib |  | ⚠️ | ⚠️ | ⚠️ |
| RectAreaLightUniformsLib |  | ⚠️ | ⚠️ | ⚠️ |
|  | <span style="color: #ff00ff;">**Lines**</span> |  |  |  |
| [Line2](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/line2.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
| [LineGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/line_geometry.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
| [LineMaterial](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/line_material.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
| [LineSegments2](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/line_segments2.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
| [LineSegmentsGeometry](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/line_segments_geometry.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
| [Wireframe](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/wireframe.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
| [WireframeGeometry2](https://github.com/Knightro63/three_js/blob/main/packages/three_js_line/lib/wireframe_geometry2.dart) | [three_js_line](https://pub.dev/packages/three_js_line) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Loaders**</span> |  |  |  |
| Rhino3dmLoader |  | ❌ | ❌ | ❌ |
| ThreeMFLoader |  | ❌ | ❌ | ❌ |
| AMFLoader |  | ❌ | ❌ | ❌ |
| [BVHLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/bvh_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| [ColladaLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/collada/collada_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| [DDSLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/dds_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| DRACOLoader |  | ❌ | ❌ | ❌ |
| EXRLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [FBXLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/fbx_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| [FontLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_text/lib/loaders/font_loader.dart) | [three_js_text](https://pub.dev/packages/three_js_text) | ✅ | ✅ | ✅ |
| [GCodeLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/gcode_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| [GLTFLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/gltf/gltf_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| HDRCubeTextureLoader |  | ⚠️ | ⚠️ | ⚠️ |
| IESLoader |  | ⚠️ | ⚠️ | ⚠️ |
| KMZLoader |  | ❌ | ❌ | ❌ |
| KTX2Loader |  | ❌ | ❌ | ❌ |
| [KTXLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/ktx_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| LDrawLoader |  | ⚠️ | ⚠️ | ⚠️ |
| LottieLoader |  | ❌ | ❌ | ❌ |
| LUT3dlLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [LUTCubeLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/lut_cube_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| LUTImageLoader |  | ⚠️ | ⚠️ | ⚠️ |
| LWOLoader |  | ❌ | ❌ | ❌ |
| MaterialXLoader |  | ❌ | ❌ | ❌ |
| [MD2Loader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/md2/md2_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| MDDLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [MTLLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/obj/mtl_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| NRRDLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [OBJLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/obj/obj_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| [PCDLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/pcd_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| PBDLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [PLYLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/ply_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| PVRLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [RGBELoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/rgbe_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| RGBMLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [STLLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/stl_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| [SVGLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_svg/lib/import/svg_loder.dart) | [three_js_svg](https://pub.dev/packages/three_js_svg) | ✅ | ✅ | ✅ |
| TDSLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [TGALoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/tga_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| TIFFLoader |  | ❌ | ❌ | ❌ |
| [TTFLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_text/lib/loaders/ttf_loader.dart) | [three_js_text](https://pub.dev/packages/three_js_text) | ✅ | ✅ | ✅ |
| UltraHDRLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [USDLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/usdz/usdz_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| [USDZLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/usdz/usdz_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| [VOXLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/vox_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
| VRMLoader |  | ❌ | ❌ | ❌ |
| VTKLoader |  | ⚠️ | ⚠️ | ⚠️ |
| [XYZLoader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_simple_loaders/lib/xyz_loder.dart) | [three_js_simple_loaders](https://pub.dev/packages/three_js_simple_loaders) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Materials**</span> |  |  |  |
| LDrawConditionalLineMaterial |  | ❌ | ❌ | ❌ |
| LDrawConditionalLineNodeMaterial |  | ❌ | ❌ | ❌ |
| [MeshGouraudMaterial](https://github.com/Knightro63/three_js/blob/main/packages/three_js_core/lib/materials/mesh_gouraud_loader.dart) | [three_js_core](https://pub.dev/packages/three_js_core) | ✅ | ✅ | ✅ |
| MeshPostProcessingMaterial |  | ⚠️ | ⚠️ | ⚠️ |
|  | <span style="color: #ff00ff;">**Math**</span> |  |  |  |
| [Capsule](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/octree/capsule.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| ColorConverter |  | ⚠️ | ⚠️ | ⚠️ |
| ColorSpaces |  | ⚠️ | ⚠️ | ⚠️ |
| [ConvexHull](https://github.com/Knightro63/three_js/blob/main/packages/three_js_geometry/lib/convex_hull.dart) | [three_js_geometry](https://pub.dev/packages/three_js_geometry) | ✅ | ✅ | ✅ |
| [ImprovedNoise](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/noise/improved_noise.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| Lut |  | ⚠️ | ⚠️ | ⚠️ |
| [MeshSurfaceSampler](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/utils/mesh_surface_sampler.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| OBB |  | ⚠️ | ⚠️ | ⚠️ |
| [Octree](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/octree/octree.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| SimplexNoise |  | ⚠️ | ⚠️ | ⚠️ |
|  | <span style="color: #ff00ff;">**Misc**</span> |  |  |  |
| ConvexObjectBreaker |  | ⚠️ | ⚠️ | ⚠️ |
| GPUComputationRenderer |  | ❌ | ❌ | ❌ |
| [Gyroscope](https://github.com/Knightro63/three_js/blob/main/packages/three_js_particles/lib/gyroscope.dart) | [three_js_particles](https://pub.dev/packages/three_js_particles) | ✅ | ✅ | ✅ |
| [MD2Character](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/md2/md2_charcter.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| [MD2Loader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/md2/md2_loader.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| MD2CharacterComplex |  | ❌ | ❌ | ❌ |
| [MorphAnimMesh](https://github.com/Knightro63/three_js/blob/main/packages/three_js_advanced_loaders/lib/md2/morph_anim_mesh.dart) | [three_js_advanced_loaders](https://pub.dev/packages/three_js_advanced_loaders) | ✅ | ✅ | ✅ |
| MorphBlendMesh |  | ⚠️ | ⚠️ | ⚠️ |
| ProgressiveLightMap |  | ⚠️ | ⚠️ | ⚠️ |
| ProgressiveLightMapGPU |  | ❌ | ❌ | ❌ |
| [RollerCoasterGeometry](https://github.com/Knightro63/three_js/blob/main/examples/lib/rollercoster/rollercoaster.dart) |  | ✅ | ✅ | ✅ |
| [TubePainter](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/tube_painter.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| Volume |  | ⚠️ | ⚠️ | ⚠️ |
| VolumeSlice |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Modifers**</span> |  |  |  |
| CurveModifier |  | ❌ | ❌ | ❌ |
| CurveModifierGPU |  | ❌ | ❌ | ❌ |
| [EdgeSplitModifier](https://github.com/Knightro63/three_js/blob/main/packages/three_js_modifers/lib/edge_split_modifier.dart) | [three_js_modifers](https://pub.dev/packages/three_js_modifers) | ✅ | ✅ | ✅ |
| [SimplifyModifier](https://github.com/Knightro63/three_js/blob/main/packages/three_js_modifers/lib/simplify_modifer.dart) | [three_js_modifers](https://pub.dev/packages/three_js_modifers) | ✅ | ✅ | ✅ |
| [TessellateModifier](https://github.com/Knightro63/three_js/blob/main/packages/three_js_modifers/lib/tesselate_modifer.dart) | [three_js_modifers](https://pub.dev/packages/three_js_modifers) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Objects**</span> |  |  |  |
| GroundedSkybox |  | ⚠️ | ⚠️ | ⚠️ |
| [Lensflare](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/lens_flare.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| LensflareMesh |  | ❌ | ❌ | ❌ |
| [MarchingCubes](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/marching_cubes.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| [Reflector](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/water/reflector.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| ReflectorForSSRPass |  | ⚠️ | ⚠️ | ⚠️ |
| [Refractor](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/water/refractor.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| ShadowMesh |  | ⚠️ | ⚠️ | ⚠️ |
| [Sky](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/sky/sky.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| SkyMesh |  | ❌ | ❌ | ❌ |
| Water |  | ⚠️ | ⚠️ | ⚠️ |
| [Water2](https://github.com/Knightro63/three_js/blob/main/packages/three_js_objects/lib/water/water2.dart) | [three_js_objects](https://pub.dev/packages/three_js_objects) | ✅ | ✅ | ✅ |
| Water2Mesh |  | ❌ | ❌ | ❌ |
| WaterMesh |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Off Screen**</span> |  |  |  |
| Jank |  | ⚠️ | ⚠️ | ⚠️ |
| OffScreen |  | ❌ | ❌ | ❌ |
| Scene |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Physics**</span> |  |  |  |
| AmmoPhysics |  | ❌ | ❌ | ❌ |
| JoltPhysics |  | ❌ | ❌ | ❌ |
| RapierPhysics |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Post Porcessing**</span> |  |  |  |
| [AfterimagePass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/afterimage_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [BloomPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/bloom_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| BokehPass |  | ⚠️ | ⚠️ | ⚠️ |
| ClearPass |  | ⚠️ | ⚠️ | ⚠️ |
| CubeTexturePass |  | ⚠️ | ⚠️ | ⚠️ |
| [DotScreenPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/dot_screen_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [EffectComposer](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/effect_composer.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [FilmPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/film_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [FXAAPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/fxaa_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [GlitchPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/glitch_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| GTAOPass |  | ⚠️ | ⚠️ | ⚠️ |
| HalftonePass |  | ⚠️ | ⚠️ | ⚠️ |
| [LUTPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/lut_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [MaskPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/mask_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| OutlinePass |  | ⚠️ | ⚠️ | ⚠️ |
| [OutputPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/output_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [Pass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [RenderPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/render_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| RenderPixelatedPass |  | ⚠️ | ⚠️ | ⚠️ |
| RenderTransitionPass |  | ⚠️ | ⚠️ | ⚠️ |
| SAOPass |  | ⚠️ | ⚠️ | ⚠️ |
| SavePass |  | ⚠️ | ⚠️ | ⚠️ |
| [ShaderPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/shader_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [SMAAPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/smaa_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [SSAARenderPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/ssaa_render_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| SSAOPass |  | ⚠️ | ⚠️ | ⚠️ |
| SSRPass |  | ⚠️ | ⚠️ | ⚠️ |
| [TAARenderPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/taa_render_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [TexturePass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/texture_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [UnrealBloomPass](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/post/unreal_bloom_pass.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Renderers**</span> |  |  |  |
| CSS2DRenderer |  | ❌ | ❌ | ❌ |
| CSS3DRenderer |  | ❌ | ❌ | ❌ |
| [Projector](https://github.com/Knightro63/three_js/blob/main/packages/three_js_svg/lib/export/projector.dart) | [three_js_svg](https://pub.dev/packages/three_js_svg) | ✅ | ✅ | ✅ |
| [SVGRenderer](https://github.com/Knightro63/three_js/blob/main/packages/three_js_svg/lib/export/svg_renderer.dart) | [three_js_svg](https://pub.dev/packages/three_js_svg) | ✅ | ✅ | ✅ |
|  | <span style="color: #ff00ff;">**Shaders**</span> |  |  |  |
| ACESFilmicToneMappingShader |  | ⚠️ | ⚠️ | ⚠️ |
| [AfterimageShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/afterimage_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| BasicShader |  | ⚠️ | ⚠️ | ⚠️ |
| [BleachBypassShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/bleach_bypass_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| BlendShader |  | ⚠️ | ⚠️ | ⚠️ |
| BokehShader |  | ⚠️ | ⚠️ | ⚠️ |
| BokehShader2 |  | ⚠️ | ⚠️ | ⚠️ |
| BrightnessContrastShader |  | ⚠️ | ⚠️ | ⚠️ |
| ColorCorrectionShader |  | ⚠️ | ⚠️ | ⚠️ |
| ColorifyShader |  | ⚠️ | ⚠️ | ⚠️ |
| [ConvolutionShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/convolution_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [CopyShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/copy_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| DepthLimitedBlurShader |  | ⚠️ | ⚠️ | ⚠️ |
| [DigitalGlitch](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/digital_glitch.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| DOFMipMapShader |  | ⚠️ | ⚠️ | ⚠️ |
| [DotScreenShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/dot_screen_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| ExposureShader |  | ⚠️ | ⚠️ | ⚠️ |
| [FilmShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/film_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| FocusShader |  | ⚠️ | ⚠️ | ⚠️ |
| FreiChenShader |  | ⚠️ | ⚠️ | ⚠️ |
| [FXAAShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/fxaa_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [GammaCorrectionShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/gamma_correction_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| GodRaysDepthMaskShader |  | ⚠️ | ⚠️ | ⚠️ |
| GTAOShader |  | ⚠️ | ⚠️ | ⚠️ |
| HalftoneShader |  | ⚠️ | ⚠️ | ⚠️ |
| [HorizontalBlurShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/horizontal_blur_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| HorizontalTiltShiftShader |  | ⚠️ | ⚠️ | ⚠️ |
| HueSaturationShader |  | ⚠️ | ⚠️ | ⚠️ |
| KaleidoShader |  | ⚠️ | ⚠️ | ⚠️ |
| [LuminosityHighPassShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/luminosity_high_pass_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [LuminosityShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/luminosity_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| MirrorShader |  | ⚠️ | ⚠️ | ⚠️ |
| NormalMapShader |  | ⚠️ | ⚠️ | ⚠️ |
| [OutputShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/outpass_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| PoissonDenoiseShader |  | ⚠️ | ⚠️ | ⚠️ |
| RGBShiftShader |  | ⚠️ | ⚠️ | ⚠️ |
| SAOShader |  | ⚠️ | ⚠️ | ⚠️ |
| SepiaShader |  | ⚠️ | ⚠️ | ⚠️ |
| [SMAAShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/smaa_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| [SobelOperatorShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/sobel_operator_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| SSAOShader |  | ⚠️ | ⚠️ | ⚠️ |
| SSRShader |  | ⚠️ | ⚠️ | ⚠️ |
| SubsurfaceScatteringShader |  | ⚠️ | ⚠️ | ⚠️ |
| TechnicolorShader |  | ⚠️ | ⚠️ | ⚠️ |
| ToonShader |  | ⚠️ | ⚠️ | ⚠️ |
| TriangleBlurShader |  | ⚠️ | ⚠️ | ⚠️ |
| [UnpackDepthRGBAShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/unpack_depth_rgba_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| VelocityShader |  | ⚠️ | ⚠️ | ⚠️ |
| [VerticalBlurShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/vertical_blur_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| VerticalTiltShiftShader |  | ⚠️ | ⚠️ | ⚠️ |
| [VignetteShader](https://github.com/Knightro63/three_js/blob/main/packages/three_js_postprocessing/lib/shaders/vignette_shader.dart) | [three_js_postprocessing](https://pub.dev/packages/three_js_postprocessing) | ✅ | ✅ | ✅ |
| VolumeShader |  | ⚠️ | ⚠️ | ⚠️ |
| WaterRefractionShader |  | ⚠️ | ⚠️ | ⚠️ |
|  | <span style="color: #ff00ff;">**Textures**</span> |  |  |  |
| FlakesTexture |  | ⚠️ | ⚠️ | ⚠️ |
| | <span style="color: #ff00ff;">**Transpiler**</span> | ❌ | ❌ | ❌ |
| | <span style="color: #ff00ff;">**TSL**</span> | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**Utils**</span> |  |  |  |
| [BufferGeometryUtils](https://github.com/Knightro63/three_js/blob/main/packages/three_js_modifers/lib/buffergeometry_utils.dart) | [three_js_modifers](https://pub.dev/packages/three_js_modifers) | ✅ | ✅ | ✅ |
| [CameraUtils](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/utils/camera_utils.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| GeometryCompressionUtils |  | ⚠️ | ⚠️ | ⚠️ |
| GeometryUtils |  | ⚠️ | ⚠️ | ⚠️ |
| LDrawUtils |  | ⚠️ | ⚠️ | ⚠️ |
| SceneOptimizer |  | ⚠️ | ⚠️ | ⚠️ |
| SceneUtils |  | ⚠️ | ⚠️ | ⚠️ |
| ShadowMapViewer |  | ⚠️ | ⚠️ | ⚠️ |
| ShadowMapViewerGPU |  | ❌ | ❌ | ❌ |
| [SkeletonUtils](https://github.com/Knightro63/three_js/blob/main/packages/three_js_helpers/lib/utils/skeleton_utils.dart) | [three_js_helpers](https://pub.dev/packages/three_js_helpers) | ✅ | ✅ | ✅ |
| SortUtils |  | ⚠️ | ⚠️ | ⚠️ |
| UVsDebug |  | ⚠️ | ⚠️ | ⚠️ |
| WebGLTextureUtils |  | ⚠️ | ⚠️ | ⚠️ |
| WebGPUTextureUtils |  | ❌ | ❌ | ❌ |
|  | <span style="color: #ff00ff;">**WebXR**</span> |  |  |  |
| [ARButton](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/buttons/ar_button.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| OculusHandModel |  | ❌ | ❌ | ❌ |
| OculusHandPointerModel |  | ❌ | ❌ | ❌ |
| Text2D |  | ❌ | ❌ | ❌ |
| [VRButton](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/buttons/vr_button.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| [XRButton](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/buttons/xr_button.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| [XRControllerModelFactory](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/models/hand/xr_controller_model_factory.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| XREstimatedLight |  | ❌ | ❌ | ❌ |
| [XRHandMeshModel](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/models/hand/xr_hand_mesh_modle.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| [XRHandModelFactory](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/models/hand/xr_hand_modle_factory.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| [XRHandPrimitiveModel](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/models/hand/xr_hand_primitive_modle.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
| [XRPlanes](https://github.com/Knightro63/three_js/blob/main/packages/three_js_xr/lib/models/xr_planes.dart) | [three_js_xr](https://pub.dev/packages/three_js_xr) | ✅ | ❌ | ❌ |
