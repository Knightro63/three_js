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
 - Minimum os Deployment Target: 10.14
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**iOS**
 - Minimum os Deployment Target: 12.0
 - Xcode 13 or newer
 - Swift 5
 - Metal supported

**iOS-Simulator**
 - Minimum os Deployment Target: 12.0
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
