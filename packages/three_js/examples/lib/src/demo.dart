import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class Demo extends StatefulWidget {
  final String fileName;
  const Demo({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<Demo> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  Future<void> setup() async {

  }
}
