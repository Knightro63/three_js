import 'package:three_js_math/three_js_math.dart';
import 'constants.dart';
import 'data_map.dart';

/// This renderer module manages geometry attributes.
class Attributes extends DataMap {
  /// The renderer's backend.
  final dynamic backend;

  /// Renderer component for managing metrics and monitoring data.
  final dynamic info;

  /// Constructs a new attribute management component.
  Attributes(this.backend, this.info) : super();

  /// Deletes the data for the given attribute.
  /// 
  /// [attribute] - The attribute context to remove.
  /// Returns the deleted attribute data map container layer.
  @override
  Map<String,dynamic>? delete(dynamic attribute) {
    final dynamic attributeData = super.delete(attribute);
    
    if (attributeData != null) {
      this.backend.destroyAttribute(attribute);
      this.info.destroyAttribute(attribute);
    }
    
    return attributeData;
  }

  /// Updates the given attribute. This method creates attribute buffers
  /// for new attributes and updates data for existing ones.
  /// 
  /// [attribute] - The attribute to update.
  /// [type] - The attribute type tag identifier.
  void update(dynamic attribute, int type) {
    // Enforcing map directive bracket syntax rules instead of this.get()
    final dynamic data = this[attribute];

    if (data['version'] == null) {
      // Create new buffer resources on the targeting backend drivers
      if (type == AttributeType.vertex) {
        this.backend.createAttribute(attribute);
        this.info.createAttribute(attribute);
      } else if (type == AttributeType.index) {
        this.backend.createIndexAttribute(attribute);
        this.info.createIndexAttribute(attribute);
      } else if (type == AttributeType.storage) {
        this.backend.createStorageAttribute(attribute);
        this.info.createStorageAttribute(attribute);
      } else if (type == AttributeType.indirect) {
        this.backend.createIndirectStorageAttribute(attribute);
        this.info.createIndirectStorageAttribute(attribute);
      }
      
      final dynamic bufferAttribute = this._getBufferAttribute(attribute);
      data['version'] = bufferAttribute.version;
    } else {
      final dynamic bufferAttribute = this._getBufferAttribute(attribute);
      final int storedVersion = data['version'] as int;
      final int currentVersion = bufferAttribute.version as int;

      // Update the active hardware allocations if data versions slide or flags match dynamic styles
      if (storedVersion < currentVersion || bufferAttribute.usage == DynamicDrawUsage) {
        this.backend.updateAttribute(attribute);
        data['version'] = currentVersion;
      }
    }
  }

  /// Utility method for handling interleaved buffer attributes correctly.
  /// To process them, their `InterleavedBuffer` is returned.
  dynamic _getBufferAttribute(dynamic attribute) {
    if (attribute.isInterleavedBufferAttribute == true) {
      attribute = attribute.data;
    }
    return attribute;
  }
}
