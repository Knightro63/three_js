# three_js_transform_controls

[![Pub Version](https://img.shields.io/pub/v/three_js_transform_controls)](https://pub.dev/packages/three_js_transform_controls)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A type of three_js camera controller that allows users to add either arcball or transform controller to thier projects.

<!-- <picture>
  <img alt="" src="">
</picture> -->

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

### Getting started

To get started add this to your pubspec.yaml file along with the other portions three_js_math, three_js_core, and a three_js_(loder type).

```dart
    late ArcballControls controls;

    void initControls() {
        controls = ArcballControls(camera, _globalKey, scene, 1);
        controls.addEventListener('change', (event) {
            render();
        });
    }

    void update() {
        controls.update();
    }
```

## Usage

This project is a simple camera controller for three_js.

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js_transform_controls/example/lib/main.dart).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
