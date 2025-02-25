import 'type_backed_array.dart';
// import "dart:typed_data";
// import "package:three_js_core/three_js_core.dart";
// import "package:three_js_math/three_js_math.dart";
// import 'dart:math' as math;

// Utility class for tracking attribute data in type-backed arrays for a set
// of groups. The set of attributes is kept for each group and are expected to be the
// same buffer type.
class TypedAttributeData {
  var groupAttributes = [{}];
  int groupCount = 0;

  TypedAttributeData() {
    groupAttributes = [{}];
    groupCount = 0;
  }

  // returns the buffer type for the given attribute
  Type? getType(String name) {
    return groupAttributes[0][name]?.type;
  }

  int getItemSize(String name) {
    return groupAttributes[0][name].itemSize;
  }

  bool getNormalized(String name) {
    return groupAttributes[0][name].normalized;
  }

  int getCount(int index) {
    if (groupCount <= index) {
      return 0;
    }

    final pos = getGroupAttrArray('position', index);
    return pos.length ~/ pos.itemSize;
  }

  // returns the total length required for all groups for the given attribute
  int getTotalLength(String name) {
    int length = 0;

    for (int i = 0; i < groupCount; i++) {
      var attrSet = groupAttributes[i];
      int lengthOne = attrSet[name].length;
      length += lengthOne;
    }

    return length;
  }

  getGroupAttrSet([index = 0]) {
    // Return the exiting group set if necessary
    if (groupAttributes[index] == true) {
      // equivalent JS function: Math.max( this.groupCount, index + 1 );
      groupCount = groupCount > index + 1 ? groupCount : index + 1;
      return groupAttributes[index];
    }

    // add any new group sets required
    var refAttrSet = groupAttributes[0];
    groupCount = groupCount > index + 1 ? groupCount : index + 1;

    while (index >= groupAttributes.length) {
      var newAttrSet = {};
      groupAttributes.add(newAttrSet);

      refAttrSet.forEach((key, refAttrSet) {
        var refAttr = refAttrSet[key];
        var newAttr = TypeBackedArray(refAttr.type);
        newAttr.itemSize = refAttr.itemSize;
        newAttr.normalized = refAttr.normalized;
        newAttrSet[key] = newAttr;
      });
    }

    return groupAttributes[index];
  }

  // Get the raw array for the group set of data
  getGroupAttrArray(name, [index = 0]) {
    // throw an error if we've never
    var referenceAttrSet = groupAttributes[0];
    var referenceAttr = referenceAttrSet[name];
    if (referenceAttr == null) {
      throw Exception('TypedAttributeData: Attribute with "$name" has not been initialized');
    }

    return getGroupAttrSet(index)[name];
  }

  // initializes an attribute array with the given name, type, and size
  initializeArray(String name, Type type, int itemSize, bool normalized) {
    var referenceAttrSet = groupAttributes[0];
    var referenceAttr = referenceAttrSet[name];
    if (referenceAttr != null) {
      if (referenceAttr.type != type) {
        for (int i = 0, l = groupAttributes.length; i < l; i++) {
          var arr = groupAttributes[i][name];

          if (arr != null) {
            arr.setType(type);
            arr.itemSize = itemSize;
            arr.normalized = normalized;
          }
        }
      }
    } else {
      for (int i = 0, l = groupAttributes.length; i < l; i++) {
        var arr = TypeBackedArray(type);
        arr.itemSize = itemSize;
        arr.normalized = normalized;
        groupAttributes[i][name] = arr;
      }
    }
  }

  // Clear all the data
  void clear() {
    groupCount = 0;
    for (var attrSet in groupAttributes) {
      attrSet.forEach((key, attr) {
        attr.clear();
      });
    }
  }

  // Remove the given key
  void delete(String key) {
    for (var attrSet in groupAttributes) {
      attrSet.remove(key);
    }
  }

  // Reset the datasets completely
  void reset() {
    groupAttributes = [];
    groupCount = 0;
  }
}
