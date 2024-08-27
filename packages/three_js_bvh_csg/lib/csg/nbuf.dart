import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';

class NBuf3 {
  int top = 0;
  late Float32List array;

  NBuf3(int ct) {
    array = Float32List(ct);
  }

  void write(Vector3 v) {
    array[top++] = v.x;
    array[top++] = v.y;
    array[top++] = v.z;
  }
}

class NBuf2 {
  int top = 0;
  late Float32List array;

  NBuf2(int ct) {
    array = Float32List(ct);
  }

  void write(Vector v){
    array[top++] = v.x;
    array[top++] = v.y;
  }
}