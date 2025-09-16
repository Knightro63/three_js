import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThreeJsArCameraView extends StatelessWidget {
  const ThreeJsArCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    // This string "ar_camera_view" must match the identifier registered in AppDelegate.swift
    return const UiKitView(viewType: 'three_js_ar/cameraView');
  }
}

class ThreeJsAr {
  final MethodChannel _methodChannel = MethodChannel('three_js_ar/method');
  final EventChannel _arManagerEventChannel = EventChannel('three_js_ar/armanager');
  int? textureId;

  Stream<ARTransformData>? _arManagerEvent;

  Future<int> createTexture() async {
    textureId = (await _methodChannel.invokeMethod('createTexture'))['textureId'];
    return textureId!;
  }

  Future<void> updateTexture() async {
    await _methodChannel.invokeMethod('textureFrameAvailable');
  }

  Future<List<double>?> hitTest(double x, double y) async {
    return await _methodChannel.invokeMethod('handleTap',  {"x": x, "y": y});
  }

  /// Determines whether sensor is available.
  Future<bool> isSupported() async {
    final available = await _methodChannel.invokeMethod('isSupported');
    return available;
  }

  /// A broadcast stream of events from the device accelerometer.
  Stream<ARTransformData> transform() {
    _arManagerEvent ??= _arManagerEventChannel.receiveBroadcastStream().map((dynamic event) => ARTransformData(event.cast<double>()));
    return _arManagerEvent!;
  }
}

class ARTransformData {
  ARTransformData(this.matrix);
  final List<double> matrix;
  @override
  String toString() => '[ThreeJsArEvent ($matrix)]';
}