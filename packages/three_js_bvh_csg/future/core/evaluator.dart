import 'dart:math' as math;
import "package:three_js_bvh_csg/core/brush.dart";
import "package:three_js_math/three_js_math.dart";
// import "brush.dart";
import "operations/operations.dart";
import "debug/operation_debug_data.dart";
import "typed_attribute_data.dart";
import "triangle_splitter.dart";

// Merges groups with common material indices in place
void joinGroups(List groups) {
  for (int i = 0; i < groups.length - 1; i++) {
    var group = groups[i];
    var nextGroup = groups[i + 1];
    if (group['materialIndex'] == nextGroup['materialIndex']) {
      var start = group['start'];
      var end = nextGroup['start'] + nextGroup['count'];
      nextGroup['start'] = start;
      nextGroup['count'] = end - start;
      // groups.splice( i,1 );
      groups.removeAt(i);
      i--;
    }
  }
}

// Initialize the target geometry and attribute data based on
// the given reference geometry
void prepareAttributesData(referenceGeometry, targetGeometry, attributeData, List<String> relevantAttributes) {
  attributeData.clear();

  // initialize and clear unused data fro the attribute buffers and vice versa
  var aAttributes = referenceGeometry.attributes;
  for (int i = 0, l = relevantAttributes.length; i < l; i++) {
    var key = relevantAttributes[i];
    var aAttr = aAttributes[key];
    attributeData.initializeArray(key, aAttr.array.runtimeType, aAttr.itemSize, aAttr.normalized);
  }
  for (var key in attributeData.attributes.keys) {
    if (!relevantAttributes.contains(key)) {
      attributeData.delete(key);
    }
  }
  for (var key in targetGeometry.attributes.keys) {
    if (!relevantAttributes.contains(key)) {
      targetGeometry.deleteAttribute(key);
      targetGeometry.dispose();
    }
  }
}

class ForBuffer extends BufferAttribute {
  ForBuffer(super.arrayList, super.itemSize, super.normalized);
}

// Assigns the given tracked attribute data to the geometry and returns whether the
// geometry needs to be disposed of
void assignBufferData(geometry, attributeData, groupOrder) {
  bool needsDisposal = false;
  int drawRange = -1;

  // set the data
  var attributes = geometry.attributes;
  var referenceAttrSet = attributeData.groupAttributes[0];
  for (var key in referenceAttrSet.keys) {
    var requiredLength = attributeData.getTotalLength(key);
    var type = attributeData.getType(key);
    var itemSize = attributeData.getItemSize(key);
    var normalized = attributeData.getNormalized(key);
    var geoAttr = attributes[key];
    if (!geoAttr || geoAttr.array.length < requiredLength) {
      // create the attribute if it doesn't exist yet
      //geoAttr = BufferAttribute(type(requiredLength), itemSize, normalized);
      BufferAttribute bufAssign = ForBuffer(type(requiredLength), itemSize, normalized);
      geoAttr = bufAssign;
      geometry.setAttribute(key, geoAttr);
      needsDisposal = true;
    }

    // assign the data to the geometry attribute buffers in the provided order
    // of the groups list
    num offset = 0;
    for (int i = 0, l = math.min(groupOrder.length, attributeData.groupCount); i < l; i++) {
      var index = groupOrder[i].index;
      var groupAttr = attributeData.groupAttributes[index][key];
      var trimmedArray = groupAttr.type(groupAttr.array.buffer, 0, groupAttr.length);
      geoAttr.array.set(trimmedArray, offset);
      offset += trimmedArray.length;
    }

    geoAttr.needsUpdate = true;
    drawRange = requiredLength / geoAttr.itemSize;
  }

  // remove or update the index appropriately
  if (geometry.index != null) {
    var indexArray = geometry.index.array;
    if (indexArray.length < drawRange) {
      geometry.index = null;
      needsDisposal = true;
    } else {
      for (int i = 0, l = indexArray.length; i < l; i++) {
        indexArray[i] = i;
      }
    }
  }

  // initialize the groups
  int groupOffset = 0;
  geometry.clearGroups();
  for (int i = 0, l = math.min(groupOrder.length, attributeData.groupCount); i < l; i++) {
    var index = groupOrder[i];
    var materialIndex = groupOrder[i];
    int vertCount = attributeData.getCount(index);
    if (vertCount != 0) {
      geometry.addGroup(groupOffset, vertCount, materialIndex);
      groupOffset += vertCount;
    }
  }

  // update the draw range
  geometry.setDrawRange(0, drawRange);

  // remove the bounds tree if it exists because its now out of date
  geometry.boundsTree = null;

  if (needsDisposal) {
    geometry.dispose();
  }

  // return needsDisposal;
}

// Returns the list of materials used for the given set of groups
List getMaterialList(List groups, materials) {
  var result = materials;
  if (materials is! List) {
    result = [];
    for (var g in groups) {
      result[g.materialIndex] = materials;
    }
  }
  return result;
}

// Utility class for performing CSG operations
class Evaluator {
  TriangleSplitter triangleSplitter = TriangleSplitter();
  List<TypedAttributeData> attributeData = [];
  List<String> attributes = ['position', 'uv', 'normal'];
  bool useGroups = true;
  bool consolidateGroups = true;
  OperationDebugData debug = OperationDebugData();

  List<Map<String, dynamic>> getGroupRanges(geometry) {
    return !useGroups || geometry.groups.length == 0
        ? [
            {'start': 0, 'count': double.infinity.toInt(), 'materialIndex': 0}
          ]
        : geometry.groups.map((group) => Map<String, dynamic>.from(group)).toList();
  }

  dynamic evaluate(a, b, operations, [targetBrushes = Brush]) {
    bool wasArray = true;
    if (operations is! List) {
      operations = [operations];
    }

    if (targetBrushes is! List) {
      targetBrushes = [targetBrushes];
      wasArray = false;
    }

    if (targetBrushes.length != operations.length) {
      throw Exception('Evaluator: operations and target array passed as different sizes.');
    }

    a.prepareGeometry();
    b.prepareGeometry();

    var triangleSplitter = this.triangleSplitter;
    var attributeData = this.attributeData;
    var attributes = this.attributes;
    var useGroups = this.useGroups;
    var consolidateGroups = this.consolidateGroups;
    var debug = this.debug;

    // expand the attribute data array to the necessary size
    while (attributeData.length < targetBrushes.length) {
      attributeData.add(TypedAttributeData());
    }

    // prepare the attribute data buffer information
    for (int i = 0; i < targetBrushes.length; i++) {
      var brush = targetBrushes[i];
      prepareAttributesData(a.geometry, brush.geometry, attributeData[i], attributes);
    }

    // run the operation to fill the list of attribute data
    debug.init();
    performOperation(a, b, operations, triangleSplitter, attributeData, {'useGroups': useGroups});
    debug.complete();

    // get the materials and group ranges
    var aGroups = getGroupRanges(a.geometry);
    var aMaterials = getMaterialList(aGroups, a.material);

    var bGroups = getGroupRanges(b.geometry);
    var bMaterials = getMaterialList(bGroups, b.material);
    for (var g in bGroups) {
      g['materialIndex'] += aMaterials.length;
    }

    var groups = [...aGroups, ...bGroups].map((group) => Map<String, dynamic>.from(group)).toList();

    // generate the minimum set of materials needs for the list of groups and adjust the groups
    // if they're needed
    if (useGroups) {
      var allMaterials = [...aMaterials, ...bMaterials];
      if (consolidateGroups) {
        groups = groups.map((group) {
          var mat = allMaterials[group['materialIndex']];
          group['materialIndex'] = allMaterials.indexOf(mat);
          return group;
        }).toList()
          ..sort((a, b) => a['materialIndex'] - b['materialIndex']);
      }

      // create a map from old to new index and remove materials that aren't used
      var finalMaterials = [];
      for (int i = 0, l = allMaterials.length; i < l; i++) {
        bool foundGroup = false;
        for (int g = 0, lg = groups.length; g < lg; g++) {
          var group = groups[g];
          if (group['materialIndex'] == i) {
            foundGroup = true;
            group['materialIndex'] = finalMaterials.length;
          }
        }
        if (foundGroup) {
          finalMaterials.add(allMaterials[i]);
        }
      }

      for (var tb in targetBrushes) {
        tb.material = finalMaterials;
      }
    } else {
      groups = [
        {'start': 0, 'count': double.infinity.toInt(), 'index': 0, 'materialIndex': 0}
      ];
      for (var tb in targetBrushes) {
        tb.material = aMaterials[0];
      }
    }

    // apply groups and attribute data to the geometry
    for (int i = 0; i < targetBrushes.length; i++) {
      var brush = targetBrushes[i];
      var targetGeometry = brush.geometry;
      assignBufferData(targetGeometry, attributeData[i], groups);
      if (consolidateGroups) {
        joinGroups(targetGeometry.groups);
      }
    }

    return wasArray ? targetBrushes : targetBrushes[0];
  }

  // TODO: fix
  Brush evaluateHierarchy(root, [target = Brush]) {
    root.updateMatrixWorld(true);

    void flatTraverse(obj, cb) {
      var children = obj.children;
      for (int i = 0, l = children.length; i < l; i++) {
        var child = children[i];
        if (child.isOperationGroup) {
          flatTraverse(child, cb);
        } else {
          cb(child);
        }
      }
    }

    bool traverse(brush) {
      var children = brush.children;
      bool didChange = false;
      for (int i = 0, l = children.length; i < l; i++) {
        var child = children[i];
        didChange = traverse(child) || didChange;
      }

      bool isDirty = brush.isDirty();
      if (isDirty) {
        brush.markUpdated();
      }

      if (didChange && !brush.isOperationGroup) {
        var result;
        flatTraverse(brush, (child) {
          if (result == null) {
            result = evaluate(brush, child, child.operation);
          } else {
            result = evaluate(result, child, child.operation);
          }
        });

        brush._cachedGeometry = result.geometry;
        brush._cachedMaterials = result.material;
        return true;
      } else {
        return didChange || isDirty;
      }
    }

    traverse(root);

    target.geometry = root._cachedGeometry;
    target.material = root._cachedMaterials;

    return target;
  }

  void reset() {
    triangleSplitter.reset();
  }
}
