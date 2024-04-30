# three_js_exporters

[![Pub Version](https://img.shields.io/pub/v/three_js_exporters)](https://pub.dev/packages/three_js_exporters)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A type of three_js model exporter that allows users to export either obj, ply, or stl files from thier projects.

<!-- <picture>
  <img alt="" src="">
</picture> -->

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

### Getting started

To get started add this to your pubspec.yaml file along with the other portions three_js_math, and three_js_core.

```dart
    void init() {
        String? contents = OBJExporter().parseMesh(mesh);
    }
```

## Usage

This project is a model exporter for three_js.

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
