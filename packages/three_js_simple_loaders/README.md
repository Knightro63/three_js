# three_js_simple_loaders

[![Pub Version](https://img.shields.io/pub/v/three_js_simple_loaders)](https://pub.dev/packages/three_js_simple_loaders)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A type of three_js model loader that allows users to add stl, obj, or lut files to thier projects.

<picture>
  <img alt="Picture of a obj loaded model with mtl." src="https://raw.githubusercontent.com/Knightro63/three_js/master/packages/three_js_simple_loaders/assets/example.jpg">
</picture>

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

### Getting started

To get started add this to your pubspec.yaml file along with the other portions three_js_math, three_js_core, and three_js_core_loaders.

```dart
    late Scene scene;

    void init() {
        scene = Scene();
        scene.background = Color.fromHex32(0xf0f0f0);
            
        final loader = OBJLoader();
        final obj = await loader.fromAsset('assets/${fileName}.obj');
        scene.add(obj);
        loader.dispose();
    }
```

## Usage

This project is a simple model loader for three_js.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js_simple_loaders/example/lib/main.dart).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
