# three_js_svg

[![Pub Version](https://img.shields.io/pub/v/three_js_svg)](https://pub.dev/packages/three_js_svg)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A type of three_js svg loader and exporter that allows users to add or export svgs to and from thier projects.

<picture>
  <img alt="Picture of a tiger svg." src="https://raw.githubusercontent.com/Knightro63/three_js/master/packages/three_js_svg/assets/example.jpg">
</picture>

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

### Getting started

To get started add this to your pubspec.yaml file along with the other portions three_js_math, three_js_core, and three_js_core_loaders.

```dart
    late Scene scene;

    void init() {
        scene = Scene();
        scene.background = Color.fromHex32(0xf0f0f0);
            
        final loader = SVGLoader();
        final data = await loader.fromAsset('assets/${fileName}.svg');

        List<ShapePath> paths = data!.paths;

        Group group = Group();
        group.scale.scale(0.25);
        group.position.x = -25;
        group.position.y = 25;
        group.rotateZ(math.pi);
        group.rotateY(math.pi);
        //group.scale.y *= -1;

        for (int i = 0; i < paths.length; i++) {
          ShapePath path = paths[i];

          final fillColor = path.userData?["style"]["fill"];
          if (guiData["drawFillShapes"] == true && fillColor != null && fillColor != 'none') {
            MeshBasicMaterial material = MeshBasicMaterial.fromMap({
              "color":tmath.Color().setStyle(fillColor).convertSRGBToLinear(),
              "opacity": path.userData?["style"]["fillOpacity"].toDouble(),
              "transparent": true,
              "side": tmath.DoubleSide,
              "depthWrite": false,
              "wireframe": guiData["fillShapesWireframe"]
            });

            final shapes = SVGLoader.createShapes(path);

            for (int j = 0; j < shapes.length; j++) {
              final shape = shapes[j];

              ShapeGeometry geometry = ShapeGeometry([shape]);
              Mesh mesh = Mesh(geometry, material);

              group.add(mesh);
            }
          }

          final strokeColor = path.userData?["style"]["stroke"];

          if (guiData["drawStrokes"] == true &&
              strokeColor != null &&
              strokeColor != 'none') {
            three.MeshBasicMaterial material = three.MeshBasicMaterial.fromMap({
              "color":tmath.Color().setStyle(strokeColor).convertSRGBToLinear(),
              "opacity": path.userData?["style"]["strokeOpacity"].toDouble(),
              "transparent": true,
              "side": tmath.DoubleSide,
              "depthWrite": false,
              "wireframe": guiData["strokesWireframe"]
            });

            for (int j = 0, jl = path.subPaths.length; j < jl; j++) {
              Path subPath = path.subPaths[j];
              final geometry = SVGLoader.pointsToStroke(subPath.getPoints(), path.userData?["style"]);

              if (geometry != null) {
                final mesh = three.Mesh(geometry, material);

                group.add(mesh);
              }
            }
          }
        }

        scene.add(group);
    }
```

## Usage

This project is a svg model loader and exporter for three_js.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js_svg/example/lib/main.dart).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
