import 'base_buffer_attribute.dart';

/// This buffer attribute class does not construct a VBO. Instead, it uses
/// whatever VBO is passed in constructor and can later be altered via the
/// `buffer` property.
/// 
/// It is required to pass additional params alongside the VBO. Those are: the
/// GL context, the GL data type, the number of components per vertex, the
/// number of bytes per component, and the number of vertices.
/// 
/// The most common use case for this class is when some kind of GPGPU
/// calculation interferes or even produces the VBOs in question.
class GLBufferAttribute extends BaseBufferAttribute {

  /// [buffer] — Must be a
  /// [WebGLBuffer](https://developer.mozilla.org/en-US/docs/Web/API/WebGLBuffer).
  ///
  /// [type] — One of
  /// [ WebGL Data Types](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/Constants#Data_types).
  ///
  /// [itemSize] — The number of values of the array that should be associated
  /// with a particular vertex. For instance, if this attribute is storing a
  /// 3-component vector (such as a position, normal, or color), then itemSize
  /// should be 3.
  ///
  /// [elementSize] — 1, 2 or 4. The corresponding size (in bytes) for the given
  /// "type" param.
  GLBufferAttribute(
      int buffer, String type, int itemSize, int elementSize, int count)
      : super() {
    this.buffer = buffer;
    this.type = type;
    this.itemSize = itemSize;
    this.elementSize = elementSize;
    this.count = count;

    version = 0;
  }

  set needsUpdate(bool value) {
    if (value == true) version++;
  }

  /// Sets the [buffer] property.
  GLBufferAttribute setBuffer(int buffer) {
    this.buffer = buffer;

    return this;
  }

  /// Sets the both [type] and [elementSize] properties.
  GLBufferAttribute setType(String type, int elementSize) {
    this.type = type;
    this.elementSize = elementSize;

    return this;
  }

  /// Sets the [itemSize] property.
  GLBufferAttribute setItemSize(int itemSize) {
    this.itemSize = itemSize;

    return this;
  }

  /// Sets the [count] property.
  GLBufferAttribute setCount(int count) {
    this.count = count;

    return this;
  }
}
