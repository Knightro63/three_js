import 'interleaved_buffer.dart';

/// An instanced version of [InterleavedBuffer].
class InstancedInterleavedBuffer extends InterleavedBuffer {
  bool isInstancedInterleavedBuffer = true;
  
  InstancedInterleavedBuffer(super.array, super.stride, meshPerAttribute){
    this.meshPerAttribute = meshPerAttribute ?? 1;
    type = "InstancedInterleavedBuffer";
  }

  @override
  InstancedInterleavedBuffer copy(InterleavedBuffer source) {
    super.copy(source);
    if (source is InstancedInterleavedBuffer) {
      meshPerAttribute = source.meshPerAttribute;
    }
    return this;
  }

  @override
  InstancedInterleavedBuffer clone([Map<String, dynamic>? data]) {
    //if(data is InterleavedBuffer) throw('data must be InstancedInterleavedBuffer'); 
    final ib = super.clone(data);
    ib.meshPerAttribute = meshPerAttribute;
    return ib as InstancedInterleavedBuffer;
  }

  @override
  Map<String,dynamic> toJson(data) {
    final json = super.toJson(data);

    json["isInstancedInterleavedBuffer"] = true;
    json["meshPerAttributes"] = meshPerAttribute;

    return json;
  }
}
