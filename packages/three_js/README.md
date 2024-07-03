# three_js

[![Pub Version](https://img.shields.io/pub/v/three_js)](https://pub.dev/packages/three_js)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63//three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A 3D rendering engine for dart (based on [three.js](https://github.com/mrdoob/three.js) and [three_dart](https://github.com/wasabia/three_dart)) that allows users to view, edit and manipulate their 3D objects. The current builds uses [angle](https://github.com/google/angle) for desktop and mobile, and WebGL2 for web applications.

## Features

<picture>
  <img alt="Gif of dash playing a game." src="https://github.com/Knightro63/three_js/blob/main/assets/flutter_game.gif?raw=true">
</picture>

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

**Android**
 - compileSdkVersion: 34
 - OpenGL supported

 **Windows**
 - Intel supported.
 - AMD supported.
 - Direct3D 11 and OpenGL supported

**Web**
 - WebGL2 support.

**Linux**
 - Unsupported

## Getting started

To get started add three_js to your pubspec.yaml file.

## Usage

This project is a simple 3D rendering engine for flutter to view, edit, or manipulate 3D models.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js/example/), for a preview go [here].

## Know Issues

**MacOS**
 - GroupMaterials do not work

**iOS**
 - Buffer Validation issues
 - GroupMaterials do not work
 - Protoplanets does not function correctly

**Android**
 - GroupMaterials do not work

**Windows**
 - GroupMaterials do not work

**Web**
 - Lens Flare not working correctly

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
