# three_js_video_texture

[![Pub Version](https://img.shields.io/pub/v/three_js_video_texture)](https://pub.dev/packages/three_js_video_texture)
[![analysis](https://github.com/Knightro63/three_js/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/three_js/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A type of three_js texture loader that allows users to add video files to thier projects.

This is a dart conversion of three.js and three_dart, originally created by [@mrdoob](https://github.com/mrdoob) and has a coverted dart fork by [@wasabia](https://github.com/wasabia).

### Getting started

To get started add this to your pubspec.yaml file along with the other portions three_js_math, and three_js_core.

## Usage

To get started add three_js_video_texture to your pubspec.yaml file. Adding permissions for audio and video is required if using either item.
Please use [Permission Handler](https://pub.dev/packages/permission_handler) package to help with this.

**Android**
 - Add the following to your AndroidManifest.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.example.app">
    <application
      ...
      />
    </application>
    <!-- Internet access permissions. If using web assets -->
    <uses-permission android:name="android.permission.INTERNET" />
    <!--
      Media access permissions.
      Android 13 or higher.
      https://developer.android.com/about/versions/13/behavior-changes-13#granular-media-permissions
      -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <!--
      Storage access permissions.
      Android 12 or lower.
      -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
</manifest>
```

**MacOS and iOS**
 - Please add some permissions to have this work. User Selected File "Read/Write"
 - If using web assets please add: Incoming Connections (Server)

**Linux**
 - The folling is required for audio and video `sudo apt install libmpv-dev mpv`

## Example

Find the example for this API [here](https://github.com/Knightro63/three_js/tree/main/packages/three_js_video_texture/example/lib/main.dart).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/three_js/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/three_js/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/three_js/pulls) directly.
