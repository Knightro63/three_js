import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:three_js_ar/three_js_ar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThreeJsAr threeJsAR = ThreeJsAr();
  final Vector3 _position = Vector3.zero();
  final Vector3 _rotation = Vector3.zero();
  bool isSupported = false;

  @override
  void initState() {
    super.initState();
    threeJsAR.transform().listen((event) {
      setState(() {
        _rotation.copyFromArray(event.matrix.sublist(12));
        _position.copyFromArray(event.matrix.sublist(8));
      });
    });

    threeJsAR.isSupported().then((onValue){
      isSupported = onValue;
      setState(() {
        
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Motion Sensors'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  const Text('isSupported: '),
                  Text('$isSupported'),
                ],
              ),
              const Text('Position'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_position.x.toStringAsFixed(4)),
                  Text(_position.y.toStringAsFixed(4)),
                  Text(_position.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Rotation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_rotation.x).toStringAsFixed(4)),
                  Text(degrees(_rotation.y).toStringAsFixed(4)),
                  Text(degrees(_rotation.z).toStringAsFixed(4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}