import 'dart:async';
import 'dart:math';
import 'package:example/loaders/webgl_loader_gltf.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';

class MemoryLeakHunting extends StatefulWidget {
  const MemoryLeakHunting({super.key});
  @override
  createState() => _State();
}

class _State extends State<MemoryLeakHunting> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  bool isOn = false;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(Random().nextInt(60)+20);
      });
    });
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          isOn?WebglLoaderGltf():Statistics(data: data),
          
        ],
      ),
      floatingActionButton: InkWell(
        onTap: () async{
          setState(() {
            isOn = !isOn;
          });
          if(!isOn){
            await Future.delayed(Duration(seconds: 3),(){setState(() {});});
          }
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(10)
          ),
          child: Icon(isOn?Icons.open_in_new:Icons.open_in_new_off),
        )
      ),
    );
  }

  Future<void> setup() async {

  }
}
