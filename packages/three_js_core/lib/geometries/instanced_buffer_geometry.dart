import 'buffer_geometry.dart';
import '../core/object_3d.dart';

class InstancedBufferGeometry extends BufferGeometry {
  InstancedBufferGeometry() : super() {
    type = 'InstancedBufferGeometry';
    instanceCount = double.infinity.toInt();
  }

  @override
  InstancedBufferGeometry copy(BufferGeometry source) {
    super.copy(source);
    instanceCount = source.instanceCount;
    return this;
  }

  @override
  BufferGeometry clone() {
    return InstancedBufferGeometry().copy(this);
  }

  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    final data = super.toJson(meta: meta);
    data['instanceCount'] = instanceCount;
    data['isInstancedBufferGeometry'] = true;
    return data;
  }
}
