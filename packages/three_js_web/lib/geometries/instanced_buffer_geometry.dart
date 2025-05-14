@JS('THREE')
import 'buffer_geometry.dart';
import '../core/object_3d.dart';
import 'dart:js_interop';

@JS('InstancedBufferGeometry')
class InstancedBufferGeometry extends BufferGeometry {
  external InstancedBufferGeometry();

  @override
  external InstancedBufferGeometry copy(BufferGeometry source);
  @override
  external BufferGeometry clone();

  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    return toJSON(meta?.toJson());
  }

  external Map<String, dynamic> toJSON(Map? meta);
}
