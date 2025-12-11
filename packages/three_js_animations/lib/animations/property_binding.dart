import 'package:three_js_core/three_js_core.dart';
import 'animation_object_group.dart';

// Characters [].:/ are reserved for track binding syntax.
const _reservedCharsRe = '\\[\\]\\.:\\/';
final _reservedRe = RegExp("[$_reservedCharsRe]");

// Attempts to allow node names from any language. ES5's `\w` regexp matches
// only latin characters, and the unicode \p{L} is not yet supported. So
// instead, we exclude reserved characters and match everything else.
const _wordChar = '[^$_reservedCharsRe]';
final _wordCharOrDot = '[^${_reservedCharsRe.replaceAll('\\.', '')}]';

// Parent directories, delimited by '/' or ':'. Currently unused, but must
// be matched to parse the rest of the track name.
final _directoryRe =
    RegExp(r"((?:WC+[\/:])*)").pattern.replaceAll('WC', _wordChar);

// Target node. May contain word characters (a-zA-Z0-9_) and '.' or '-'.
final _nodeRe = RegExp(r"(WCOD+)?").pattern.replaceAll('WCOD', _wordCharOrDot);

// Object on target node, and accessor. May not contain reserved
// characters. Accessor may contain any character except closing bracket.
final _objectRe =
    RegExp(r"(?:\.(WC+)(?:\[(.+)\])?)?").pattern.replaceAll('WC', _wordChar);

// Property and accessor. May not contain reserved characters. Accessor may
// contain any non-bracket characters.
final _propertyRe =
    RegExp(r"\.(WC+)(?:\[(.+)\])?").pattern.replaceAll('WC', _wordChar);

final _ts = "^$_directoryRe$_nodeRe$_objectRe$_propertyRe\$";
final _trackRe = RegExp(_ts);

final _supportedObjectNames = ['material', 'materials', 'bones'];

class AnimationBinding{

  void bind() {}
  void unbind(){}
}

class Composite extends AnimationBinding{
  late AnimationObjectGroup _targetGroup;
  late List<PropertyBinding?> _bindings;

  Composite(AnimationObjectGroup targetGroup, String path, Map<String, dynamic>? optionalParsedPath) {
    final parsedPath = optionalParsedPath ?? PropertyBinding.parseTrackName(path);

    _targetGroup = targetGroup;
    _bindings = targetGroup.subscribe_(path, parsedPath);
  }

  void getValue(int array, int offset){
    bind(); // bind all binding

    final firstValidIndex = _targetGroup.nCachedObjects_,
        binding = _bindings[firstValidIndex];

    // and only call .getValue on the first
    if (binding != null) binding.getValue(array, offset);
  }

  void setValue(int array, int offset) {
    final bindings = _bindings;

    for (int i = _targetGroup.nCachedObjects_, n = bindings.length;i != n;++i) {
      bindings[i]?.setValue(array, offset);
    }
  }

  @override
  void bind() {
    final bindings = _bindings;

    for (int i = _targetGroup.nCachedObjects_, n = bindings.length;i != n;++i) {
      bindings[i]?.bind();
    }
  }
  @override
  void unbind() {
    final bindings = _bindings;

    for (int i = _targetGroup.nCachedObjects_, n = bindings.length;i != n;++i) {
      bindings[i]?.unbind();
    }
  }
}

enum BindingType{direct,entireArray,arrayElement,hasFromToArray}
enum Versioning{none,needsUpdate,matrixWorldNeedsUpdate}

class PropertyBinding extends AnimationBinding{
  late String path;
  late Map<String, dynamic> parsedPath;
  late Object3D? node;
  late Object3D? rootNode;

  late String propertyName;
  late dynamic resolvedProperty;

  late dynamic targetObject;
  late Function(dynamic,int) getValue;
  late Function(dynamic,int) setValue;
  late String? propertyIndex;

  PropertyBinding(this.rootNode, this.path, Map<String, dynamic>? parsedPath) {
    this.parsedPath = parsedPath ?? PropertyBinding.parseTrackName(path);
    node = PropertyBinding.findNode(rootNode, this.parsedPath["nodeName"]) ?? rootNode;
    getValue = getValueUnbound;
    setValue = setValueUnbound;
  }

  static AnimationBinding create(root, String path, Map<String,dynamic>? parsedPath) {
    if (!(root != null && root is AnimationObjectGroup)) {
      return PropertyBinding(root, path, parsedPath);
    } 
    else {
      return Composite(root, path, parsedPath);
    }
  }

  ///  *
	///  * Replaces spaces with underscores and removes unsupported characters from
	///  * node names, to ensure compatibility with parseTrackName().
	///  *
	///  * @param {string} name Node name to be sanitized.
	///  * @return {string}
	///  *
  static String sanitizeNodeName(String name) {
    final reg = RegExp(r"\s");

    String tempName = name.replaceAll(reg, '_');
    tempName = tempName.replaceAll(_reservedRe, '');

    return tempName;
  }

  static Map<String, dynamic> parseTrackName(String trackName) {
    final matches = _trackRe.firstMatch(trackName);

    if (matches == null) {
      throw ('PropertyBinding: Cannot parse trackName: $trackName');
    }

    final results = {
      // directoryName: matches[ 1 ], // (tschw) currently unused
      "nodeName": matches.group(2),
      "objectName": matches.group(3),
      "objectIndex": matches.group(4),
      "propertyName": matches.group(5), // required
      "propertyIndex": matches.group(6)
    };

    String? nodeName = results["nodeName"];

    int? lastDot;

    if (nodeName != null) {
      lastDot = nodeName.lastIndexOf('.');
    }

    if (lastDot != null && lastDot != -1) {
      final objectName = results["nodeName"]!.substring(lastDot + 1);

      // Object names must be checked against an allowlist. Otherwise, there
      // is no way to parse 'foo.bar.baz': 'baz' must be a property, but
      // 'bar' could be the objectName, or part of a nodeName (which can
      // include '.' characters).
      if (_supportedObjectNames.contains(objectName)) {
        results["nodeName"] = results["nodeName"]!.substring(0, lastDot);
        results["objectName"] = objectName;
      }
    }

    if (results["propertyName"] == null || results["propertyName"]!.isEmpty) {
      throw ('PropertyBinding: can not parse propertyName from trackName: $trackName');
    }

    return results;
  }

  static Object3D? searchNodeSubtree(List<Object3D> children, String nodeName) {
    for (int i = 0; i < children.length; i++) {
      final childNode = children[i];

      if (childNode.name == nodeName || childNode.uuid == nodeName) {
        return childNode;
      }

      final result = searchNodeSubtree(childNode.children, nodeName);

      if (result != null) return result;
    }

    return null;
  }

  static Object3D? findNode(Object3D? root, String? nodeName) {
    if (nodeName == null ||
      nodeName == '' ||
      nodeName == '.' ||
      root == null ||
      nodeName == root.name ||
      nodeName == root.uuid
    ){
      return root;
    }

    // search into skeleton bones.
    if (root.skeleton != null) {
      final bone = root.skeleton!.getBoneByName(nodeName);

      if (bone != null) {
        return bone;
      }
    }

    // search into node subtree.
    if (root.children.isNotEmpty) {
      final subTreeNode = searchNodeSubtree(root.children, nodeName);

      if (subTreeNode != null) {
        return subTreeNode;
      }
    }

    return null;
  }

  // these are used to "bind" a nonexistent property
  void _getValueUnavailable(dynamic b, int v){}
  void _setValueUnavailable(dynamic b, int v){}

  Function(dynamic,int) getterByBindingType(int idx ,int v) {
    if (idx == 0) {
      return getValueDirect;
    } 
    else if (idx == 1) {
      return getValueArray;
    } 
    else if (idx == 2) {
      return getValueArrayElement;
    } 
    else if (idx == 3) {
      return getValueToArray;
    } 
    else {
      throw ("PropertyBinding.getterByBindingType idx: $idx is not support ");
    }
  }

  // 0
  void getValueDirect(buffer, int offset) {
    final v = targetObject.getProperty(propertyName);
    buffer[offset] = v;
  }

  // 1
  void getValueArray(buffer, int offset) {
    final source = resolvedProperty;
    for (int i = 0, n = source.length; i != n; ++i) {
      buffer[offset++] = source[i];
    }
  }

  // 2
  void getValueArrayElement(buffer, int offset) {
    buffer[offset] = resolvedProperty[propertyIndex];
  }

  // 3
  void getValueToArray(buffer, int offset) {
    resolvedProperty.toNumArray(buffer, offset);
  }

  Function(dynamic,int)? setterByBindingTypeAndVersioning(int bindingType, int versioning) {
    if (bindingType == 0) {
      if (versioning == 0) {
        return setValueDirect;
      } else if (versioning == 1) {
        return setValueDirectSetNeedsUpdate;
      } else if (versioning == 2) {
        return setValueDirectSetMatrixWorldNeedsUpdate;
      }
    } else if (bindingType == 1) {
      if (versioning == 0) {
        return setValueArray;
      } else if (versioning == 1) {
        return setValueArraySetNeedsUpdate;
      } else if (versioning == 2) {
        return setValueArraySetMatrixWorldNeedsUpdate;
      }
    } else if (bindingType == 2) {
      if (versioning == 0) {
        return setValueArrayElement;
      } else if (versioning == 1) {
        return setValueArrayElementSetNeedsUpdate;
      } else if (versioning == 2) {
        return setValueArrayElementSetMatrixWorldNeedsUpdate;
      }
    } else if (bindingType == 3) {
      if (versioning == 0) {
        return setValueFromArray;
      } else if (versioning == 1) {
        return setValueFromArraySetNeedsUpdate;
      } else if (versioning == 2) {
        return setValueFromArraySetMatrixWorldNeedsUpdate;
      }
    }

    return null;
  }

  void setValueDirect(buffer, int offset) {
    targetObject[propertyName] = buffer[offset];
    //targetObject.setProperty(propertyName, buffer[offset], offset);
  }

  void setValueDirectSetNeedsUpdate(buffer, int offset) {
    targetObject[propertyName] = buffer[ offset ];
    //targetObject.setProperty(propertyName, buffer[offset], offset);
    targetObject.needsUpdate = true;
  }

  void setValueDirectSetMatrixWorldNeedsUpdate(buffer, int offset) {
    targetObject[propertyName] = buffer[ offset ];
    //targetObject.setProperty(propertyName, buffer[offset].toDouble(), offset);
    targetObject.matrixWorldNeedsUpdate = true;
  }

  void setValueArray(buffer, int offset) {
    final dest = resolvedProperty;
    for (int i = 0, n = dest.length; i != n; ++i) {
      dest[i] = buffer[offset++];
    }
  }

  void setValueArraySetNeedsUpdate(buffer, int offset) {
    final dest = resolvedProperty;
    for (int i = 0, n = dest.length; i != n; ++i) {
      dest[i] = buffer[offset++];
    }
    targetObject.needsUpdate = true;
  }

  void setValueArraySetMatrixWorldNeedsUpdate(buffer, int offset) {
    final dest = resolvedProperty;
    for (int i = 0, n = dest.length; i != n; ++i) {
      dest[i] = buffer[offset++].toDouble();
    }
    targetObject.matrixWorldNeedsUpdate = true;
  }

  void setValueArrayElement(buffer, int offset) {
    resolvedProperty[propertyIndex] = buffer[offset];
  }

  void setValueArrayElementSetNeedsUpdate(buffer, int offset) {
    resolvedProperty[propertyIndex] = buffer[offset];
    targetObject.needsUpdate = true;
  }

  void setValueArrayElementSetMatrixWorldNeedsUpdate(buffer, int offset) {
    resolvedProperty[propertyIndex] = buffer[offset];
    targetObject.matrixWorldNeedsUpdate = true;
  }

  void setValueFromArray(buffer, int offset) {
    resolvedProperty.copyFromUnknown(buffer, offset);
  }

  void setValueFromArraySetNeedsUpdate(buffer, int offset) {
    resolvedProperty.copyFromUnknown(List<double>.from(buffer.map((e) => e.toDouble())), offset);
    targetObject.needsUpdate = true;
  }

  void setValueFromArraySetMatrixWorldNeedsUpdate(buffer, offset) {
    resolvedProperty.copyFromUnknown(buffer, offset);
    targetObject.matrixWorldNeedsUpdate = true;
  }

  void getValueUnbound(targetArray, int offset) {
    bind();
    getValue(targetArray, offset);

    // Note: This class uses a State pattern on a per-method basis:
    // 'bind' sets 'this.getValue' / 'setValue' and shadows the
    // prototype version of these methods with one that represents
    // the bound state. When the property is not found, the methods
    // become no-ops.
  }

  void setValueUnbound(sourceArray, int offset) {
    bind();
    setValue(sourceArray, offset);
  }

  // create getter / setter pair for a property in the scene graph
  @override
  void bind() {
    dynamic targetObject = node;
    final parsedPath = this.parsedPath;

    final objectName = parsedPath["objectName"];
    final propertyName = parsedPath["propertyName"];
    String? propertyIndex = parsedPath["propertyIndex"];

    if (targetObject == null) {
      targetObject = PropertyBinding.findNode(rootNode, parsedPath["nodeName"]) ?? rootNode;
      node = targetObject;
    }

    // set fail state so we can just 'return' on error
    getValue = _getValueUnavailable;
    setValue = _setValueUnavailable;

    // ensure there is a value node
    if (targetObject == null) {
      console.warning('PropertyBinding: Trying to update node for track: $path but it wasn\'t found.');
      return;
    }

    if (objectName != null) {
      int? objectIndex = parsedPath["objectIndex"];

      // special cases were we need to reach deeper into the hierarchy to get the face materials....
      switch (objectName) {
        case 'materials':
          if (!targetObject.material) {
            console.warning('PropertyBinding: Can not bind to material as node does not have a material. $this');
            return;
          }

          if (!targetObject.material.materials) {
            console.warning('PropertyBinding: Can not bind to material.materials as node.material does not have a materials array. $this');
            return;
          }
          targetObject = targetObject.material.materials;
          break;
        case 'bones':
          if (targetObject.skeleton != null) {
            console.warning('PropertyBinding: Can not bind to bones as node does not have a skeleton. $this');
            return;
          }
          // potential future optimization: skip this if propertyIndex is already an integer
          // and convert the integer string to a true integer.
          targetObject.children = targetObject.skeleton!.bones;

          // support resolving morphTarget names into indices.
          for (int i = 0; i < targetObject.children.length; i++) {
            if (targetObject.children[i].name == objectIndex.toString()) {
              objectIndex = i;
              break;
            }
          }
          break;
        default:
          if (targetObject.getProperty(objectName) == null) {
            console.warning('PropertyBinding: Can not bind to objectName of node null. $this');
            return;
          }

          // targetObject = targetObject[ objectName ];
          targetObject = targetObject.getProperty(objectName);
      }

      if (objectIndex != null) {
        if (targetObject?.children[objectIndex] == null) {
          console.warning('PropertyBinding: Trying to bind to objectIndex of objectName, but is null.$this $targetObject');
          return;
        }

        targetObject = targetObject?.children[objectIndex];
      }
    }

    // resolve property
    final nodeProperty = targetObject?.getProperty(propertyName);

    if (nodeProperty == null) {
      final nodeName = parsedPath["nodeName"];

      console.warning('PropertyBinding: Trying to update property for track: $nodeName $propertyName  but it wasn\'t found. $targetObject');
      return;
    }

    // determine versioning scheme
    Versioning versioning = Versioning.none;

    this.targetObject = targetObject;

    // if ( targetObject.needsUpdate != null ) { // material
    if (targetObject.runtimeType.toString().endsWith("Material")) {
      versioning = Versioning.needsUpdate;
    } 
    else if (targetObject?.matrixWorldNeedsUpdate != null) {
      // node transform
      versioning = Versioning.matrixWorldNeedsUpdate;
    }

    // determine how the property gets bound
    BindingType bindingType = BindingType.direct;

    if (propertyIndex != null) {
      // access a sub element of the property array (only primitives are supported right now)

      if (propertyName == 'morphTargetInfluences') {
        // potential optimization, skip this if propertyIndex is already an integer, and convert the integer string to a true integer.

        // support resolving morphTarget names into indices.
        if (targetObject?.geometry != null) {
          console.warning('PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry. $this');
          return;
        }

        if (targetObject?.geometry is BufferGeometry) {
          if (targetObject?.geometry?.morphAttributes != null) {
            console.warning('PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes. $this');
            return;
          }

          if (targetObject?.morphTargetDictionary?[propertyIndex] != null) {
            propertyIndex = targetObject!.morphTargetDictionary![propertyIndex];
          }
        } 
        else {
          console.warning('PropertyBinding: Can not bind to morphTargetInfluences on Geometry. Use BufferGeometry instead. $this');
          return;
        }
      }

      bindingType = BindingType.arrayElement;

      resolvedProperty = nodeProperty;
      this.propertyIndex = propertyIndex;
      // } else if ( nodeProperty.fromArray != null && nodeProperty.toArray != null ) {
    } 
    else if (["Color", "Vector3", "Quaternion"].contains(nodeProperty.runtimeType.toString())) {
      // must use copy for Object3D.Euler/Quaternion
      bindingType = BindingType.hasFromToArray;
      resolvedProperty = nodeProperty;
    } 
    else if (nodeProperty is List) {
      bindingType = BindingType.entireArray;
      resolvedProperty = nodeProperty;
    } 
    else {
      this.propertyName = propertyName;
    }

    // select getter / setter
    getValue = getterByBindingType(bindingType.index,0);
    setValue = setterByBindingTypeAndVersioning(bindingType.index, versioning.index)!;
  }
  @override
  void unbind() {
    node = null;

    // back to the prototype version of getValue / setValue
    // note: avoiding to mutate the shape of 'this' via 'delete'
    getValue = _getValueUnbound;
    setValue = _setValueUnbound;
  }

  Function _getValueUnbound(b, int v) {
    return getValue(b,v);
  }

  Function _setValueUnbound(b, int v) {
    return setValue(b,v);
  }
}
