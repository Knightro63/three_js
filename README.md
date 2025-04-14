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
 - No longer supported due to IOSurface issue, please use override to flutter_angle: ^0.1.0 for testing on simulator.

**Android**
 - compileSdkVersion: 34
 - OpenGL supported
 - Vulkan supported

 **Windows**
 - Intel supported.
 - AMD supported.
 - Direct3D 11 and OpenGL supported

**Web**
 - WebGL2 supported

**WASM**
 - Currently not supported due to WebGL2RenderingContext conversion issue.

**Linux**
 - Unsupported

## Getting started

To get started add three_js to your pubspec.yaml file.

## Usage

This project is a simple 3D rendering engine for flutter to view, edit, or manipulate 3D models.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js/example/), for more examples you can click [here](https://github.com/Knightro63/three_js/tree/main/examples/), and for a preview go [here](https://knightro63.github.io/three_js/).

## Know Issues

**All**
 - MD2 annimations do not work
 - Collada animations do not work
 - Collada kinnametics does not work
 - PMREM gives weird artifacts

**MacOS**
 - Audio has a [bug](https://github.com/bluefireteam/audioplayers/issues/1296)

**iOS**
 - Protoplanets does not function correctly

**Android**
 - Morphtargets dones not work
 - Some RGBELoaders cause app to crash
 
**Windows**

**Web**
 - Lens Flare not working correctly
 - Postprocessing does not work
 - Track pad has some bugs

## Librarues and Plugins

**ADD-ONS**
 - [Omio](https://github.com/Knightro63/oimo_physics) a physics engine for three_js
 - [Cannon](https://github.com/Knightro63/cannon_physics) a physics engine for three_js
 - [Terrain](https://github.com/Knightro63/three_js/tree/main/packages/three_js_terrain) a map generator for three_js

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
