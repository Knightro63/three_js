import 'package:flutter_gl/flutter_gl.dart';
import '../others/constants.dart';
import 'interleaved_buffer.dart';

abstract class BaseBufferAttribute<TData extends NativeArray> {
  late TData array;
  late int itemSize;

  InterleavedBuffer? data;

  late String type;

  String? name;

  int count = 0;
  bool normalized = false;
  int usage = StaticDrawUsage;
  int version = 0;
  Map<String, int>? updateRange;

  void Function()? onUploadCallback;

  int? buffer;
  int? elementSize;

  BaseBufferAttribute();
}
