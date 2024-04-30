# three_js_text_loaders

[![Pub Version](https://img.shields.io/pub/v/three_js_text_loaders)](https://pub.dev/packages/three_js_text_loaders)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A type of three_js model loader that allows users to add text font files to thier projects.

<!-- <picture>
  <img alt="" src="">
</picture> -->

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

### Getting started

To get started add this to your pubspec.yaml file along with the other portions three_js_math, three_js_core, and three_js_core_loaders.

```dart
    late Scene scene;

    void init() {
        scene = Scene();
        scene.background = Color.fromHex32(0xf0f0f0);
            
        final font = await loadFont();
        createText(font);
    }

    void createText(font) {
        final textGeo = TextGeometry(
            text, 
            TextGeometryOptions(
                font: font,
                size: size,
                depth: fontHeight,
                curveSegments: curveSegments,
                bevelThickness: bevelThickness,
                bevelSize: bevelSize,
                bevelEnabled: bevelEnabled
            )
        );

        final materials = GroupMaterial([
            MeshPhongMaterial.fromMap({"color": 0xffffff, "flatShading": true}),
            MeshPhongMaterial.fromMap({"color": 0xffffff})
        ]);
        
        final textMesh1 = Mesh(textGeo, materials);

        scene.add(textMesh1);
    }

    Future<TYPRFont> loadFont() async {
        final loader = TYPRLoader();
        final font = await loader.fromAsset("assets/pingfang.ttf");
        loader.dispose();

        return font!;
    }
```

## Usage

This project is a text font loader for three_js.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js_text_loaders/example/lib/main.dart).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
