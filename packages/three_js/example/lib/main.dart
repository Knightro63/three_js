import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart';
import 'app/example_app.dart';

void main() {
  Cache.enabled = true;
  Console.isVerbose = true;
  runApp(const ExampleApp());
}
