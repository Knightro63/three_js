import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

// Pre-compiled regex patterns for performance
final RegExp variantPathRegex = RegExp(r'^(.+?)/\{(\w+)=(\w+)\}/(.+)$');

/// Spec types (must match USDCParser)
enum SpecType {
  unknown(0),
  attribute(1),
  connection(2),
  expression(3),
  mapper(4),
  mapperArg(5),
  prim(6),
  pseudoRoot(7),
  relationship(8),
  relationshipTarget(9),
  variant(10),
  variantSet(11);

  final int value;
  const SpecType(this.value);
}

/// UsdGeomCamera fallback values (OpenUSD schema)
final Map<String, dynamic> usdCameraDefaults = {
  'projection': 'perspective',
  'clippingRange': Float32List.fromList([1.0, 1000000.0]),
  'horizontalAperture': 20.955,
  'verticalAperture': 15.2908,
  'horizontalApertureOffset': 0.0,
  'verticalApertureOffset': 0.0,
  'focalLength': 50.0,
  'focusDistance': 0.0,
  'fStop': 0.0,
};

/**
 * USDComposer handles scene composition from parsed USD data.
 * This includes reference resolution, variant selection, transform handling,
 * and building the Three.js scene graph.
 *
 * Works with specsByPath format from USDCParser.
 */
class USDComposer {
  LoadingManager? manager;

  Map<String,dynamic> textureCache = {};
  List<Map<String,dynamic>> skinnedMeshes = [];
  List<Future> texturePromises = [];

  Map<String, dynamic> childrenByPath = {};
  Map<String, dynamic> attributesByPrimPath = {};
  Map<String, dynamic> materialsByRoot = {};
  Map<String, dynamic> shadersByMaterialPath = {};
  Map<String, dynamic> geomSubsetsByMeshPath = {};
  Map<String,dynamic> skeletons = {};

  Map<String, dynamic> assets = {};
  Map<String, dynamic> specsByPath = {};
  Map<String, dynamic>  externalVariantSelections = {};

  String basePath = '';
  double fps = 24;

	USDComposer([this.manager]);

  /// Compose a Three.js scene from parsed USD data using pub.dev packages.
  Group compose(
    Map<String, dynamic> parsedData, {
    Map<String, dynamic>? assets,
    Map<String, dynamic>? variantSelections,
    String basePath = '',
  }) {
    specsByPath = parsedData['specsByPath'] as Map<String, dynamic>? ?? {};
    this.assets = assets ?? {};
    externalVariantSelections = variantSelections ?? {};
    this.basePath = basePath;
    
    // Reinitialize ecosystem instance arrays
    skinnedMeshes = [];
    skeletons = {};
    texturePromises = [];

    // Build indexes for O(1) lookups
    _buildIndexes();

    // Get FPS from root spec field descriptors
    final Map<String, dynamic>? rootSpec = specsByPath['/'] as Map<String, dynamic>?;
    final Map<String, dynamic> rootFields = (rootSpec != null && rootSpec['fields'] is Map<String, dynamic>)
        ? rootSpec['fields'] as Map<String, dynamic>
        : {};

    // Resolve frame rate timing metrics safely
    fps = (rootFields['timeCodesPerSecond'] as num?)?.toDouble() ??
          (rootFields['framesPerSecond'] as num?)?.toDouble() ??
          24.0;

    // Group is imported natively from three_js_core
    final AnimationObject group = AnimationObject();
    _buildHierarchy(group, '/');

    // Bind skeletons to skinned meshes
    _bindSkeletons();

    // Expose skeleton on the root group so that AnimationMixer's
    // PropertyBinding.findNode resolves bone names before scene objects.
    final List<String> skeletonPaths = skeletons.keys.toList();
    if (skeletonPaths.length == 1) {
      final dynamic targetSkeletonNode = skeletons[skeletonPaths.first];
      if (targetSkeletonNode != null) {
        // Set the dynamic skeleton property directly on the core object instance
        group.skeleton = targetSkeletonNode['skeleton'];
      }
    }

    // Build and bind animations from three_js_animations framework
    // List<AnimationClip> animations is natively available on Object3D/Group
    final List<AnimationClip> generatedAnimations = _buildAnimations();
    group.animations = generatedAnimations;

    // Handle metersPerUnit scaling via three_js_math vectors
    final double? metersPerUnit = (rootFields['metersPerUnit'] as num?)?.toDouble();
    if (metersPerUnit != null && metersPerUnit != 1.0) {
      // group.scale is a native Vector3 property provided by three_js_math
      group.scale.setScalar(metersPerUnit);
    }

    // Handle Z-up to Y-up matrix conversion orientation adjustments
    if (rootSpec != null && rootFields['upAxis'] == 'Z') {
      // group.rotation is a native Euler or Vector3 representation.
      // three_js allows assignments directly through coordinates.
      group.rotation.x = -math.pi / 2.0;
    }

    return group;
  }

  /// Apply USD transforms to a Three.js object.
  /// Handles xformOpOrder with proper matrix composition.
  /// USD uses row-vector convention, Three.js uses column-vector.
  void applyTransform(
    Object3D obj,
    Map<String, dynamic> fields, [
    Map<String, dynamic> attrs = const {},
  ]) {
    final Map<String, dynamic> data = {...fields, ...attrs};
    final dynamic xformOpOrderRaw = data['xformOpOrder'];
    
    final List<dynamic>? xformOpOrder = xformOpOrderRaw is List 
        ? xformOpOrderRaw 
        : null;

    // If we have xformOpOrder, apply transforms using matrices
    if (xformOpOrder != null && xformOpOrder.isNotEmpty) {
      final Matrix4 matrix = Matrix4();
      final Matrix4 tempMatrix = Matrix4();

      // Track scale for handling negative scale with rotation
      List<double>? scaleValues;

      // Iterate FORWARD for Three.js column-vector convention
      for (int i = 0; i < xformOpOrder.length; i++) {
        final String op = xformOpOrder[i].toString();
        final bool isInverse = op.startsWith('!invert!');
        final String opName = isInverse ? op.substring(8) : op;

        if (opName == 'xformOp:transform') {
          final dynamic m = data['xformOp:transform'];
          if (m is List && m.length == 16) {
            // Flatten/extract values explicitly as doubles
            final List<double> values = m.map((v) => (v as num).toDouble()).toList();
            
            // Row-major elements from USD mapped to Three.js internal storage rules
            tempMatrix.setValues(
              values[0], values[4], values[8], values[12],
              values[1], values[5], values[9], values[13],
              values[2], values[6], values[10], values[14],
              values[3], values[7], values[11], values[15],
            );
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:translate') {
          final dynamic t = data['xformOp:translate'];
          if (t is List && t.length >= 3) {
            tempMatrix.makeTranslation(
              (t[0] as num).toDouble(),
              (t[1] as num).toDouble(),
              (t[2] as num).toDouble(),
            );
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:translate:pivot') {
          final dynamic t = data['xformOp:translate:pivot'];
          if (t is List && t.length >= 3) {
            tempMatrix.makeTranslation(
              (t[0] as num).toDouble(),
              (t[1] as num).toDouble(),
              (t[2] as num).toDouble(),
            );
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:scale') {
          final dynamic s = data['xformOp:scale'];
          if (s != null) {
            if (s is List && s.length >= 3) {
              final double sx = (s[0] as num).toDouble();
              final double sy = (s[1] as num).toDouble();
              final double sz = (s[2] as num).toDouble();
              tempMatrix.makeScale(sx, sy, sz);
              scaleValues = [sx, sy, sz];
            } else if (s is num) {
              final double sVal = s.toDouble();
              tempMatrix.makeScale(sVal, sVal, sVal);
              scaleValues = [sVal, sVal, sVal];
            }
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:rotateXYZ') {
          final dynamic r = data['xformOp:rotateXYZ'];
          if (r is List && r.length >= 3) {
            // USD rotateXYZ: matrix = Rx * Ry * Rz
            // Three.js Euler 'ZYX' order produces same result
            final Euler euler = Euler(
              (r[0] as num).toDouble() * math.pi / 180.0,
              (r[1] as num).toDouble() * math.pi / 180.0,
              (r[2] as num).toDouble() * math.pi / 180.0,
              RotationOrders.zxy,
            );
            tempMatrix.makeRotationFromEuler(euler);
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:rotateX') {
          final dynamic r = data['xformOp:rotateX'];
          if (r is num) {
            tempMatrix.makeRotationX(r.toDouble() * math.pi / 180.0);
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:rotateY') {
          final dynamic r = data['xformOp:rotateY'];
          if (r is num) {
            tempMatrix.makeRotationY(r.toDouble() * math.pi / 180.0);
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:rotateZ') {
          final dynamic r = data['xformOp:rotateZ'];
          if (r is num) {
            tempMatrix.makeRotationZ(r.toDouble() * math.pi / 180.0);
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        } else if (opName == 'xformOp:orient') {
          final dynamic q = data['xformOp:orient'];
          if (q is List && q.length == 4) {
            final Quaternion quat = Quaternion(
              (q[0] as num).toDouble(),
              (q[1] as num).toDouble(),
              (q[2] as num).toDouble(),
              (q[3] as num).toDouble(),
            );
            tempMatrix.makeRotationFromQuaternion(quat);
            if (isInverse) tempMatrix.invert();
            matrix.multiply(tempMatrix);
          }
        }
      }

      obj.matrix.setFrom(matrix);
      obj.matrix.decompose(obj.position, obj.quaternion, obj.scale);

      // Fix for negative scale: decompose() may absorb negative scale into quaternion
      // Restore original scale signs to keep animation consistent
      if (scaleValues != null) {
        final bool negX = scaleValues[0] < 0;
        final bool negY = scaleValues[1] < 0;
        final bool negZ = scaleValues[2] < 0;
        final int negCount = (negX ? 1 : 0) + (negY ? 1 : 0) + (negZ ? 1 : 0);

        // decompose() absorbs pairs of negative scales into rotation
        // For [-1,-1,-1] → [-1,1,1], Y and Z were absorbed, flip quat.y and quat.w
        if (negCount == 3) {
          obj.scale.setValues(scaleValues[0], scaleValues[1], scaleValues[2]);
          obj.quaternion.set(
            obj.quaternion.x,
            -obj.quaternion.y,
            obj.quaternion.z,
            -obj.quaternion.w,
          );
        }
      }
      return;
    }

    // Fallback: handle individual transform ops without order
    if (data.containsKey('xformOp:translate')) {
      final dynamic t = data['xformOp:translate'];
      if (t is List && t.length >= 3) {
        obj.position.setValues(
          (t[0] as num).toDouble(),
          (t[1] as num).toDouble(),
          (t[2] as num).toDouble(),
        );
      }
    }

    if (data.containsKey('xformOp:translate:pivot')) {
      final dynamic p = data['xformOp:translate:pivot'];
      if (p is List && p.length >= 3) {
        // Assuming a custom property or vector extension on your object layout definition
        // because Object3D doesn't naturally contain an exposed direct pivot vector property slot
        (obj as dynamic).pivot = Vector3(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
          (p[2] as num).toDouble(),
        );
      }
    }

    if (data.containsKey('xformOp:scale')) {
      final dynamic s = data['xformOp:scale'];
      if (s is List && s.length >= 3) {
        obj.scale.setValues(
          (s[0] as num).toDouble(),
          (s[1] as num).toDouble(),
          (s[2] as num).toDouble(),
        );
      } else if (s is num) {
        final double sVal = s.toDouble();
        obj.scale.setValues(sVal, sVal, sVal);
      }
    }

    if (data.containsKey('xformOp:rotateXYZ')) {
      final dynamic r = data['xformOp:rotateXYZ'];
      if (r is List && r.length >= 3) {
        obj.rotation.set(
          (r[0] as num).toDouble() * math.pi / 180.0,
          (r[1] as num).toDouble() * math.pi / 180.0,
          (r[2] as num).toDouble() * math.pi / 180.0,
        );
      }
    }

    if (data.containsKey('xformOp:orient')) {
      final dynamic q = data['xformOp:orient'];
      if (q is List && q.length == 4) {
        obj.quaternion.set(
          (q[0] as num).toDouble(),
          (q[1] as num).toDouble(),
          (q[2] as num).toDouble(),
          (q[3] as num).toDouble(),
        );
      }
    }
  }

  /// Build indexes for efficient lookups.
  /// Called once during compose() to avoid O(n) scans per lookup.
  void _buildIndexes() {
    childrenByPath = {};
    attributesByPrimPath = {};
    materialsByRoot = {};
    shadersByMaterialPath = {};
    geomSubsetsByMeshPath = {};

    for (final String path in specsByPath.keys) {
      final dynamic spec = specsByPath[path];
      if (spec == null) continue;

      final int specType = spec['specType'] is int 
          ? spec['specType'] as int 
          : (spec['specType'] is SpecType ? (spec['specType'] as SpecType).value : 0);

      final Map<String, dynamic> fields = (spec['fields'] is Map<String, dynamic>)
          ? spec['fields'] as Map<String, dynamic>
          : {};

      if (specType == SpecType.prim.value) {
        // Build parent-child index
        final int lastSlash = path.lastIndexOf('/');
        if (lastSlash > 0) {
          final String parentPath = path.substring(0, lastSlash);
          final String childName = path.substring(lastSlash + 1);

          if (!childrenByPath.containsKey(parentPath)) {
            childrenByPath[parentPath] = [];
          }
          childrenByPath[parentPath]!.add({
            'name': childName,
            'path': path,
          });
        } else if (lastSlash == 0 && path.length > 1) {
          // Direct child of root
          final String childName = path.substring(1);
          if (!childrenByPath.containsKey('/')) {
            childrenByPath['/'] = [];
          }
          childrenByPath['/']!.add({
            'name': childName,
            'path': path,
          });
        }

        final String typeName = fields['typeName']?.toString() ?? '';

        // Build material index
        if (typeName == 'Material') {
          final List<String> parts = path.split('/');
          final String rootPath = parts.length > 1 ? '/${parts[1]}' : '/';
          
          if (!materialsByRoot.containsKey(rootPath)) {
            materialsByRoot[rootPath] = [];
          }
          materialsByRoot[rootPath]!.add(path);
        }

        // Build shader index (shaders are children or descendants of materials)
        if (typeName == 'Shader' && lastSlash > 0) {
          // Walk up ancestors to find the nearest Material prim.
          // Shaders may be direct children of a Material, or nested
          // inside a NodeGraph (common with MaterialX materials).
          String ancestorPath = path.substring(0, lastSlash);
          while (ancestorPath.isNotEmpty) {
            final dynamic ancestorSpec = specsByPath[ancestorPath];
            
            if (ancestorSpec != null) {
              final int ancestorType = ancestorSpec['specType'] is int 
                  ? ancestorSpec['specType'] as int 
                  : (ancestorSpec['specType'] is SpecType ? (ancestorSpec['specType'] as SpecType).value : 0);
                  
              final Map<String, dynamic> ancestorFields = (ancestorSpec['fields'] is Map<String, dynamic>)
                  ? ancestorSpec['fields'] as Map<String, dynamic>
                  : {};

              if (ancestorType == SpecType.prim.value && ancestorFields['typeName'] == 'Material') {
                if (!shadersByMaterialPath.containsKey(ancestorPath)) {
                  shadersByMaterialPath[ancestorPath] = [];
                }
                shadersByMaterialPath[ancestorPath]!.add(path);
                break;
              }
            }

            final int slash = ancestorPath.lastIndexOf('/');
            if (slash <= 0) break;
            ancestorPath = ancestorPath.substring(0, slash);
          }
        }

        // Build GeomSubset index (subsets are children of meshes)
        if (typeName == 'GeomSubset' && lastSlash > 0) {
          final String meshPath = path.substring(0, lastSlash);
          if (!geomSubsetsByMeshPath.containsKey(meshPath)) {
            geomSubsetsByMeshPath[meshPath] = [];
          }
          geomSubsetsByMeshPath[meshPath]!.add(path);
        }
      } else if (specType == SpecType.attribute.value || specType == SpecType.relationship.value) {
        // Build attribute index
        final int dotIndex = path.lastIndexOf('.');
        if (dotIndex > 0) {
          final String primPath = path.substring(0, dotIndex);
          final String attrName = path.substring(dotIndex + 1);

          if (!attributesByPrimPath.containsKey(primPath)) {
            attributesByPrimPath[primPath] = {};
          }
          attributesByPrimPath[primPath]![attrName] = spec;
        }
      }
    }
  }

  /// Check if a path is a direct child of parentPath.
  // bool _isDirectChild(String parentPath, String path, String prefix) {
  //   if (!path.startsWith(prefix)) return false;

  //   final String remainder = path.substring(prefix.length);
  //   if (remainder.isEmpty) return false;

  //   // Check for variant paths or simple names
  //   if (remainder.startsWith('{')) {
  //     return false; // Variant paths are not direct children
  //   }

  //   return !remainder.contains('/');
  // }

  /// Build the scene hierarchy recursively.
  /// Uses childrenByPath index for O(1) child lookup instead of O(n) iteration.
  void _buildHierarchy(Object3D parent, String parentPath) {
    // Map signature assumptions from prior layout index definitions:
    // Map<String, List<Map<String, String>>> childrenByPath;
    
    final List<Map<String, String>> childEntries = [];
    final Set<String> seenPaths = {};

    // Get direct children using the index lookup window
    final List<Map<String, String>>? directChildren = childrenByPath[parentPath];
    if (directChildren != null) {
      for (final Map<String, String> child in directChildren) {
        final String? path = child['path'];
        if (path != null && !seenPaths.contains(path)) {
          seenPaths.add(path);
          childEntries.add(child);
        }
      }
    }

    // Also get children from active variant paths
    final List<String> variantPaths = _getVariantPaths(parentPath);
    for (final String vp in variantPaths) {
      final List<Map<String, String>>? variantChildren = childrenByPath[vp];
      if (variantChildren != null) {
        for (final Map<String, String> child in variantChildren) {
          final String? path = child['path'];
          if (path != null && !seenPaths.contains(path)) {
            seenPaths.add(path);
            childEntries.add(child);
          }
        }
      }
    }

    // Process each child spatial node entry sequentially
    for (final Map<String, String> entry in childEntries) {
      final String name = entry['name'] ?? '';
      final String path = entry['path'] ?? '';

      final dynamic spec = specsByPath[path];
      if (spec == null) continue;

      final int specType = spec['specType'] is int 
          ? spec['specType'] as int 
          : (spec['specType'] is SpecType ? (spec['specType'] as SpecType).value : 0);

      if (specType != SpecType.prim.value) continue;

      final Map<String, dynamic> fields = (spec['fields'] is Map<String, dynamic>)
          ? spec['fields'] as Map<String, dynamic>
          : {};
          
      final String typeName = fields['typeName']?.toString() ?? '';

      // Check for references/payloads
      final List<dynamic> refValues = _getReferences(spec);
      if (refValues.isNotEmpty) {
        // Get local variant selections from this prim descriptor
        final Map<String, dynamic> localVariants = _getLocalVariantSelections(fields);

        // Resolve all downstream composition references
        final List<Object3D> resolvedGroups = [];
        for (final dynamic refValue in refValues) {
          final Object3D? referencedGroup = _resolveReference(refValue, localVariants);
          if (referencedGroup != null) {
            resolvedGroups.add(referencedGroup);
          }
        }

        if (resolvedGroups.isNotEmpty) {
          final Map<String, dynamic> attrs = _getAttributes(path);

          // Single reference with single mesh: use optimized merge path
          // This handles the USDZExporter pattern: Xform references geometry file
          if (resolvedGroups.length == 1) {
            final Object3D? singleMesh = _findSingleMesh(resolvedGroups.first);
            if (singleMesh != null && (typeName == 'Xform' || typeName.isEmpty)) {
              // Merge the mesh target metadata straight into this prim
              singleMesh.name = name;
              applyTransform(singleMesh, fields, attrs);

              // Apply material binding from the referencing prim if present
              _applyMaterialBinding(singleMesh, path);
              parent.add(singleMesh);

              // Still build local children (overrides) recursively
              _buildHierarchy(singleMesh, path);
              continue;
            }
          }

          // Create a standard container node for the referenced spatial content
          final Object3D obj = Object3D();
          obj.name = name;
          applyTransform(obj, fields, attrs);

          // Add all children from all resolved hierarchy references
          for (final Object3D referencedGroup in resolvedGroups) {
            while (referencedGroup.children.isNotEmpty) {
              obj.add(referencedGroup.children.first);
            }
          }
          parent.add(obj);

          // Still build local children (overrides)
          _buildHierarchy(obj, path);
          continue;
        }
      }

      // Build appropriate Three.js object based on schema type
      if (typeName == 'SkelRoot') {
        // Skeletal root - treat as standard transform but flag for skeleton binding step
        final Object3D obj = Object3D();
        obj.name = name;
        obj.userData['isSkelRoot'] = true;
        
        final Map<String, dynamic> attrs = _getAttributes(path);
        applyTransform(obj, fields, attrs);
        parent.add(obj);
        
        _buildHierarchy(obj, path);
      } else if (typeName == 'Skeleton') {
        // Build skeleton architecture and catalog its instance pointer map
        final dynamic skeleton = _buildSkeleton(path);
        if (skeleton != null) {
          skeletons[path] = skeleton;
        }

        // Recursively build children (may contain underlying SkelAnimation components)
        _buildHierarchy(parent, path);
      } else if (typeName == 'SkelAnimation') {
        // Skip - animations are processed downstream concurrently in _buildAnimations()
      } else if (typeName == 'Mesh') {
        final Object3D? obj = _buildMesh(path, spec);
        if (obj != null) {
          parent.add(obj);
          _buildHierarchy(obj, path);
        }
      } 
      else if (typeName == 'Camera') {
        final Object3D obj = _buildCamera(path);
        obj.name = name;
        
        final Map<String, dynamic> attrs = _getAttributes(path);
        applyTransform(obj, fields, attrs);
        parent.add(obj);
        
        _buildHierarchy(obj, path);
      } 
      else if (
        typeName == 'DistantLight' || 
        typeName == 'SphereLight' || 
        typeName == 'RectLight' || 
        typeName == 'DiskLight'
      ) {
        final Object3D? obj = _buildLight(path, typeName);
        if(obj != null){
          obj.name = name;
          
          final Map<String, dynamic> attrs = _getAttributes(path);
          applyTransform(obj, fields, attrs);
          parent.add(obj);
          
          _buildHierarchy(obj, path);
        }
      } 
      else if (
        typeName == 'Cube' || 
        typeName == 'Sphere' || 
        typeName == 'Cylinder' || 
        typeName == 'Cone' || 
        typeName == 'Capsule'
      ) {
        final Object3D? obj = _buildGeomPrimitive(path, spec, typeName);
        if (obj != null) {
          parent.add(obj);
          _buildHierarchy(obj, path);
        }
      } else if (typeName == 'Material' || typeName == 'Shader' || typeName == 'GeomSubset') {
        // Skip materials/shaders/subsets, they are looked up directly by parent meshes
      } else {
        // Fallback: Transform node, standard group, or unknown generic prim layout
        final Object3D obj = Object3D();
        obj.name = name;
        
        final Map<String, dynamic> attrs = _getAttributes(path);
        applyTransform(obj, fields, attrs);
        parent.add(obj);
        
        _buildHierarchy(obj, path);
      }
    }
  }

  /// Get variant paths for a parent path based on variant selections.
  List<String> _getVariantPaths(String parentPath) {
    final dynamic parentSpec = specsByPath[parentPath];
    
    final Map<String, dynamic> parentFields = (parentSpec != null && parentSpec['fields'] is Map<String, dynamic>)
        ? parentSpec['fields'] as Map<String, dynamic>
        : {};

    final dynamic variantSetChildrenRaw = parentFields['variantSetChildren'];
    final List<dynamic>? variantSetChildren = variantSetChildrenRaw is List ? variantSetChildrenRaw : null;
    final List<String> variantPaths = [];

    if (variantSetChildren == null || variantSetChildren.isEmpty) {
      return variantPaths;
    }

    for (final dynamic nameEntry in variantSetChildren) {
      final String variantSetName = nameEntry.toString();

      // External selections take priority
      String? selectedVariant = externalVariantSelections[variantSetName]?.toString();

      // Fall back to file's internal selection
      if (selectedVariant == null) {
        final dynamic variantSelection = parentFields['variantSelection'];
        if (variantSelection is Map<String, dynamic>) {
          selectedVariant = variantSelection[variantSetName]?.toString();
        }
      }

      // Fall back to first variant child
      if (selectedVariant == null) {
        final String variantSetPath = '$parentPath/{$variantSetName=}';
        final dynamic variantSetSpec = specsByPath[variantSetPath];
        
        if (variantSetSpec != null && variantSetSpec['fields'] is Map<String, dynamic>) {
          final Map<String, dynamic> vSetFields = variantSetSpec['fields'] as Map<String, dynamic>;
          final dynamic vChildren = vSetFields['variantChildren'];
          if (vChildren is List && vChildren.isNotEmpty) {
            selectedVariant = vChildren.first.toString();
          }
        }
      }

      if (selectedVariant != null) {
        final String variantPath = '$parentPath/{$variantSetName=$selectedVariant}';
        variantPaths.add(variantPath);
      }
    }

    return variantPaths;
  }

  /// Resolve a file path relative to basePath.
  String _resolveFilePath(String refPath) {
    String cleanPath = refPath;
    
    // Remove ./ prefix
    if (cleanPath.startsWith('./')) {
      cleanPath = cleanPath.substring(2);
    }
    
    if (basePath.isEmpty) return cleanPath;

    // LoaderUtils.resolveURL expects basePath to end with a separator;
    // the USDZ flow passes the zip-internal directory name without one.
    final String base = basePath.endsWith('/') ? basePath : '$basePath/';
    
    return LoaderUtils.resolveURL(cleanPath, base);
  }

  /// Resolve a USD reference and return the composed content.
  /// [refValue] - Reference value like "@./path/to/file.usdc@"
  /// [localVariants] - Variant selections to apply
  /// Returns [Group] composed content or null
  Group? _resolveReference(String? refValue, [Map<String, dynamic> localVariants = const {}]) {
    if (refValue == null || refValue.isEmpty) return null;

    // Regular expression matching @path@<prim> structure layout
    final RegExp regex = RegExp(r'@([^@]+)@(?:<([^>]+)>)?');
    final RegExpMatch? match = regex.firstMatch(refValue);
    if (match == null) return null;

    final String filePath = match.group(1) ?? '';
    final String? primPath = match.group(2); // e.g., "/Geometry"
    
    final String resolvedPath = _resolveFilePath(filePath);

    // Merge variant selections - external takes priority, then local
    final Map<String, dynamic> mergedVariants = {...localVariants, ...externalVariantSelections};

    // Look up pre-parsed data in assets portfolio maps
    final dynamic referencedData = assets[resolvedPath];
    if (referencedData == null) return null;

    // If it's specsByPath data, compose it using a unified USDComposer instance
    if (referencedData is Map && referencedData.containsKey('specsByPath')) {
      // Cast safely to keep compiler context happy
      final Map<String, dynamic> parsedMap = Map<String, dynamic>.from(referencedData);
      
      // Assuming 'manager' variable layout is declared at your parent class structure level
      final USDComposer composer = USDComposer(manager);
      final String newBasePath = _getBasePath(resolvedPath);
      
      final Group composedGroup = composer.compose(parsedMap, assets: assets, variantSelections: mergedVariants, basePath: newBasePath);

      // If a primPath is specified, find and return just that subtree
      if (primPath != null && primPath.isNotEmpty) {
        final String? primName = primPath.split('/').lastOrNull;

        if (primName != null && primName.isNotEmpty) {
          // Find the direct child with this name (not a deep search)
          // This is important because there may be multiple objects with the same name
          Object3D? targetObject;
          for (final Object3D child in composedGroup.children) {
            if (child.name == primName) {
              targetObject = child;
              break;
            }
          }

          if (targetObject != null) {
            // Detach from parent for re-parenting operations safely
            composedGroup.remove(targetObject);

            // Wrap in a group to maintain consistent return type
            final Group wrapper = Group();
            wrapper.add(targetObject);
            return wrapper;
          }
        }
      }
      
      return composedGroup;
    }

    // If it's already a Three.js Group (legacy port asset fallback tracking support), clone it
    if (referencedData is Object3D) {
      // native clone operation provided out-of-the-box by three_js_core
      return referencedData.clone(true) as Group?;
    }

    return null;
  }

  /// Find a single mesh in the group's shallow hierarchy.
  /// Only returns a mesh if it's at depth 0 or 1, not deeply nested.
  /// This preserves transforms in complex hierarchies like Kitchen Set
  /// while supporting USDZExporter round-trip (Xform > Xform > Mesh pattern).
  Mesh? _findSingleMesh(Object3D group) {
    // Check direct children first using a traditional index loop
    // to avoid concurrent modification issues while calling group.remove()
    for (int i = 0; i < group.children.length; i++) {
      final Object3D child = group.children[i];
      if (child is Mesh) {
        group.remove(child);
        return child;
      }
    }

    // Check grandchildren (USDZExporter pattern: Xform > Geometry > Mesh)
    // Only if there's exactly one child with exactly one grandchild
    if (group.children.length == 1) {
      final Object3D child = group.children.first;
      
      if (child.children.length == 1) {
        final Object3D grandchild = child.children.first;
        
        // Type verify the grandchild is a Mesh and the parent node has identity transform
        if (grandchild is Mesh && !_hasNonIdentityTransform(child)) {
          // Safe to merge - intermediate has identity transform
          child.remove(grandchild);
          return grandchild;
        }
      }
    }

    return null;
  }

  /// Check if an object has a non-identity local transform.
  bool _hasNonIdentityTransform(Object3D obj) {
    final Vector3 pos = obj.position;
    
    // In three_js_math, obj.rotation can be an Euler or Vector3 instance.
    // Both expose standard x, y, z coordinate fields.
    final dynamic rot = obj.rotation;
    final Vector3 scale = obj.scale;

    final bool hasPosition = pos.x != 0.0 || pos.y != 0.0 || pos.z != 0.0;
    final bool hasRotation = rot.x != 0.0 || rot.y != 0.0 || rot.z != 0.0;
    final bool hasScale = scale.x != 1.0 || scale.y != 1.0 || scale.z != 1.0;

    return hasPosition || hasRotation || hasScale;
  }

  /// Get the base path (directory) from a file path.
  String _getBasePath(String filePath) {
    final int lastSlash = filePath.lastIndexOf('/');
    return lastSlash >= 0 ? filePath.substring(0, lastSlash) : '';
  }

  /// Extract variant selections from a spec's fields.
  Map<String, String> _getLocalVariantSelections(Map<String, dynamic> fields) {
    final Map<String, String> variants = {};
    final dynamic variantSelection = fields['variantSelection'];

    if (variantSelection is Map<String, dynamic>) {
      for (final String key in variantSelection.keys) {
        variants[key] = variantSelection[key].toString();
      }
    }

    return variants;
  }

  /// Get all reference values from a prim spec.
  /// Returns an array of reference strings like "@path@" or "@path@<prim>"
  List<String> _getReferences(Map<String, dynamic> spec) {
    final List<String> results = [];
    final dynamic fields = spec['fields'];
    if (fields == null || fields is! Map<String, dynamic>) return results;

    final dynamic referencesRaw = fields['references'];
    if (referencesRaw is List && referencesRaw.isNotEmpty) {
      final dynamic ref = referencesRaw.first;

      if (ref is String) {
        // Extract all @...@ references (handles both single and array values)
        final RegExp regex = RegExp(r'@([^@]+)@(?:<([^>]+)>)?');
        final Iterable<RegExpMatch> matches = regex.allMatches(ref);
        
        for (final RegExpMatch match in matches) {
          // match.group(0) extracts the full matching string pattern
          final String? fullMatch = match.group(0);
          if (fullMatch != null) {
            results.add(fullMatch);
          }
        }
      } else if (ref is Map && ref.containsKey('assetPath')) {
        results.add('@${ref['assetPath']}@');
      }
    }

    if (results.isEmpty && fields.containsKey('payload')) {
      final dynamic payload = fields['payload'];
      if (payload is String) {
        results.add(payload);
      } else if (payload is Map && payload.containsKey('assetPath')) {
        results.add('@${payload['assetPath']}@');
      }
    }

    return results;
  }

  /// Get attributes for a path from attribute specs.
  Map<String, dynamic> _getAttributes(String path) {
    final Map<String, dynamic> attrs = {};
    _collectAttributesFromPath(path, attrs);

    // Collect overrides from sibling variants (when path is inside a variant)
    // Uses the globally pre-compiled RegExp variantPathRegex we defined earlier
    final RegExpMatch? variantMatch = variantPathRegex.firstMatch(path);

    if (variantMatch != null) {
      final String basePath = variantMatch.group(1) ?? '';
      final String relativePath = variantMatch.group(4) ?? '';
      final List<String> variantPaths = _getVariantPaths(basePath);

      for (final String vp in variantPaths) {
        if (path.startsWith(vp)) continue;
        final String overridePath = '$vp/$relativePath';
        _collectAttributesFromPath(overridePath, attrs);
      }
    } else {
      // Check for variant overrides at ancestor levels
      final List<String> parts = path.split('/');
      
      // Equivalent to the JavaScript loop boundaries
      for (int i = 1; i < parts.length - 1; i++) {
        final String ancestorPath = parts.sublist(0, i + 1).join('/');
        final String relativePath = parts.sublist(i + 1).join('/');
        final List<String> variantPaths = _getVariantPaths(ancestorPath);

        for (final String vp in variantPaths) {
          final String overridePath = '$vp/$relativePath';
          _collectAttributesFromPath(overridePath, attrs);
        }
      }
    }

    return attrs;
  }

  void _collectAttributesFromPath(String path, Map<String, dynamic> attrs) {
    // Use the attribute index for O(1) lookup instead of O(n) iteration
    // Map schema matching our prior indexes: Map<String, Map<String, dynamic>> attributesByPrimPath
    final Map<String, dynamic>? attrMap = attributesByPrimPath[path];
    if (attrMap == null) return;

    for (final String attrName in attrMap.keys) {
      final dynamic attrSpec = attrMap[attrName];
      if (attrSpec == null || attrSpec['fields'] is! Map<String, dynamic>) continue;

      final Map<String, dynamic> fields = attrSpec['fields'] as Map<String, dynamic>;

      if (fields.containsKey('default') && fields['default'] != null) {
        attrs[attrName] = fields['default'];
      } else if (fields.containsKey('timeSamples') && fields['timeSamples'] is Map<String, dynamic>) {
        // For animated attributes without default, use the first time sample (rest pose)
        final Map<String, dynamic> timeSamples = fields['timeSamples'] as Map<String, dynamic>;
        final dynamic times = timeSamples['times'];
        final dynamic values = timeSamples['values'];

        if (times is List && values is List && times.isNotEmpty) {
          // Find time 0, or use the first available time
          final int idx = times.indexOf(0.0); // Assuming times are doubles
          attrs[attrName] = idx >= 0 ? values[idx] : values.first;
        }
      }

      if (fields.containsKey('elementSize') && fields['elementSize'] != null) {
        attrs['$attrName:elementSize'] = fields['elementSize'];
      }

      if (attrName.startsWith('primvars:') && fields.containsKey('typeName') && fields['typeName'] != null) {
        attrs['$attrName:typeName'] = fields['typeName'];
      }
    }
  }

  /// Build a mesh from a USD geometric primitive (Cube, Sphere, Cylinder, Cone, Capsule).
  Mesh? _buildGeomPrimitive(String path, dynamic spec, String typeName) {
    final Map<String, dynamic> attrs = _getAttributes(path);
    final String name = path.split('/').lastOrNull ?? '';
    
    BufferGeometry? geometry;

    if (typeName == 'Cube') {
      final double size = (attrs['size'] as num?)?.toDouble() ?? 2.0;
      geometry = BoxGeometry(size, size, size);
    } else if (typeName == 'Sphere') {
      final double radius = (attrs['radius'] as num?)?.toDouble() ?? 1.0;
      geometry = SphereGeometry(radius, 32, 16);
    } else if (typeName == 'Cylinder') {
      final double height = (attrs['height'] as num?)?.toDouble() ?? 2.0;
      final double radius = (attrs['radius'] as num?)?.toDouble() ?? 1.0;
      geometry = CylinderGeometry(radius, radius, height, 32);
    } else if (typeName == 'Cone') {
      final double height = (attrs['height'] as num?)?.toDouble() ?? 2.0;
      final double radius = (attrs['radius'] as num?)?.toDouble() ?? 1.0;
      geometry = ConeGeometry(radius, height, 32);
    } else if (typeName == 'Capsule') {
      final double height = (attrs['height'] as num?)?.toDouble() ?? 1.0;
      final double radius = (attrs['radius'] as num?)?.toDouble() ?? 0.5;
      geometry = CapsuleGeometry(radius: radius, length: height, capSegments: 16, radialSegments: 32);
    }

    if (geometry == null) return null;

    // USD defaults axis to "Z", Three.js uses Y
    final String axis = attrs['axis']?.toString() ?? 'Z';
    if (axis == 'X') {
      geometry.rotateZ(-math.pi / 2.0);
    } else if (axis == 'Z') {
      geometry.rotateX(math.pi / 2.0);
    }

    final Map<String, dynamic> fields = (spec['fields'] is Map<String, dynamic>)
        ? spec['fields'] as Map<String, dynamic>
        : {};

    final Material material = _buildMaterial(path, fields);
    final Mesh mesh = Mesh(geometry, material);
    
    mesh.name = name;
    applyTransform(mesh, fields, attrs);

    return mesh;
  }

  /// Build a mesh from a Mesh spec.
  Mesh? _buildMesh(String path, dynamic spec) {
    final Map<String, dynamic> attrs = _getAttributes(path);

    // Check for skinning data
    final dynamic jointIndices = attrs['primvars:skel:jointIndices'];
    final dynamic jointWeights = attrs['primvars:skel:jointWeights'];
    final bool hasSkinning = jointIndices is List &&
        jointWeights is List &&
        jointIndices.isNotEmpty &&
        jointWeights.isNotEmpty;

    // Collect GeomSubsets for multi-material support
    final List<dynamic> geomSubsets = _getGeomSubsets(path);
    
    BufferGeometry? geometry;
    dynamic material; // Can be a Material or a List<Material>

    if (geomSubsets.isNotEmpty) {
      geometry = _buildGeometryWithSubsets(attrs, geomSubsets, hasSkinning);
      final String? meshMaterialPath = _getMaterialPath(path, spec['fields'] ?? {});
      
      material = geomSubsets.map<Material>((subset) {
        if (subset is! Map<String, dynamic>) return MeshBasicMaterial();
        final String? matPath = subset['materialPath']?.toString() ?? meshMaterialPath;
        return _buildMaterialForPath(matPath);
      }).toList();
    } else {
      geometry = _buildGeometry(path, attrs, hasSkinning);
      material = _buildMaterial(path, spec['fields'] ?? {});
    }

    //if (geometry == null) return null;

    // Apply displayColor adjustments
    final dynamic displayColor = attrs['primvars:displayColor'];
    if (displayColor is List && displayColor.length >= 3) {
      final double r = (displayColor[0] as num).toDouble();
      final double g = (displayColor[1] as num).toDouble();
      final double b = (displayColor[2] as num).toDouble();

      void applyDisplayColor(dynamic mat) {
        if (mat is Material && mat is MeshStandardMaterial) {
          // Only override if default white and no texture map is bound
          if (mat.color.red == 1.0 && mat.color.green == 1.0 && mat.color.blue == 1.0 && mat.map == null) {
            mat.color.setRGB(r, g, b, ColorSpace.srgb);
          }
        }
      }

      if (material is List) {
        for (final dynamic mat in material) {
          applyDisplayColor(mat);
        }
      } else {
        applyDisplayColor(material);
      }
    }

    // Apply displayOpacity adjustments
    final dynamic displayOpacity = attrs['primvars:displayOpacity'];
    if (displayOpacity is List && displayOpacity.length == 1 && geomSubsets.isEmpty) {
      final double opacity = (displayOpacity[0] as num).toDouble();

      void applyDisplayOpacity(dynamic mat) {
        if (mat is Material) {
          if (opacity < 1.0 && mat.opacity == 1.0 && mat.transparent == false) {
            mat.opacity = opacity;
            mat.transparent = true;
          }
        }
      }

      if (material is List) {
        for (final dynamic mat in material) {
          applyDisplayOpacity(mat);
        }
      } else {
        applyDisplayOpacity(material);
      }
    }

    Mesh mesh;

    if (hasSkinning) {
      mesh = SkinnedMesh(geometry, material);

      // Find skeleton path from skel:skeleton relationship
      dynamic skelBindingSpec = specsByPath['$path.skel:skeleton'];
      if (skelBindingSpec == null) {
        skelBindingSpec = specsByPath['$path.rel skel:skeleton'];
      }

      String? skeletonPath;
      if (skelBindingSpec != null && skelBindingSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> bFields = skelBindingSpec['fields'] as Map<String, dynamic>;
        final dynamic targetPaths = bFields['targetPaths'];
        
        if (targetPaths is List && targetPaths.isNotEmpty) {
          skeletonPath = targetPaths.first.toString();
        } else if (bFields['default'] != null) {
          skeletonPath = bFields['default'].toString().replaceAll(RegExp(r'<|>'), '');
        }
      }

      // Get per-mesh joint mapping and geomBindTransform
      final dynamic localJoints = attrs['skel:joints'];
      final dynamic geomBindTransform = attrs['primvars:skel:geomBindTransform'];

      // Assuming skinnedMeshes is pre-declared as List<Map<String, dynamic>> at class level
      skinnedMeshes.add({
        'mesh': mesh,
        'skeletonPath': skeletonPath,
        'path': path,
        'localJoints': localJoints,
        'geomBindTransform': geomBindTransform,
      });
    } else {
      mesh = Mesh(geometry, material);
    }

    mesh.name = path.split('/').lastOrNull ?? '';
    
    final Map<String, dynamic> fields = (spec['fields'] is Map<String, dynamic>)
        ? spec['fields'] as Map<String, dynamic>
        : {};
        
    applyTransform(mesh, fields, attrs);

    return mesh;
  }

  /// Build a camera from a Camera spec using three_js_core classes.
  Camera _buildCamera(String path) {
    final Map<String, dynamic> attrs = _getAttributes(path);
    
    // A tiny epsilon value fallback to mirror JS Number.EPSILON behavior
    const double epsilon = 1e-15;

    // Resolve camera configurations using your usdCameraDefaults map values
    final dynamic projectionToken = attrs['projection'];
    final String projection = projectionToken is String 
        ? projectionToken.toLowerCase() 
        : usdCameraDefaults['projection'].toString();

    final dynamic clippingRangeRaw = attrs['clippingRange'];
    final List<dynamic> clippingRange = clippingRangeRaw is List 
        ? clippingRangeRaw 
        : (usdCameraDefaults['clippingRange'] as List);

    final double near = math.max(
      epsilon,
      _parseNumber(clippingRange[0], (usdCameraDefaults['clippingRange'] as List)[0]),
    );
    
    final double far = math.max(
      near + epsilon,
      _parseNumber(clippingRange[1], (usdCameraDefaults['clippingRange'] as List)[1]),
    );

    final double horizontalAperture = _parseNumber(
      attrs['horizontalAperture'], 
      usdCameraDefaults['horizontalAperture'],
    );
    
    final double verticalAperture = _parseNumber(
      attrs['verticalAperture'], 
      usdCameraDefaults['verticalAperture'],
    );
    
    final double horizontalApertureOffset = _parseNumber(
      attrs['horizontalApertureOffset'], 
      usdCameraDefaults['horizontalApertureOffset'],
    );
    
    final double verticalApertureOffset = _parseNumber(
      attrs['verticalApertureOffset'], 
      usdCameraDefaults['verticalApertureOffset'],
    );
    
    final double focalLength = _parseNumber(
      attrs['focalLength'], 
      usdCameraDefaults['focalLength'],
    );
    
    final double focusDistance = _parseNumber(
      attrs['focusDistance'], 
      usdCameraDefaults['focusDistance'],
    );
    
    final double fStop = _parseNumber(
      attrs['fStop'], 
      usdCameraDefaults['fStop'],
    );

    Camera camera;

    if (projection == 'orthographic') {
      // USD orthographic apertures are in tenths of a world unit.
      final double width = horizontalAperture / 10.0;
      final double height = verticalAperture / 10.0;
      final double offsetX = horizontalApertureOffset / 10.0;
      final double offsetY = verticalApertureOffset / 10.0;

      camera = OrthographicCamera(
        offsetX - width * 0.5,
        offsetX + width * 0.5,
        offsetY + height * 0.5,
        offsetY - height * 0.5,
        near,
        far,
      );
    } else {
      final double safeVerticalAperture = math.max(epsilon, verticalAperture);
      final double safeFocalLength = math.max(epsilon, focalLength);
      final double aspect = horizontalAperture / safeVerticalAperture;
      
      // Field of view calculation using native trig functions
      final double fov = 2.0 * math.atan(safeVerticalAperture / (2.0 * safeFocalLength)) * 180.0 / math.pi;

      final PerspectiveCamera pCamera = PerspectiveCamera(fov, aspect, near, far);
      pCamera.filmGauge = math.max(horizontalAperture, verticalAperture);
      pCamera.filmOffset = horizontalApertureOffset;
      pCamera.focus = focusDistance;
      pCamera.setFocalLength(safeFocalLength);

      if (verticalApertureOffset != 0.0) {
        // Three.js supports only horizontal film offset directly.
        pCamera.userData['verticalApertureOffset'] = verticalApertureOffset;
      }
      
      camera = pCamera;
    }

    camera.userData['fStop'] = fStop;
    camera.userData['usdProjection'] = projection;

    return camera;
  }

  /// Build a light from a UsdLux light spec using pub.dev three_js packages.
  Light? _buildLight(String path, String typeName) {
    final Map<String, dynamic> attrs = _getAttributes(path);
    
    final double intensity = _parseNumber(attrs['inputs:intensity'], 1.0);
    
    final dynamic baseColorRaw = attrs['inputs:color'];
    final List<dynamic> baseColor = baseColorRaw is List ? baseColorRaw : [1.0, 1.0, 1.0];
    
    final bool enableColorTemperature = attrs['inputs:enableColorTemperature'] == true;
    final double colorTemperature = _parseNumber(attrs['inputs:colorTemperature'], 6500.0);

    final Color color = Color(
      (baseColor[0] as num).toDouble(),
      (baseColor[1] as num).toDouble(),
      (baseColor[2] as num).toDouble(),
    );

    if (enableColorTemperature) {
      final Color temp = _colorTemperature(colorTemperature);
      color.multiply(temp);
    }

    Light? light;

    if (typeName == 'DistantLight') {
      light = DirectionalLight(color.getHex(), intensity);
    } else if (typeName == 'SphereLight') {
      final double coneAngle = _parseNumber(attrs['shaping:cone:angle'], 0.0);
      
      if (coneAngle > 0.0) {
        final double angle = coneAngle * math.pi / 180.0;
        final double softness = _parseNumber(attrs['shaping:cone:softness'], 0.0);
        
        // SpotLight signature: Color, intensity, distance, angle, penumbra, decay
        light = SpotLight(color.getHex(), intensity, 0.0, angle, softness);
      } else {
        light = PointLight(color.getHex(), intensity);
      }
    } else if (typeName == 'RectLight') {
      final double width = _parseNumber(attrs['inputs:width'], 1.0);
      final double height = _parseNumber(attrs['inputs:height'], 1.0);
      
      light = RectAreaLight(color.getHex(), intensity, width, height);
    } else if (typeName == 'DiskLight') {
      final double radius = _parseNumber(attrs['inputs:radius'], 0.5);
      final double side = radius * 2.0;
      
      light = RectAreaLight(color.getHex(), intensity, side, side);
    }

    return light;
  }

  /// Convert a color temperature in Kelvin to an RGB Color.
  /// Based on Tanner Helland's algorithm.
  Color _colorTemperature(double kelvin) {
    final double temp = kelvin / 100.0;
    double r = 0.0;
    double g = 0.0;
    double b = 0.0;

    if (temp <= 66.0) {
      r = 1.0;
      g = 0.3900815787690196 * math.log(temp) - 0.6318414437886275;
    } else {
      r = 1.292936186062745 * math.pow(temp - 60.0, -0.1332047592);
      g = 1.1298908608952941 * math.pow(temp - 60.0, -0.0755148492);
    }

    if (temp >= 66.0) {
      b = 1.0;
    } else if (temp <= 19.0) {
      b = 0.0;
    } else {
      b = 0.543206789110196 * math.log(temp - 10.0) - 1.19625408914;
    }

    final double finalR = math.min(math.max(r, 0.0), 1.0);
    final double finalG = math.min(math.max(g, 0.0), 1.0);
    final double finalB = math.min(math.max(b, 0.0), 1.0);

    return Color(finalR, finalG, finalB);
  }

  /// Safely parse a dynamic value into a valid double value with a fallback parameter.
  double _parseNumber(dynamic value, double fallback) {
    if (value == null) return fallback;
    
    if (value is num) {
      final double n = value.toDouble();
      return n.isFinite ? n : fallback;
    }
    
    final double? n = double.tryParse(value.toString());
    if (n != null && n.isFinite) {
      return n;
    }
    
    return fallback;
  }

  /// Retrieve the GeomSubsets for multi-material support out of pre-indexed cache maps.
  List<Map<String, dynamic>> _getGeomSubsets(String meshPath) {
    final List<Map<String, dynamic>> subsets = [];
    
    // Index cache lookup matching prior definitions: Map<String, List<String>> geomSubsetsByMeshPath
    final List<String>? subsetPaths = geomSubsetsByMeshPath[meshPath];
    if (subsetPaths == null) return subsets;

    for (final String p in subsetPaths) {
      final Map<String, dynamic> attrs = _getAttributes(p);
      final dynamic indicesRaw = attrs['indices'];
      
      if (indicesRaw is! List || indicesRaw.isEmpty) continue;

      // Get material binding - check direct path and variant paths
      final String? materialPath = _getMaterialBindingTarget(p);

      subsets.add({
        'name': p.split('/').lastOrNull ?? '',
        'indices': indicesRaw,
        'materialPath': materialPath,
      });
    }

    return subsets;
  }

  /// Get material binding target path, checking variant paths if needed.
  String? _getMaterialBindingTarget(String primPath) {
    const String attrName = 'material:binding';

    // First check direct path
    final String directPath = '$primPath.$attrName';
    final dynamic directSpec = specsByPath[directPath];

    if (directSpec != null && directSpec['fields'] is Map<String, dynamic>) {
      final Map<String, dynamic> dFields = directSpec['fields'] as Map<String, dynamic>;
      final dynamic dTargetPaths = dFields['targetPaths'];
      if (dTargetPaths is List && dTargetPaths.isNotEmpty) {
        return dTargetPaths.first.toString();
      }
    }

    // Check variant paths at ancestor levels
    final List<String> parts = primPath.split('/');
    for (int i = 1; i < parts.length; i++) {
      final String ancestorPath = parts.sublist(0, i + 1).join('/');
      final String relativePath = parts.sublist(i + 1).join('/');
      
      final List<String> variantPaths = _getVariantPaths(ancestorPath);
      for (final String vp in variantPaths) {
        final String overridePath = relativePath.isNotEmpty 
            ? '$vp/$relativePath.$attrName' 
            : '$vp.$attrName';
            
        final dynamic overrideSpec = specsByPath[overridePath];
        if (overrideSpec != null && overrideSpec['fields'] is Map<String, dynamic>) {
          final Map<String, dynamic> oFields = overrideSpec['fields'] as Map<String, dynamic>;
          final dynamic oTargetPaths = oFields['targetPaths'];
          if (oTargetPaths is List && oTargetPaths.isNotEmpty) {
            return oTargetPaths.first.toString();
          }
        }
      }
    }

    return null;
  }

  /// Build a mesh from a Mesh spec using three_js_core classes.
  BufferGeometry _buildGeometry(String path, Map<String, dynamic> fields, [bool hasSkinning = false]) {
    final BufferGeometry geometry = BufferGeometry();
    
    final dynamic pointsRaw = fields['points'];
    if (pointsRaw is! List || pointsRaw.isEmpty) return geometry;
    
    // Safely cast or parse incoming points list as a flat double sequence
    final List<double> points = List<double>.from(pointsRaw.map((v) => (v as num).toDouble()));

    final dynamic faceVertexIndicesRaw = fields['faceVertexIndices'];
    final List<int> faceVertexIndices = faceVertexIndicesRaw is List 
        ? List<int>.from(faceVertexIndicesRaw.map((v) => (v as num).toInt()))
        : [];

    final dynamic faceVertexCountsRaw = fields['faceVertexCounts'];
    final List<int> faceVertexCounts = faceVertexCountsRaw is List 
        ? List<int>.from(faceVertexCountsRaw.map((v) => (v as num).toInt()))
        : [];

    // Parse polygon holes (Arnold format: [holeFaceIdx, parentFaceIdx, ...])
    final dynamic polygonHoles = fields['primvars:arnold:polygon_holes'];
    final Map<String,dynamic> holeMap = _buildHoleMap(polygonHoles);

    // Compute triangulation pattern once using actual vertex positions
    // This pattern will be reused for normals, UVs, etc.
    List<int> indices = faceVertexIndices;
    List<int>? triPattern;

    if (faceVertexCounts.isNotEmpty) {
      final dynamic result = _triangulateIndicesWithPattern(faceVertexIndices, faceVertexCounts, points, holeMap);
      if (result is Map) {
        indices = List<int>.from(result['indices']);
        triPattern = List<int>.from(result['pattern']);
      }
    }

    List<double> positions = points;
    if (indices.isNotEmpty) {
      positions = _expandAttribute(points, indices, 3);
    }

    geometry.setAttributeFromString('position', Float32BufferAttribute(Float32List.fromList(positions), 3));

    // Process Normals
    final dynamic normalsRaw = fields['normals'] ?? fields['primvars:normals'];
    final dynamic normalIndicesRaw = fields['normals:indices'] ?? fields['primvars:normals:indices'];

    if (normalsRaw is List && normalsRaw.isNotEmpty) {
      final List<double> normals = List<double>.from(normalsRaw.map((v) => (v as num).toDouble()));
      List<double> normalData = normals;

      if (normalIndicesRaw is List && normalIndicesRaw.isNotEmpty && triPattern != null) {
        final List<int> rawNormIndices = List<int>.from(normalIndicesRaw.map((v) => (v as num).toInt()));
        // Indexed normals - apply triangulation pattern to indices
        final List<int> triangulatedNormalIndices = _applyTriangulationPattern(rawNormIndices, triPattern);
        normalData = _expandAttribute(normals, triangulatedNormalIndices, 3);
      } else if (normals.length == points.length) {
        // Per-vertex normals
        if (indices.isNotEmpty) {
          normalData = _expandAttribute(normals, indices, 3);
        }
      } else if (triPattern != null) {
        // Per-face-vertex normals (no separate indices) - use same triangulation pattern
        final List<int> computedNormalIndices = List<int>.generate(normals.length ~/ 3, (i) => i);
        final List<int> triangulatedNormalIndices = _applyTriangulationPattern(computedNormalIndices, triPattern);
        normalData = _expandAttribute(normals, triangulatedNormalIndices, 3);
      }
      
      geometry.setAttributeFromString('normal', Float32BufferAttribute(Float32List.fromList(normalData), 3));
    } else {
      // Compute vertex normals from the original indexed topology where vertices are shared
      final List<double> vertexNormals = _computeVertexNormals(points, indices);
      final List<double> expandedNormals = _expandAttribute(vertexNormals, indices, 3);
      geometry.setAttributeFromString('normal', Float32BufferAttribute(Float32List.fromList(expandedNormals), 3));
    }

    // Process UV1 (st)
    final dynamic uvResult = _findUVPrimvar(fields);
    final dynamic uvsRaw = uvResult['uvs'];
    final dynamic uvIndicesRaw = uvResult['uvIndices'];
    final int numFaceVertices = faceVertexIndices.length;

    if (uvsRaw is List && uvsRaw.isNotEmpty) {
      final List<double> uvs = List<double>.from(uvsRaw.map((v) => (v as num).toDouble()));
      List<double> uvData = uvs;

      if (uvIndicesRaw is List && uvIndicesRaw.isNotEmpty && triPattern != null) {
        final List<int> rawUvIndices = List<int>.from(uvIndicesRaw.map((v) => (v as num).toInt()));
        final List<int> triangulatedUvIndices = _applyTriangulationPattern(rawUvIndices, triPattern);
        uvData = _expandAttribute(uvs, triangulatedUvIndices, 2);
      } else if (indices.isNotEmpty && (uvs.length ~/ 2) == (points.length ~/ 3)) {
        uvData = _expandAttribute(uvs, indices, 2);
      } else if (triPattern != null && (uvs.length ~/ 2) == numFaceVertices) {
        // Per-face-vertex UVs (faceVarying, no separate indices)
        final List<int> computedUvIndices = List<int>.generate(numFaceVertices, (i) => i);
        final List<int> uvIndicesFromPattern = _applyTriangulationPattern(computedUvIndices, triPattern);
        uvData = _expandAttribute(uvs, uvIndicesFromPattern, 2);
      }
      
      geometry.setAttributeFromString('uv', Float32BufferAttribute(Float32List.fromList(uvData), 2));
    }

    // Process UV2 (st1) for lightmaps/AO
    final dynamic uv2Result = _findUV2Primvar(fields);
    final dynamic uvs2Raw = uv2Result['uvs2'];
    final dynamic uv2IndicesRaw = uv2Result['uv2Indices'];

    if (uvs2Raw is List && uvs2Raw.isNotEmpty) {
      final List<double> uvs2 = List<double>.from(uvs2Raw.map((v) => (v as num).toDouble()));
      List<double> uv2Data = uvs2;

      if (uv2IndicesRaw is List && uv2IndicesRaw.isNotEmpty && triPattern != null) {
        final List<int> rawUv2Indices = List<int>.from(uv2IndicesRaw.map((v) => (v as num).toInt()));
        final List<int> triangulatedUv2Indices = _applyTriangulationPattern(rawUv2Indices, triPattern);
        uv2Data = _expandAttribute(uvs2, triangulatedUv2Indices, 2);
      } else if (indices.isNotEmpty && (uvs2.length ~/ 2) == (points.length ~/ 3)) {
        uv2Data = _expandAttribute(uvs2, indices, 2);
      } else if (triPattern != null && (uvs2.length ~/ 2) == numFaceVertices) {
        // Per-face-vertex UV2 (faceVarying, no separate indices)
        final List<int> computedUv2Indices = List<int>.generate(numFaceVertices, (i) => i);
        final List<int> uv2IndicesFromPattern = _applyTriangulationPattern(computedUv2Indices, triPattern);
        uv2Data = _expandAttribute(uvs2, uv2IndicesFromPattern, 2);
      }
      
      geometry.setAttributeFromString('uv1', Float32BufferAttribute(Float32List.fromList(uv2Data), 2));
    }

    // Add skinning attributes if applicable
    if (hasSkinning) {
      final dynamic jointIndicesRaw = fields['primvars:skel:jointIndices'];
      final dynamic jointWeightsRaw = fields['primvars:skel:jointWeights'];
      final int elementSize = (fields['primvars:skel:jointIndices:elementSize'] as num?)?.toInt() ?? 4;

      if (jointIndicesRaw is List && jointWeightsRaw is List) {
        final List<int> jointIndices = List<int>.from(jointIndicesRaw.map((v) => (v as num).toInt()));
        final List<double> jointWeights = List<double>.from(jointWeightsRaw.map((v) => (v as num).toDouble()));
        
        final int numVertices = positions.length ~/ 3;
        List<int> skinIndexData;
        List<double> skinWeightData;

        if (indices.isNotEmpty) {
          skinIndexData = _expandAttributeInt(jointIndices, indices, elementSize);
          skinWeightData = _expandAttribute(jointWeights, indices, elementSize);
        } else {
          skinIndexData = jointIndices;
          skinWeightData = jointWeights;
        }

        final Uint16List skinIndices = Uint16List(numVertices * 4);
        final Float32List skinWeights = Float32List(numVertices * 4);

        _selectTopWeights(skinIndexData, skinWeightData, elementSize, numVertices, skinIndices, skinWeights);

        geometry.setAttributeFromString('skinIndex', Uint16BufferAttribute(skinIndices, 4));
        geometry.setAttributeFromString('skinWeight', Float32BufferAttribute(skinWeights, 4));
      }
    }

    return geometry;
  }

  /// Build a multi-material mesh using GeomSubsets using three_js_core buffers.
  BufferGeometry _buildGeometryWithSubsets(
    Map<String, dynamic> fields, 
    List<dynamic> geomSubsets, 
    [bool hasSkinning = false]
  ) {
    final BufferGeometry geometry = BufferGeometry();

    final dynamic pointsRaw = fields['points'];
    if (pointsRaw is! List || pointsRaw.isEmpty) return geometry;
    final List<double> points = List<double>.from(pointsRaw.map((v) => (v as num).toDouble()));

    final dynamic faceVertexIndicesRaw = fields['faceVertexIndices'];
    final List<int> faceVertexIndices = faceVertexIndicesRaw is List 
        ? List<int>.from(faceVertexIndicesRaw.map((v) => (v as num).toInt()))
        : [];

    final dynamic faceVertexCountsRaw = fields['faceVertexCounts'];
    if (faceVertexCountsRaw is! List || faceVertexCountsRaw.isEmpty) return geometry;
    final List<int> faceVertexCounts = List<int>.from(faceVertexCountsRaw.map((v) => (v as num).toInt()));

    // Parse polygon holes (Arnold format)
    final dynamic polygonHoles = fields['primvars:arnold:polygon_holes'];
    final dynamic holeMap = _buildHoleMap(polygonHoles);
    final Set<int> holeFaces = holeMap['holeFaces'] as Set<int>? ?? {};
    final Map<int, List<int>> parentToHoles = holeMap['parentToHoles'] as Map<int, List<int>>? ?? {};

    final dynamic uvResult = _findUVPrimvar(fields);
    final dynamic uvsRaw = uvResult['uvs'];
    final dynamic uvIndicesRaw = uvResult['uvIndices'];
    final List<double>? uvs = uvsRaw is List ? List<double>.from(uvsRaw.map((v) => (v as num).toDouble())) : null;

    final dynamic uv2Result = _findUV2Primvar(fields);
    final dynamic uvs2Raw = uv2Result['uvs2'];
    final dynamic uv2IndicesRaw = uv2Result['uv2Indices'];
    final List<double>? uvs2 = uvs2Raw is List ? List<double>.from(uvs2Raw.map((v) => (v as num).toDouble())) : null;

    final dynamic normalsRaw = fields['normals'] ?? fields['primvars:normals'];
    final List<double>? normals = normalsRaw is List ? List<double>.from(normalsRaw.map((v) => (v as num).toDouble())) : null;
    final dynamic normalIndicesRaw = fields['normals:indices'] ?? fields['primvars:normals:indices'];

    final dynamic jointIndicesRaw = hasSkinning ? fields['primvars:skel:jointIndices'] : null;
    final List<int>? jointIndices = jointIndicesRaw is List ? List<int>.from(jointIndicesRaw.map((v) => (v as num).toInt())) : null;
    
    final dynamic jointWeightsRaw = hasSkinning ? fields['primvars:skel:jointWeights'] : null;
    final List<double>? jointWeights = jointWeightsRaw is List ? List<double>.from(jointWeightsRaw.map((v) => (v as num).toDouble())) : null;
    
    final int elementSize = (fields['primvars:skel:jointIndices:elementSize'] as num?)?.toInt() ?? 4;

    // Build face-to-triangle mapping (accounting for holes)
    final List<int> faceTriangleOffset = [];
    int triangleCount = 0;

    for (int i = 0; i < faceVertexCounts.length; i++) {
      faceTriangleOffset.add(triangleCount);
      // Skip hole faces - they are triangulated with their parent
      if (holeFaces.contains(i)) continue;

      final int count = faceVertexCounts[i];
      final List<int>? holes = parentToHoles[i];

      if (holes != null && holes.isNotEmpty) {
        int totalVerts = count;
        for (final int holeIdx in holes) {
          totalVerts += faceVertexCounts[holeIdx];
        }
        triangleCount += totalVerts - 2;
      } else if (count >= 3) {
        triangleCount += count - 2;
      }
    }

    final Int32List triangleToSubset = Int32List(triangleCount)..fillRange(0, triangleCount, -1);

    for (int si = 0; si < geomSubsets.length; si++) {
      final dynamic subset = geomSubsets[si];
      if (subset is! Map || subset['indices'] is! List) continue;
      final List<dynamic> sIndices = subset['indices'] as List;

      for (int i = 0; i < sIndices.length; i++) {
        final int faceIdx = (sIndices[i] as num).toInt();
        if (faceIdx >= faceVertexCounts.length) continue;

        final int triStart = faceTriangleOffset[faceIdx];
        final int triCount = faceVertexCounts[faceIdx] - 2;
        for (int t = 0; t < triCount; t++) {
          if (triStart + t < triangleCount) {
            triangleToSubset[triStart + t] = si;
          }
        }
      }
    }

    // Sort triangles by subset
    final List<Map<String, int>> sortedTriangles = [];
    for (int tri = 0; tri < triangleCount; tri++) {
      sortedTriangles.add({'original': tri, 'subset': triangleToSubset[tri]});
    }
    sortedTriangles.sort((a, b) => (a['subset'] ?? 0).compareTo(b['subset'] ?? 0));

    final List<Map<String, int>> groups = [];
    int currentSubset = sortedTriangles.isNotEmpty ? (sortedTriangles.first['subset'] ?? -1) : -1;
    int groupStart = 0;

    for (int i = 0; i < sortedTriangles.length; i++) {
      if (sortedTriangles[i]['subset'] != currentSubset) {
        if (currentSubset >= 0) {
          groups.add({'start': groupStart * 3, 'count': (i - groupStart) * 3, 'materialIndex': currentSubset});
        }
        currentSubset = sortedTriangles[i]['subset'] ?? -1;
        groupStart = i;
      }
    }

    if (currentSubset >= 0 && sortedTriangles.length > groupStart) {
      groups.add({'start': groupStart * 3, 'count': (sortedTriangles.length - groupStart) * 3, 'materialIndex': currentSubset});
    }

    for (final Map<String, int> group in groups) {
      geometry.addGroup(group['start']!, group['count']!, group['materialIndex']!);
    }

    // Triangulate original data using consistent pattern
    final dynamic triResult = _triangulateIndicesWithPattern(faceVertexIndices, faceVertexCounts, points, holeMap);
    final List<int> origIndices = List<int>.from(triResult['indices']);
    final List<int> triPattern = List<int>.from(triResult['pattern']);

    final int numFaceVertices = faceVertexCounts.fold<int>(0, (a, b) => a + b);

    final List<int>? faceVaryingIdentity = 
        (uvs != null && uvIndicesRaw == null && (uvs.length ~/ 2) == numFaceVertices) || 
        (uvs2 != null && uv2IndicesRaw == null && (uvs2.length ~/ 2) == numFaceVertices)
        ? _applyTriangulationPattern(List<int>.generate(numFaceVertices, (i) => i), triPattern)
        : null;

    final List<int>? origUvIndices = uvIndicesRaw is List
        ? _applyTriangulationPattern(List<int>.from(uvIndicesRaw.map((v) => (v as num).toInt())), triPattern)
        : ((uvs != null && (uvs.length ~/ 2) == numFaceVertices) ? faceVaryingIdentity : null);

    final List<int>? origUv2Indices = uv2IndicesRaw is List
        ? _applyTriangulationPattern(List<int>.from(uv2IndicesRaw.map((v) => (v as num).toInt())), triPattern)
        : ((uvs2 != null && (uvs2.length ~/ 2) == numFaceVertices) ? faceVaryingIdentity : null);

    final bool hasIndexedNormals = normals != null && normalIndicesRaw is List && normalIndicesRaw .isNotEmpty;
    final bool hasFaceVaryingNormals = normals != null && (normals.length ~/ 3) == numFaceVertices;

    final List<int>? origNormalIndices = hasIndexedNormals
        ? _applyTriangulationPattern(List<int>.from(normalIndicesRaw.map((v) => (v as num).toInt())), triPattern)
        : (hasFaceVaryingNormals ? _applyTriangulationPattern(List<int>.generate(numFaceVertices, (i) => i), triPattern) : null);

    final List<double>? vertexNormals = (normals == null && origIndices.isNotEmpty) 
        ? _computeVertexNormals(points, origIndices) 
        : null;

    // Build reordered vertex data
    final int vertexCount = triangleCount * 3;
    final Float32List positions = Float32List(vertexCount * 3);
    final Float32List? uvData = uvs != null ? Float32List(vertexCount * 2) : null;
    final Float32List? uv1Data = uvs2 != null ? Float32List(vertexCount * 2) : null;
    final Float32List? normalData = (normals != null || vertexNormals != null) ? Float32List(vertexCount * 3) : null;
    
    final Uint16List? skinSrcIndices = jointIndices != null ? Uint16List(vertexCount * elementSize) : null;
    final Float32List? skinSrcWeights = jointWeights != null ? Float32List(vertexCount * elementSize) : null;

    for (int i = 0; i < sortedTriangles.length; i++) {
      final int origTri = sortedTriangles[i]['original']!;
      
      for (int v = 0; v < 3; v++) {
        final int origIdx = origTri * 3 + v;
        final int newIdx = i * 3 + v;
        final int pointIdx = origIndices[origIdx];

        positions[newIdx * 3] = points[pointIdx * 3];
        positions[newIdx * 3 + 1] = points[pointIdx * 3 + 1];
        positions[newIdx * 3 + 2] = points[pointIdx * 3 + 2];

        if (uvData != null && uvs != null) {
          if (origUvIndices != null) {
            final int uvIdx = origUvIndices[origIdx];
            uvData[newIdx * 2] = uvs[uvIdx * 2];
            uvData[newIdx * 2 + 1] = uvs[uvIdx * 2 + 1];
          } else if ((uvs.length ~/ 2) == (points.length ~/ 3)) {
            uvData[newIdx * 2] = uvs[pointIdx * 2];
            uvData[newIdx * 2 + 1] = uvs[pointIdx * 2 + 1];
          }
        }

        if (uv1Data != null && uvs2 != null) {
          if (origUv2Indices != null) {
            final int uv2Idx = origUv2Indices[origIdx];
            uv1Data[newIdx * 2] = uvs2[uv2Idx * 2];
            uv1Data[newIdx * 2 + 1] = uvs2[uv2Idx * 2 + 1];
          } else if ((uvs2.length ~/ 2) == (points.length ~/ 3)) {
            uv1Data[newIdx * 2] = uvs2[pointIdx * 2];
            uv1Data[newIdx * 2 + 1] = uvs2[pointIdx * 2 + 1];
          }
        }

        if (normalData != null) {
          if (normals != null && origNormalIndices != null) {
            final int normalIdx = origNormalIndices[origIdx];
            normalData[newIdx * 3] = normals[normalIdx * 3];
            normalData[newIdx * 3 + 1] = normals[normalIdx * 3 + 1];
            normalData[newIdx * 3 + 2] = normals[normalIdx * 3 + 2];
          } else if (normals != null && normals.length == points.length) {
            normalData[newIdx * 3] = normals[pointIdx * 3];
            normalData[newIdx * 3 + 1] = normals[pointIdx * 3 + 1];
            normalData[newIdx * 3 + 2] = normals[pointIdx * 3 + 2];
          } else if (vertexNormals != null) {
            normalData[newIdx * 3] = vertexNormals[pointIdx * 3];
            normalData[newIdx * 3 + 1] = vertexNormals[pointIdx * 3 + 1];
            normalData[newIdx * 3 + 2] = vertexNormals[pointIdx * 3 + 2];
          }
        }
        if (skinSrcIndices != null && skinSrcWeights != null && jointIndices != null && jointWeights != null) {
          for (int j = 0; j < elementSize; j++) {
            final int srcOffset = pointIdx * elementSize + j;
            skinSrcIndices[newIdx * elementSize + j] = srcOffset < jointIndices.length ? jointIndices[srcOffset] : 0;
            skinSrcWeights[newIdx * elementSize + j] = srcOffset < jointWeights.length ? jointWeights[srcOffset] : 0.0;
          }
        }
      }
    }
    geometry.setAttributeFromString('position', Float32BufferAttribute(positions, 3));
    if (uvData != null) geometry.setAttributeFromString('uv', Float32BufferAttribute(uvData, 2));
    if (uv1Data != null) geometry.setAttributeFromString('uv1', Float32BufferAttribute(uv1Data, 2));
    if (normalData != null) geometry.setAttributeFromString('normal', Float32BufferAttribute(normalData, 3));
    if (skinSrcIndices != null && skinSrcWeights != null) {
      final Uint16List skinIndexData = Uint16List(vertexCount * 4);
      final Float32List skinWeightData = Float32List(vertexCount * 4);
      _selectTopWeights(skinSrcIndices, skinSrcWeights, elementSize, vertexCount, skinIndexData, skinWeightData);
      geometry.setAttributeFromString('skinIndex', Uint16BufferAttribute(skinIndexData, 4));
      geometry.setAttributeFromString('skinWeight', Float32BufferAttribute(skinWeightData, 4));
    }
    return geometry;
  }

  /// Select top skeletal joint weights for 4-bone influence limits per vertex.
  void _selectTopWeights(
    dynamic srcIndices, // Can accept List<int>, Uint16List, etc.
    dynamic srcWeights, // Can accept List<double>, Float32List, etc.
    int elementSize,
    int numVertices,
    Uint16List dstIndices,
    Float32List dstWeights,
  ) {
    if (elementSize <= 4) {
      for (int i = 0; i < numVertices; i++) {
        for (int j = 0; j < 4; j++) {
          final int dstOffset = i * 4 + j;
          if (j < elementSize) {
            final int srcOffset = i * elementSize + j;
            dstIndices[dstOffset] = srcIndices[srcOffset] ?? 0;
            dstWeights[dstOffset] = (srcWeights[srcOffset] ?? 0.0).toDouble();
          } else {
            dstIndices[dstOffset] = 0;
            dstWeights[dstOffset] = 0.0;
          }
        }
      }
      return;
    }

    // When elementSize > 4, find the 4 largest weights per vertex
    // using a partial selection sort (4 iterations of O(elementSize)).
    final Uint32List order = Uint32List(elementSize);
    
    for (int i = 0; i < numVertices; i++) {
      final int base = i * elementSize;
      for (int j = 0; j < elementSize; j++) {
        order[j] = j;
      }

      for (int k = 0; k < 4; k++) {
        int maxIdx = k;
        double maxW = (srcWeights[base + order[k]] ?? 0.0).toDouble();

        for (int j = k + 1; j < elementSize; j++) {
          final double w = (srcWeights[base + order[j]] ?? 0.0).toDouble();
          if (w > maxW) {
            maxW = w;
            maxIdx = j;
          }
        }

        if (maxIdx != k) {
          final int tmp = order[k];
          order[k] = order[maxIdx];
          order[maxIdx] = tmp;
        }
      }

      double total = 0.0;
      for (int j = 0; j < 4; j++) {
        total += (srcWeights[base + order[j]] ?? 0.0).toDouble();
      }

      for (int j = 0; j < 4; j++) {
        final int s = order[j];
        final int dstOffset = i * 4 + j;
        if (total > 0.0) {
          dstIndices[dstOffset] = srcIndices[base + s] ?? 0;
          dstWeights[dstOffset] = (srcWeights[base + s] ?? 0.0).toDouble() / total;
        } else {
          dstIndices[dstOffset] = 0;
          dstWeights[dstOffset] = 0.0;
        }
      }
    }
  }

  /// Find the primary UV coordinates and indices from the fields.
  Map<String, dynamic> _findUVPrimvar(Map<String, dynamic> fields) {
    for (final String key in fields.keys) {
      if (!key.startsWith('primvars:')) continue;
      if (key.endsWith(':typeName') || key.endsWith(':elementSize') || key.endsWith(':indices')) continue;
      if (key.contains('skel:')) continue;

      final String? typeName = fields['$key:typeName']?.toString();
      if (typeName != null && typeName.contains('texCoord')) {
        return {
          'uvs': fields[key],
          'uvIndices': fields['$key:indices'],
        };
      }
    }

    final dynamic uvs = fields['primvars:st'] ?? fields['primvars:UVMap'];
    final dynamic uvIndices = fields['primvars:st:indices'];
    return {
      'uvs': uvs,
      'uvIndices': uvIndices,
    };
  }

  /// Find the secondary UV coordinates (e.g., st1 for lightmaps) and indices.
  Map<String, dynamic> _findUV2Primvar(Map<String, dynamic> fields) {
    final dynamic uvs2 = fields['primvars:st1'];
    final dynamic uv2Indices = fields['primvars:st1:indices'];
    return {
      'uvs2': uvs2,
      'uv2Indices': uv2Indices,
    };
  }

  /// Build a hole mapping configuration from Arnold-format polygon holes.
  /// [polygonHoles] is an interleaved list: [holeFaceIdx, parentFaceIdx, ...]
  Map<String, dynamic> _buildHoleMap(dynamic polygonHoles) {
    final Map<int, List<int>> parentToHoles = {};
    final Set<int> holeFaces = {};

    if (polygonHoles is! List || polygonHoles.isEmpty) {
      return {
        'parentToHoles': parentToHoles,
        'holeFaces': holeFaces,
      };
    }

    for (int i = 0; i < polygonHoles.length; i += 2) {
      if (i + 1 >= polygonHoles.length) break;
      
      final int holeFaceIdx = (polygonHoles[i] as num).toInt();
      final int parentFaceIdx = (polygonHoles[i + 1] as num).toInt();

      holeFaces.add(holeFaceIdx);
      
      if (!parentToHoles.containsKey(parentFaceIdx)) {
        parentToHoles[parentFaceIdx] = [];
      }
      parentToHoles[parentFaceIdx]!.add(holeFaceIdx);
    }

    return {
      'parentToHoles': parentToHoles,
      'holeFaces': holeFaces,
    };
  }

  /// Triangulate mesh indices while computing a face-local mapping pattern.
  Map<String, dynamic> _triangulateIndicesWithPattern(
    List<int> indices,
    List<int> counts, [
    List<double>? points,
    Map<String, dynamic>? holeMap,
  ]) {
    final List<int> triangulated = [];
    final List<int> pattern = []; // Stores face-local indices for each triangle vertex

    // Build face offset lookup for accessing hole face data
    final List<int> faceOffsets = [];
    int offsetAccum = 0;
    for (int i = 0; i < counts.length; i++) {
      faceOffsets.add(offsetAccum);
      offsetAccum += counts[i];
    }

    // Safely extract from our unified hole map layout
    final Map<int, List<int>> parentToHoles = (holeMap != null && holeMap['parentToHoles'] is Map<int, List<int>>)
        ? holeMap['parentToHoles'] as Map<int, List<int>>
        : {};
        
    final Set<int> holeFaces = (holeMap != null && holeMap['holeFaces'] is Set<int>)
        ? holeMap['holeFaces'] as Set<int>
        : {};

    int currentOffset = 0;

    for (int i = 0; i < counts.length; i++) {
      final int count = counts[i];

      // Skip faces that are holes - they will be triangulated with their parent
      if (holeFaces.contains(i)) {
        currentOffset += count;
        continue;
      }

      // Check if this face has holes
      final List<int>? holes = parentToHoles[i];

      if (holes != null && holes.isNotEmpty && points != null && points.isNotEmpty) {
        // Triangulate face with holes using vertex -> face-vertex mapping
        final Map<int, int> vertexToFaceVertex = {};
        final List<int> faceIndices = [];

        for (int j = 0; j < count; j++) {
          final int vertIdx = indices[currentOffset + j];
          faceIndices.add(vertIdx);
          vertexToFaceVertex[vertIdx] = currentOffset + j;
        }

        final List<List<int>> holeContours = [];
        for (final int holeFaceIdx in holes) {
          if (holeFaceIdx >= faceOffsets.length) continue;
          final int holeOffset = faceOffsets[holeFaceIdx];
          final int holeCount = counts[holeFaceIdx];
          final List<int> holeIndices = [];

          for (int j = 0; j < holeCount; j++) {
            final int vertIdx = indices[holeOffset + j];
            holeIndices.add(vertIdx);
            vertexToFaceVertex[vertIdx] = holeOffset + j;
          }
          holeContours.add(holeIndices);
        }

        // Execute earcut-style complex triangulation with holes mapping
        final List<List<int>> triangles = _triangulateNGonWithHoles(faceIndices, holeContours, points);
        for (final List<int> tri in triangles) {
          if (tri.length >= 3) {
            triangulated.addAll([tri[0], tri[1], tri[2]]);
            pattern.addAll([
              vertexToFaceVertex[tri[0]] ?? 0,
              vertexToFaceVertex[tri[1]] ?? 0,
              vertexToFaceVertex[tri[2]] ?? 0
            ]);
          }
        }
      } else if (count == 3) {
        triangulated.addAll([indices[currentOffset], indices[currentOffset + 1], indices[currentOffset + 2]]);
        pattern.addAll([currentOffset, currentOffset + 1, currentOffset + 2]);
      } else if (count == 4) {
        triangulated.addAll([
          indices[currentOffset], indices[currentOffset + 1], indices[currentOffset + 2],
          indices[currentOffset], indices[currentOffset + 2], indices[currentOffset + 3]
        ]);
        pattern.addAll([
          currentOffset, currentOffset + 1, currentOffset + 2,
          currentOffset, currentOffset + 2, currentOffset + 3
        ]);
      } else if (count > 4) {
        // Use ear-clipping for complex n-gons if we have vertex positions
        if (points != null && points.isNotEmpty) {
          final List<int> faceIndices = [];
          for (int j = 0; j < count; j++) {
            faceIndices.add(indices[currentOffset + j]);
          }

          final List<List<int>> triangles = _triangulateNGon(faceIndices, points);
          for (final List<int> tri in triangles) {
            if (tri.length >= 3) {
              triangulated.addAll([tri[0], tri[1], tri[2]]);
              // Find local indices within the face pattern
              pattern.addAll([
                currentOffset + faceIndices.indexOf(tri[0]),
                currentOffset + faceIndices.indexOf(tri[1]),
                currentOffset + faceIndices.indexOf(tri[2])
              ]);
            }
          }
        } else {
          // Fallback to fan triangulation
          for (int j = 1; j < count - 1; j++) {
            triangulated.addAll([indices[currentOffset], indices[currentOffset + j], indices[currentOffset + j + 1]]);
            pattern.addAll([currentOffset, currentOffset + j, currentOffset + j + 1]);
          }
        }
      }
      currentOffset += count;
    }

    return {
      'indices': triangulated,
      'pattern': pattern,
    };
  }

  /// Apply a pre-computed triangulation pattern to a list of indices.
  List<int> _applyTriangulationPattern(List<int> indices, List<int> pattern) {
    final List<int> result = [];
    for (int i = 0; i < pattern.length; i++) {
      final int targetIndex = pattern[i];
      if (targetIndex >= 0 && targetIndex < indices.length) {
        result.add(indices[targetIndex]);
      }
    }
    return result;
  }

  /// Triangulate a complex N-Gon by projecting 3D coordinates into 2D spaces.
  List<List<int>> _triangulateNGon(List<int> faceIndices, List<double> points) {
    final List<Vector2> contour2D = [];
    final List<Vector3> contour3D = [];

    for (final int idx in faceIndices) {
      contour3D.add(Vector3(
        points[idx * 3],
        points[idx * 3 + 1],
        points[idx * 3 + 2],
      ));
    }

    // Calculate polygon normal using Newell's method
    final Vector3 normal = Vector3(0.0, 0.0, 0.0);
    for (int i = 0; i < contour3D.length; i++) {
      final Vector3 curr = contour3D[i];
      final Vector3 next = contour3D[(i + 1) % contour3D.length];
      
      normal.x += (curr.y - next.y) * (curr.z + next.z);
      normal.y += (curr.z - next.z) * (curr.x + next.x);
      normal.z += (curr.x - next.x) * (curr.y + next.y);
    }
    normal.normalize();

    // Create tangent basis for projection
    final Vector3 tangent = Vector3(0.0, 0.0, 0.0);
    final Vector3 bitangent = Vector3(0.0, 0.0, 0.0);

    if (normal.y.abs() > 0.9) {
      tangent.setValues(1.0, 0.0, 0.0);
    } else {
      tangent.setValues(0.0, 1.0, 0.0);
    }

    bitangent.cross2(normal, tangent).normalize();
    tangent.cross2(bitangent, normal).normalize();

    // Project 3D vector layout coordinates down to a flat 2D workspace
    for (final Vector3 p in contour3D) {
      contour2D.add(Vector2(p.dot(tangent), p.dot(bitangent)));
    }

    // Triangulate using ShapeUtils from three_js_math package port
    final List<List<num>> triangles = ShapeUtils.triangulateShape(contour2D, []);

    // Map back to original indices
    final List<List<int>> result = [];
    for (final List<num> tri in triangles) {
      if (tri.length >= 3) {
        result.add([
          faceIndices[tri[0].toInt()],
          faceIndices[tri[1].toInt()],
          faceIndices[tri[2].toInt()],
        ]);
      }
    }

    return result;
  }

  /// Triangulate a complex N-Gon with internal holes using 2D projection.
  List<List<int>> _triangulateNGonWithHoles(
    List<int> outerIndices,
    List<List<int>> holeContours,
    List<double> points,
  ) {
    final List<Vector3> outer3D = [];
    for (final int idx in outerIndices) {
      outer3D.add(Vector3(
        points[idx * 3],
        points[idx * 3 + 1],
        points[idx * 3 + 2],
      ));
    }

    // Calculate polygon normal using Newell's method over the outer shell contour
    final Vector3 normal = Vector3(0.0, 0.0, 0.0);
    for (int i = 0; i < outer3D.length; i++) {
      final Vector3 curr = outer3D[i];
      final Vector3 next = outer3D[(i + 1) % outer3D.length];
      
      normal.x += (curr.y - next.y) * (curr.z + next.z);
      normal.y += (curr.z - next.z) * (curr.x + next.x);
      normal.z += (curr.x - next.x) * (curr.y + next.y);
    }
    normal.normalize();

    // Create tangent basis for ortho projection
    final Vector3 tangent = Vector3(0.0, 0.0, 0.0);
    final Vector3 bitangent = Vector3(0.0, 0.0, 0.0);

    if (normal.y.abs() > 0.9) {
      tangent.setValues(1.0, 0.0, 0.0);
    } else {
      tangent.setValues(0.0, 1.0, 0.0);
    }

    bitangent.cross2(normal, tangent).normalize();
    tangent.cross2(bitangent, normal).normalize();

    // Project outer shell contour to 2D
    final List<Vector2> outer2D = [];
    for (final Vector3 p in outer3D) {
      outer2D.add(Vector2(p.dot(tangent), p.dot(bitangent)));
    }

    // Project hole contours to 2D
    final List<List<Vector2>> holes2D = [];
    for (final List<int> holeIndices in holeContours) {
      final List<Vector2> hole2D = [];
      for (final int idx in holeIndices) {
        final Vector3 p = Vector3(
          points[idx * 3],
          points[idx * 3 + 1],
          points[idx * 3 + 2],
        );
        hole2D.add(Vector2(p.dot(tangent), p.dot(bitangent)));
      }
      holes2D.add(hole2D);
    }

    // Build combined index mapping reference index array: 
    // outer contour array followed sequentially by all inner holes
    final List<int> allIndices = [...outerIndices];
    for (final List<int> holeIndices in holeContours) {
      allIndices.addAll(holeIndices);
    }

    // Triangulate using ShapeUtils from three_js_math with holes support included
    final List<List<num>> triangles = ShapeUtils.triangulateShape(outer2D, holes2D);

    // Map triangle mappings back to original flat vertex indices coordinates arrays
    final List<List<int>> result = [];
    for (final List<num> tri in triangles) {
      if (tri.length >= 3) {
        final int idx0 = tri[0].toInt();
        final int idx1 = tri[1].toInt();
        final int idx2 = tri[2].toInt();

        if (idx0 < allIndices.length && idx1 < allIndices.length && idx2 < allIndices.length) {
          result.add([
            allIndices[idx0],
            allIndices[idx1],
            allIndices[idx2],
          ]);
        }
      }
    }

    return result;
  }

  /// Simple fan triangulation for face-varying vertex topological loops.
  // List<int> _triangulateIndices(List<int> indices, List<int> counts) {
  //   final List<int> triangulated = [];
  //   int currentOffset = 0;

  //   for (int i = 0; i < counts.length; i++) {
  //     final int count = counts[i];
      
  //     if (count == 3) {
  //       triangulated.addAll([
  //         indices[currentOffset], 
  //         indices[currentOffset + 1], 
  //         indices[currentOffset + 2]
  //       ]);
  //     } else if (count == 4) {
  //       triangulated.addAll([
  //         indices[currentOffset], indices[currentOffset + 1], indices[currentOffset + 2],
  //         indices[currentOffset], indices[currentOffset + 2], indices[currentOffset + 3]
  //       ]);
  //     } else if (count > 4) {
  //       // Fan triangulation for simple n-gons
  //       for (int j = 1; j < count - 1; j++) {
  //         triangulated.addAll([
  //           indices[currentOffset], 
  //           indices[currentOffset + j], 
  //           indices[currentOffset + j + 1]
  //         ]);
  //       }
  //     }
  //     currentOffset += count;
  //   }
    
  //   return triangulated;
  // }

  /// Expand flat source attributes based on index mapping sequences.
  /// Explicitly typed to process double collections (vertices, normals, UV tracks).
  List<double> _expandAttribute(List<double> data, List<int> indices, int itemSize) {
    // Allocate fixed-size tracking arrays to optimize machine allocations
    final List<double> expanded = List<double>.filled(indices.length * itemSize, 0.0);

    for (int i = 0; i < indices.length; i++) {
      final int srcIdx = indices[i];
      final int dstBase = i * itemSize;
      final int srcBase = srcIdx * itemSize;

      for (int j = 0; j < itemSize; j++) {
        expanded[dstBase + j] = data[srcBase + j];
      }
    }
    
    return expanded;
  }

  /// Overloaded wrapper variant for integer index collections tracking 
  /// (used specifically by skeletal joint mapping expansion paths).
  List<int> _expandAttributeInt(List<int> data, List<int> indices, int itemSize) {
    final List<int> expanded = List<int>.filled(indices.length * itemSize, 0);

    for (int i = 0; i < indices.length; i++) {
      final int srcIdx = indices[i];
      final int dstBase = i * itemSize;
      final int srcBase = srcIdx * itemSize;

      for (int j = 0; j < itemSize; j++) {
        expanded[dstBase + j] = data[srcBase + j];
      }
    }
    
    return expanded;
  }

  /// Compute per-vertex normals from indexed triangle data.
  /// Accumulates area-weighted face normals at each shared vertex and normalizes.
  Float32List _computeVertexNormals(List<double> points, List<int> indices) {
    final int numVertices = points.length ~/ 3;
    final Float32List normals = Float32List(numVertices * 3);

    for (int i = 0; i < indices.length; i += 3) {
      final int a = indices[i];
      final int b = indices[i + 1];
      final int c = indices[i + 2];

      final int a3 = a * 3;
      final int b3 = b * 3;
      final int c3 = c * 3;

      final double ax = points[a3], ay = points[a3 + 1], az = points[a3 + 2];
      final double bx = points[b3], by = points[b3 + 1], bz = points[b3 + 2];
      final double cx = points[c3], cy = points[c3 + 1], cz = points[c3 + 2];

      final double e1x = bx - ax, e1y = by - ay, e1z = bz - az;
      final double e2x = cx - ax, e2y = cy - ay, e2z = cz - az;

      final double nx = e1y * e2z - e1z * e2y;
      final double ny = e1z * e2x - e1x * e2z;
      final double nz = e1x * e2y - e1y * e2x;

      normals[a3] += nx;
      normals[a3 + 1] += ny;
      normals[a3 + 2] += nz;

      normals[b3] += nx;
      normals[b3 + 1] += ny;
      normals[b3 + 2] += nz;

      normals[c3] += nx;
      normals[c3 + 1] += ny;
      normals[c3 + 2] += nz;
    }

    for (int i = 0; i < numVertices; i++) {
      final int i3 = i * 3;
      final double x = normals[i3], y = normals[i3 + 1], z = normals[i3 + 2];
      final double len = math.sqrt(x * x + y * y + z * z);

      if (len > 0.0) {
        normals[i3] /= len;
        normals[i3 + 1] /= len;
        normals[i3 + 2] /= len;
      }
    }

    return normals;
  }

  /// Get the material path for a mesh, checking various binding sources.
  String? _getMaterialPath(String meshPath, Map<String, dynamic> fields) {
    String? materialPath;
    final dynamic materialBinding = fields['material:binding'];

    if (materialBinding != null) {
      materialPath = materialBinding is List ? materialBinding.first.toString() : materialBinding.toString();
    }

    // Use variant-aware lookup if no direct binding in fields
    if (materialPath == null || materialPath.isEmpty) {
      materialPath = _getMaterialBindingTarget(meshPath);
    }

    return materialPath;
  }

  /// Build a material from a Mesh spec fields mapping utilizing three_js_core materials.
  MeshPhysicalMaterial _buildMaterial(String meshPath, Map<String, dynamic> fields) {
    final MeshPhysicalMaterial material = MeshPhysicalMaterial({});
    String? materialPath;

    final dynamic materialBinding = fields['material:binding'];
    if (materialBinding != null) {
      materialPath = materialBinding is List ? materialBinding.first.toString() : materialBinding.toString();
    }

    // Use variant-aware lookup if no direct binding in fields
    if (materialPath == null || materialPath.isEmpty) {
      materialPath = _getMaterialBindingTarget(meshPath);
    }

    if (materialPath == null || materialPath.isEmpty) {
      final List<String> materialPaths = [];
      final String prefix = '$meshPath/';

      for (final String path in specsByPath.keys) {
        if (!path.startsWith(prefix)) continue;
        if (!path.endsWith('.material:binding')) continue;

        final dynamic bindingSpec = specsByPath[path];
        if (bindingSpec == null || bindingSpec['fields'] is! Map<String, dynamic>) continue;

        final Map<String, dynamic> bFields = bindingSpec['fields'] as Map<String, dynamic>;
        final dynamic targetPaths = bFields['targetPaths'];

        if (targetPaths is List && targetPaths.isNotEmpty) {
          materialPaths.add(targetPaths.first.toString());
        }
      }

      if (materialPaths.isNotEmpty) {
        materialPath = _pickBestMaterial(materialPaths);
      }
    }

    if (materialPath == null || materialPath.isEmpty) {
      // Use material index for O(1) lookup instead of O(n) iteration
      final List<String> meshParts = meshPath.split('/');
      if (meshParts.length > 1) {
        final String rootPath = '/${meshParts[1]}';
        // materialsByRoot uses Map<String, List<String>> signature matching previous indexes setup
        final List<String>? materialsInRoot = materialsByRoot[rootPath];
        
        if (materialsInRoot != null) {
          for (final String path in materialsInRoot) {
            if (path.startsWith('$rootPath/Looks/') || path.startsWith('$rootPath/Materials/')) {
              materialPath = path;
              break;
            }
          }
        }
      }
    }

    if (materialPath != null && materialPath.isNotEmpty) {
      _applyMaterial(material, materialPath);
    }

    return material;
  }

  /// Build a standalone physical material using the Three.js material system.
  MeshPhysicalMaterial _buildMaterialForPath(String? materialPath) {
    final MeshPhysicalMaterial material = MeshPhysicalMaterial({});
    if (materialPath != null && materialPath.isNotEmpty) {
      _applyMaterial(material, materialPath);
    }
    return material;
  }

  /// Apply material binding from a prim path to a mesh.
  /// Used when merging referenced geometry into a prim that has a material binding.
  void _applyMaterialBinding(Object3D mesh, String primPath) {
    // Look for material:binding on this prim
    final String bindingPath = '$primPath.material:binding';
    final dynamic bindingSpec = specsByPath[bindingPath];
    if (bindingSpec == null || bindingSpec['fields'] is! Map<String, dynamic>) return;

    final Map<String, dynamic> bFields = bindingSpec['fields'] as Map<String, dynamic>;
    String? materialPath;

    final dynamic targetPaths = bFields['targetPaths'] ?? bFields['default'];
    if (targetPaths != null) {
      materialPath = targetPaths is List ? targetPaths.first.toString() : targetPaths.toString();
    }

    if (materialPath == null || materialPath.isEmpty) return;

    // Clean the material path by removing bounding brackets <...>
    materialPath = materialPath.replaceAll(RegExp(r'^<|>$'), '');

    // Build and apply the material
    final MeshPhysicalMaterial material = MeshPhysicalMaterial({});
    _applyMaterial(material, materialPath);
    mesh.material = material;
  }

  /// Select the best material from candidates based on active texture attachments.
  String _pickBestMaterial(List<String> materialPaths) {
    if (materialPaths.isEmpty) return '';

    for (final String materialPath in materialPaths) {
      // shadersByMaterialPath maps to Map<String, List<String>> structure setup
      final List<String>? shaderPaths = shadersByMaterialPath[materialPath];
      if (shaderPaths == null) continue;

      for (final String path in shaderPaths) {
        final Map<String, dynamic> attrs = _getAttributes(path);
        if (attrs['info:id'] == 'UsdUVTexture' && attrs['inputs:file'] != null) {
          return materialPath;
        }
      }
    }

    return materialPaths.first;
  }

  /// Locate associated shaders and apply targeted attribute maps to a Three.js material.
  void _applyMaterial(MeshPhysicalMaterial material, String materialPath) {
    final dynamic materialSpec = specsByPath[materialPath];
    if (materialSpec == null) return;

    final List<String>? shaderPaths = shadersByMaterialPath[materialPath];
    if (shaderPaths == null) return;

    for (final String path in shaderPaths) {
      final dynamic spec = specsByPath[path];
      if (spec == null) continue;

      final Map<String, dynamic> specFields = (spec['fields'] is Map<String, dynamic>)
          ? spec['fields'] as Map<String, dynamic>
          : {};

      final Map<String, dynamic> shaderAttrs = _getAttributes(path);
      final String infoId = shaderAttrs['info:id']?.toString() ?? specFields['info:id']?.toString() ?? '';

      if (infoId == 'UsdPreviewSurface' || infoId == 'ND_UsdPreviewSurface_surfaceshader') {
        _applyPreviewSurface(material, path);
      } else if (infoId == 'arnold:openpbr_surface') {
        _applyOpenPBRSurface(material, path);
      }
    }
  }

  /// Shared helper for applying texture or value from shader attribute.
  /// Reduces duplication between _applyPreviewSurface and _applyOpenPBRSurface.
  bool _applyTextureOrValue(
    MeshPhysicalMaterial material,
    String shaderPath,
    Map<String, dynamic> fields,
    String attrName,
    String textureProperty,
    ColorSpace colorSpace,
    void Function(dynamic)? valueCallback,
    Texture? Function(String) textureGetter,
  ) {
    final String attrPath = '$shaderPath.$attrName';
    final dynamic spec = specsByPath[attrPath];

    if (spec != null && spec['fields'] is Map<String, dynamic>) {
      final Map<String, dynamic> sFields = spec['fields'] as Map<String, dynamic>;
      final dynamic connectionPathsRaw = sFields['connectionPaths'];

      if (connectionPathsRaw is List && connectionPathsRaw.isNotEmpty) {
        final List<String> connectionPaths = List<String>.from(connectionPathsRaw.map((e) => e.toString()));
        
        // Determine which paths to try based on whether we are using the OpenPBR getter function reference
        final List<String> paths = (textureGetter == _getTextureFromOpenPBRConnection)
            ? connectionPaths
            : [connectionPaths.first];

        for (final String connPath in paths) {
          final Texture? texture = textureGetter(connPath);
          if (texture != null) {
            texture.colorSpace = colorSpace.name;
            
            // Use dynamic reflection fallback if modifying three_js_core properties dynamically
            material.setProperty(textureProperty, texture);
            return true;
          }
        }
      }
    }

    if (fields.containsKey(attrName) && fields[attrName] != null) {
      if (valueCallback != null) {
        valueCallback(fields[attrName]);
      }
    }

    return false;
  }

  void _applyPreviewSurface(MeshPhysicalMaterial material, String shaderPath) {
    final Map<String, dynamic> fields = _getAttributes(shaderPath);

    // Local helper closure to mirror the JS applyTexture layout pattern cleanly
    bool applyTexture(
      String attrName, 
      String textureProperty, 
      ColorSpace colorSpace, 
      void Function(dynamic)? valueCallback
    ) {
      return _applyTextureOrValue(
        material, 
        shaderPath, 
        fields, 
        attrName, 
        textureProperty, 
        colorSpace, 
        valueCallback, 
        _getTextureFromConnection
      );
    }

    // Local helper closure to find attribute specifications
    dynamic getAttrSpec(String attrName) {
      final String attrPath = '$shaderPath.$attrName';
      return specsByPath[attrPath];
    }

    // 1. Diffuse color / base color map
    applyTexture('inputs:diffuseColor', 'map', ColorSpace.srgb, (color) {
      if (color is List && color.length >= 3) {
        material.color.setRGB(
          (color[0] as num).toDouble(),
          (color[1] as num).toDouble(),
          (color[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    });

    // Apply UsdUVTexture scale to diffuse color (output = texture * scale + bias)
    if (material.map != null && material.map!.userData['scale'] != null) {
      final dynamic scale = material.map!.userData['scale'];
      if (scale is List && scale.length >= 3) {
        material.color.setRGB(
          (scale[0] as num).toDouble(),
          (scale[1] as num).toDouble(),
          (scale[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    }

    // 2. Emissive mapping and calculation updates
    applyTexture('inputs:emissiveColor', 'emissiveMap', ColorSpace.srgb, (color) {
      if (color is List && color.length >= 3) {
        material.emissive?.setRGB(
          (color[0] as num).toDouble(),
          (color[1] as num).toDouble(),
          (color[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    });

    if (material.emissiveMap != null) {
      if (material.emissiveMap!.userData['scale'] != null) {
        final dynamic scale = material.emissiveMap!.userData['scale'];
        if (scale is List && scale.length >= 3) {
          material.emissive?.setRGB(
            (scale[0] as num).toDouble(),
            (scale[1] as num).toDouble(),
            (scale[2] as num).toDouble(),
            ColorSpace.srgb,
          );
        }
      } else {
        material.emissive?.setFromHex32(0xffffff); // Replaces .set(0xffffff)
      }
    }

    // 3. Normal mapping
    applyTexture('inputs:normal', 'normalMap', ColorSpace.linear, null);

    // Apply normal map scale from UsdUVTexture scale input
    if (material.normalMap != null && material.normalMap!.userData['scale'] != null) {
      final dynamic scale = material.normalMap!.userData['scale'];
      if (scale is List && scale.length >= 2) {
        // UsdUVTexture scale is float4 (r,g,b,a), use first two components for normalScale
        material.normalScale = Vector2(
          (scale[0] as num).toDouble(),
          (scale[1] as num).toDouble(),
        );
      }
    }

    // 4. Roughness
    final bool hasRoughnessMap = applyTexture('inputs:roughness', 'roughnessMap', ColorSpace.linear, (value) {
      if (value is num) material.roughness = value.toDouble();
    });
    if (hasRoughnessMap) {
      material.roughness = 1.0;
    }

    // 5. Metallic
    final bool hasMetalnessMap = applyTexture('inputs:metallic', 'metalnessMap', ColorSpace.linear, (value) {
      if (value is num) material.metalness = value.toDouble();
    });
    if (hasMetalnessMap) {
      material.metalness = 1.0;
    }

    // 6. Occlusion (aoMap)
    applyTexture('inputs:occlusion', 'aoMap', ColorSpace.linear, null);

    // 7. Index of Refraction (IOR)
    if (fields.containsKey('inputs:ior') && fields['inputs:ior'] != null) {
      material.ior = (fields['inputs:ior'] as num).toDouble();
    }

    // 8. Specular color
    applyTexture('inputs:specularColor', 'specularColorMap', ColorSpace.srgb, (color) {
      if (color is List && color.length >= 3) {
        // MeshPhysicalMaterial natively supports specularIntensity and specularColor custom properties
        (material as dynamic).specularColor?.setRGB(
          (color[0] as num).toDouble(),
          (color[1] as num).toDouble(),
          (color[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    });

    // Apply UsdUVTexture scale to specular color
    final dynamic specColorMap = (material as dynamic).specularColorMap;
    if (specColorMap != null && specColorMap.userData['scale'] != null) {
      final dynamic scale = specColorMap.userData['scale'];
      if (scale is List && scale.length >= 3) {
        (material as dynamic).specularColor?.setRGB(
          (scale[0] as num).toDouble(),
          (scale[1] as num).toDouble(),
          (scale[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    }

    // 9. Clearcoat parameters
    if (fields.containsKey('inputs:clearcoat') && fields['inputs:clearcoat'] != null) {
      material.clearcoat = (fields['inputs:clearcoat'] as num).toDouble();
    }

    if (fields.containsKey('inputs:clearcoatRoughness') && fields['inputs:clearcoatRoughness'] != null) {
      material.clearcoatRoughness = (fields['inputs:clearcoatRoughness'] as num).toDouble();
    }

    // 10. Opacity and transparency alpha blending/test modes
    final double opacityThreshold = fields.containsKey('inputs:opacityThreshold') && fields['inputs:opacityThreshold'] != null
        ? (fields['inputs:opacityThreshold'] as num).toDouble()
        : 0.0;

    // Check if opacity is connected to a texture (e.g., diffuse texture's alpha)
    final dynamic opacitySpec = getAttrSpec('inputs:opacity');
    bool hasOpacityConnection = false;

    if (opacitySpec != null && opacitySpec['fields'] is Map<String, dynamic>) {
      final Map<String, dynamic> oFields = opacitySpec['fields'] as Map<String, dynamic>;
      final dynamic oConnPaths = oFields['connectionPaths'];
      hasOpacityConnection = oConnPaths is List && oConnPaths.isNotEmpty;
    }

    if (hasOpacityConnection) {
      // Opacity from texture alpha - use the diffuse map's alpha channel
      if (opacityThreshold > 0.0) {
        // Alpha cutoff mode
        material.alphaTest = opacityThreshold;
        material.transparent = false;
      } else {
        // Alpha blend mode
        material.transparent = true;
      }
    } else {
      // Direct scalar opacity value
      final double opacity = fields.containsKey('inputs:opacity') && fields['inputs:opacity'] != null
          ? (fields['inputs:opacity'] as num).toDouble()
          : 1.0;
          
      if (opacity < 1.0) {
        material.transparent = true;
        material.opacity = opacity;
      }
    }
  }

  void _applyOpenPBRSurface(MeshPhysicalMaterial material, String shaderPath) {
    final Map<String, dynamic> fields = _getAttributes(shaderPath);

    // Local helper closure to mirror the JS applyTexture layout pattern cleanly
    bool applyTexture(
      String attrName, 
      String textureProperty, 
      ColorSpace colorSpace, 
      void Function(dynamic)? valueCallback
    ) {
      return _applyTextureOrValue(
        material, 
        shaderPath, 
        fields, 
        attrName, 
        textureProperty, 
        colorSpace, 
        valueCallback, 
        _getTextureFromOpenPBRConnection
      );
    }

    // 1. Base color (diffuse)
    applyTexture('inputs:base_color', 'map', ColorSpace.srgb, (color) {
      if (color is List && color.length >= 3) {
        material.color.setRGB(
          (color[0] as num).toDouble(),
          (color[1] as num).toDouble(),
          (color[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    });

    // Apply UsdUVTexture scale to base color
    if (material.map != null && material.map!.userData['scale'] != null) {
      final dynamic scale = material.map!.userData['scale'];
      if (scale is List && scale.length >= 3) {
        material.color.setRGB(
          (scale[0] as num).toDouble(),
          (scale[1] as num).toDouble(),
          (scale[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    }

    // 2. Base metalness
    applyTexture('inputs:base_metalness', 'metalnessMap', ColorSpace.linear, (value) {
      if (value is num) {
        material.metalness = value.toDouble();
      }
    });

    // 3. Specular roughness
    applyTexture('inputs:specular_roughness', 'roughnessMap', ColorSpace.linear, (value) {
      if (value is num) {
        material.roughness = value.toDouble();
      }
    });

    // 4. Emission color
    final bool hasEmissionMap = applyTexture('inputs:emission_color', 'emissiveMap', ColorSpace.srgb, (color) {
      if (color is List && color.length >= 3) {
        material.emissive?.setRGB(
          (color[0] as num).toDouble(),
          (color[1] as num).toDouble(),
          (color[2] as num).toDouble(),
          ColorSpace.srgb,
        );
      }
    });

    // Emission luminance/weight - multiply emissive by this factor
    final dynamic emissionLuminance = fields['inputs:emission_luminance'];
    if (emissionLuminance != null && emissionLuminance is num && emissionLuminance > 0) {
      final double luminance = emissionLuminance.toDouble();
      if (hasEmissionMap) {
        material.emissiveIntensity = luminance;
      } else {
        // Scale the emissive color by luminance natively using three_js_math vectors multipliers
        material.emissive?.scale(luminance);
      }
    }

    // 5. Transmission (transparency)
    final dynamic transmissionWeight = fields['inputs:transmission_weight'];
    if (transmissionWeight != null && transmissionWeight is num && transmissionWeight > 0) {
      material.transmission = transmissionWeight.toDouble();
      
      final dynamic transmissionDepth = fields['inputs:transmission_depth'];
      if (transmissionDepth != null && transmissionDepth is num) {
        material.thickness = transmissionDepth.toDouble();
      }

      final dynamic transmissionColor = fields['inputs:transmission_color'];
      if (transmissionColor != null && transmissionColor is List) {
        material.attenuationColor?.setRGB(
          (transmissionColor[0] as num).toDouble(),
          (transmissionColor[1] as num).toDouble(),
          (transmissionColor[2] as num).toDouble(),
        );
        material.attenuationDistance = transmissionDepth is num ? transmissionDepth.toDouble() : 1.0;
      }
    }

    // 6. Geometry opacity (overall surface opacity)
    final dynamic geometryOpacity = fields['inputs:geometry_opacity'];
    if (geometryOpacity != null && geometryOpacity is num && geometryOpacity < 1.0) {
      material.opacity = geometryOpacity.toDouble();
      material.transparent = true;
    }

    // 7. Specular IOR
    final dynamic specularIOR = fields['inputs:specular_ior'];
    if (specularIOR != null && specularIOR is num) {
      material.ior = specularIOR.toDouble();
    }

    // 8. Coat (clearcoat)
    final dynamic coatWeight = fields['inputs:coat_weight'];
    if (coatWeight != null && coatWeight is num && coatWeight > 0) {
      material.clearcoat = coatWeight.toDouble();
      
      final dynamic coatRoughness = fields['inputs:coat_roughness'];
      if (coatRoughness != null && coatRoughness is num) {
        material.clearcoatRoughness = coatRoughness.toDouble();
      }
    }

    // 9. Thin film (iridescence)
    final dynamic thinFilmWeight = fields['inputs:thin_film_weight'];
    if (thinFilmWeight != null && thinFilmWeight is num && thinFilmWeight > 0) {
      material.iridescence = thinFilmWeight.toDouble();
      
      final dynamic thinFilmIOR = fields['inputs:thin_film_ior'];
      if (thinFilmIOR != null && thinFilmIOR is num) {
        material.iridescenceIOR = thinFilmIOR.toDouble();
      }
      
      final dynamic thinFilmThickness = fields['inputs:thin_film_thickness'];
      if (thinFilmThickness != null && thinFilmThickness is num) {
        // OpenPBR uses micrometers, Three.js uses nanometers
        final double thicknessNm = thinFilmThickness.toDouble() * 1000.0;
        material.iridescenceThicknessRange = [thicknessNm, thicknessNm];
      }
    }

    // 10. Specular intensity/color parameters
    final dynamic specularWeight = fields['inputs:specular_weight'];
    if (specularWeight != null && specularWeight is num) {
      material.specularIntensity = specularWeight.toDouble();
    }

    final dynamic specularColor = fields['inputs:specular_color'];
    if (specularColor != null && specularColor is List) {
      material.specularColor?.setRGB(
        (specularColor[0] as num).toDouble(),
        (specularColor[1] as num).toDouble(),
        (specularColor[2] as num).toDouble(),
      );
    }

    // 11. Anisotropy
    final dynamic anisotropy = fields['inputs:specular_roughness_anisotropy'];
    if (anisotropy != null && anisotropy is num && anisotropy > 0) {
      material.anisotropy = anisotropy.toDouble();
    }

    // 12. Geometry normal (normal map)
    applyTexture('inputs:geometry_normal', 'normalMap', ColorSpace.linear, null);
  }

  /// Follow PBR network shader node links recursively to extract a valid Texture asset.
  Texture? _getTextureFromOpenPBRConnection(String connPath) {
    // connPath is like /Material/NodeGraph.outputs:baseColor or /Material/Shader.outputs:out
    final String cleanPath = connPath.replaceAll(RegExp(r'<|>'), '');
    final String shaderPath = cleanPath.split('.').first;

    final dynamic shaderSpec = specsByPath[shaderPath];
    if (shaderSpec == null) return null;

    final Map<String, dynamic> specFields = (shaderSpec['fields'] is Map<String, dynamic>)
        ? shaderSpec['fields'] as Map<String, dynamic>
        : {};

    final Map<String, dynamic> attrs = _getAttributes(shaderPath);
    final String infoId = attrs['info:id']?.toString() ?? specFields['info:id']?.toString() ?? '';
    final String typeName = specFields['typeName']?.toString() ?? '';

    // 1. Handle NodeGraph - follow output connection to internal shader
    if (typeName == 'NodeGraph') {
      // Get the output attribute that's connected
      final List<String> cleanParts = cleanPath.split('.');
      final String outputName = cleanParts.length > 1 ? cleanParts[1] : ''; // e.g., "outputs:baseColor"
      final String outputAttrPath = '$shaderPath.$outputName';
      
      final dynamic outputSpec = specsByPath[outputAttrPath];
      if (outputSpec != null && outputSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> oFields = outputSpec['fields'] as Map<String, dynamic>;
        final dynamic oConnPaths = oFields['connectionPaths'];
        if (oConnPaths is List && oConnPaths.isNotEmpty) {
          // Follow the internal connection recursively
          return _getTextureFromOpenPBRConnection(oConnPaths.first.toString());
        }
      }
      return null;
    }

    // 2. Handle arnold:image - Arnold's texture node
    if (infoId == 'arnold:image') {
      final String? filePath = attrs['inputs:filename']?.toString();
      if (filePath == null || filePath.isEmpty) return null;
      return _loadTextureFromPath(filePath);
    }

    // 3. Handle MaterialX image nodes (ND_image_color4, ND_image_color3, etc.)
    if (infoId.startsWith('ND_image_')) {
      final String? filePath = attrs['inputs:file']?.toString();
      if (filePath == null || filePath.isEmpty) return null;
      return _loadTextureFromPath(filePath);
    }

    // 4. Handle Maya file texture - follow the inColor connection to the actual image
    if (infoId == 'MayaND_fileTexture_color4') {
      final String inColorPath = '$shaderPath.inputs:inColor';
      final dynamic inColorSpec = specsByPath[inColorPath];
      if (inColorSpec != null && inColorSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> icFields = inColorSpec['fields'] as Map<String, dynamic>;
        final dynamic icConnPaths = icFields['connectionPaths'];
        if (icConnPaths is List && icConnPaths.isNotEmpty) {
          return _getTextureFromOpenPBRConnection(icConnPaths.first.toString());
        }
      }
      return null;
    }

    // 5. Handle MaterialX color conversion nodes - follow the input connection
    if (infoId.startsWith('ND_convert_')) {
      final String inPath = '$shaderPath.inputs:in';
      final dynamic inSpec = specsByPath[inPath];
      if (inSpec != null && inSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> iFields = inSpec['fields'] as Map<String, dynamic>;
        final dynamic iConnPaths = iFields['connectionPaths'];
        if (iConnPaths is List && iConnPaths.isNotEmpty) {
          return _getTextureFromOpenPBRConnection(iConnPaths.first.toString());
        }
      }
      return null;
    }

    // 6. Handle Arnold bump2d - follow the bump_map input
    if (infoId == 'arnold:bump2d') {
      final String bumpMapPath = '$shaderPath.inputs:bump_map';
      final dynamic bumpMapSpec = specsByPath[bumpMapPath];
      if (bumpMapSpec != null && bumpMapSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> bmFields = bumpMapSpec['fields'] as Map<String, dynamic>;
        final dynamic bmConnPaths = bmFields['connectionPaths'];
        if (bmConnPaths is List && bmConnPaths.isNotEmpty) {
          return _getTextureFromOpenPBRConnection(bmConnPaths.first.toString());
        }
      }
      return null;
    }

    // 7. Handle Arnold color_correct - follow the input connection
    if (infoId == 'arnold:color_correct') {
      final String inputPath = '$shaderPath.inputs:input';
      final dynamic inputSpec = specsByPath[inputPath];
      if (inputSpec != null && inputSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> inpFields = inputSpec['fields'] as Map<String, dynamic>;
        final dynamic inpConnPaths = inpFields['connectionPaths'];
        if (inpConnPaths is List && inpConnPaths.isNotEmpty) {
          return _getTextureFromOpenPBRConnection(inpConnPaths.first.toString());
        }
      }
      return null;
    }

    // 8. Handle nested shader paths (e.g., /Material/file2/cc.outputs:a)
    // Check if parent path is an image node
    final int lastSlashIdx = shaderPath.lastIndexOf('/');
    if (lastSlashIdx > 0) {
      final String parentPath = shaderPath.substring(0, lastSlashIdx);
      final dynamic parentSpec = specsByPath[parentPath];
      
      if (parentSpec != null && parentSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> pFields = parentSpec['fields'] as Map<String, dynamic>;
        final Map<String, dynamic> parentAttrs = _getAttributes(parentPath);
        final String parentInfoId = parentAttrs['info:id']?.toString() ?? pFields['info:id']?.toString() ?? '';

        if (parentInfoId == 'arnold:image') {
          final String? filePath = parentAttrs['inputs:filename']?.toString();
          if (filePath != null && filePath.isNotEmpty) {
            return _loadTextureFromPath(filePath);
          }
        }
      }
    }

    return null;
  }

  /// Load a texture from path, checking the local cache portfolio first.
  Texture? _loadTextureFromPath(String? filePath) {
    if (filePath == null || filePath.isEmpty) return null;

    // Assuming textureCache is declared as Map<String, Texture> at your class header level
    if (textureCache.containsKey(filePath)) {
      return textureCache[filePath];
    }

    final Texture? texture = _loadTexture(filePath, null, null);
    if (texture != null) {
      textureCache[filePath] = texture;
    }
    return texture;
  }

  /// Follow standard texture nodes connections recursively to construct and cache Texture items.
  Texture? _getTextureFromConnection(String connPath) {
    // connPath is like /Material/Shader.outputs:rgb
    final String shaderPath = connPath.split('.').first;
    final dynamic shaderSpec = specsByPath[shaderPath];
    if (shaderSpec == null) return null;

    final Map<String, dynamic> specFields = (shaderSpec['fields'] is Map<String, dynamic>)
        ? shaderSpec['fields'] as Map<String, dynamic>
        : {};

    final Map<String, dynamic> attrs = _getAttributes(shaderPath);
    final String infoId = attrs['info:id']?.toString() ?? specFields['info:id']?.toString() ?? '';
    if (infoId != 'UsdUVTexture') return null;

    final String? filePath = attrs['inputs:file']?.toString();
    if (filePath == null || filePath.isEmpty) return null;

    // Check for UsdTransform2d connection via inputs:st and trace to PrimvarReader
    Map<String, dynamic>? transformAttrs;
    int uvChannel = 0; // Default to first UV set (channel 0)

    final String stAttrPath = '$shaderPath.inputs:st';
    final dynamic stAttrSpec = specsByPath[stAttrPath];

    if (stAttrSpec != null && stAttrSpec['fields'] is Map<String, dynamic>) {
      final Map<String, dynamic> stFields = stAttrSpec['fields'] as Map<String, dynamic>;
      final dynamic stConnPaths = stFields['connectionPaths'];

      if (stConnPaths is List && stConnPaths.isNotEmpty) {
        final String stConnPath = stConnPaths.first.toString();
        final String stPath = stConnPath.replaceAll(RegExp(r'<|>'), '').split('.').first;
        final dynamic stSpec = specsByPath[stPath];

        if (stSpec != null && stSpec['fields'] is Map<String, dynamic>) {
          final Map<String, dynamic> stSpecFields = stSpec['fields'] as Map<String, dynamic>;
          final Map<String, dynamic> stAttrs = _getAttributes(stPath);
          final String stInfoId = stAttrs['info:id']?.toString() ?? stSpecFields['info:id']?.toString() ?? '';

          if (stInfoId == 'UsdTransform2d') {
            transformAttrs = stAttrs;

            // Trace to PrimvarReader to find UV set
            final String inAttrPath = '$stPath.inputs:in';
            final dynamic inAttrSpec = specsByPath[inAttrPath];

            if (inAttrSpec != null && inAttrSpec['fields'] is Map<String, dynamic>) {
              final Map<String, dynamic> inFields = inAttrSpec['fields'] as Map<String, dynamic>;
              final dynamic inConnPaths = inFields['connectionPaths'];

              if (inConnPaths is List && inConnPaths.isNotEmpty) {
                final String inConnPath = inConnPaths.first.toString();
                final String primvarPath = inConnPath.replaceAll(RegExp(r'<|>'), '').split('.').first;
                final Map<String, dynamic> primvarAttrs = _getAttributes(primvarPath);

                // Check varname to determine UV channel selection
                final String varname = primvarAttrs['inputs:varname']?.toString() ?? '';
                if (varname == 'st1') {
                  uvChannel = 1;
                } else if (varname == 'st2') {
                  uvChannel = 2;
                }
              }
            }
          } else if (stInfoId == 'UsdPrimvarReader_float2') {
            // Direct connection to PrimvarReader
            final String varname = stAttrs['inputs:varname']?.toString() ?? '';
            if (varname == 'st1') {
              uvChannel = 1;
            } else if (varname == 'st2') {
              uvChannel = 2;
            }
          }
        }
      }
    }

    // Extract scale and bias for texture value modification
    final dynamic scale = attrs['inputs:scale'];
    final dynamic bias = attrs['inputs:bias'];

    // Create composite cache key that includes scale/bias parameters if present
    String cacheKey = filePath;
    if (scale is List) {
      cacheKey += ':s${scale.join(',')}';
    }
    if (bias is List) {
      cacheKey += ':b${bias.join(',')}';
    }

    if (textureCache.containsKey(cacheKey)) {
      return textureCache[cacheKey];
    }

    final Texture? texture = _loadTexture(filePath, attrs, transformAttrs);
    if (texture != null) {
      // Store scale/bias parameters in standard three_js_core userData dictionary map
      if (scale != null) texture.userData['scale'] = scale;
      if (bias != null) texture.userData['bias'] = bias;
      
      // Assign alternative UV sets using the native .channel layout pointer property
      if (uvChannel != 0) {
        texture.channel = uvChannel;
      }
      
      textureCache[cacheKey] = texture;
    }

    return texture;
  }

  /// Apply standard scale, offset, and rotation texture transforms.
  void _applyTextureTransforms(Texture texture, Map<String, dynamic>? attrs) {
    if (attrs == null) return;

    final dynamic scale = attrs['inputs:scale'];
    if (scale is List && scale.length >= 2) {
      texture.repeat.setValues(
        (scale[0] as num).toDouble(),
        (scale[1] as num).toDouble(),
      );
    }

    final dynamic translation = attrs['inputs:translation'];
    if (translation is List && translation.length >= 2) {
      texture.offset.setValues(
        (translation[0] as num).toDouble(),
        (translation[1] as num).toDouble(),
      );
    }

    final dynamic rotation = attrs['inputs:rotation'];
    if (rotation is num) {
      texture.rotation = rotation.toDouble() * math.pi / 180.0;
    }
  }

  /// Resolve texture asset reference paths and pipeline them to the creation engine.
  Texture? _loadTexture(
    String filePath,
    Map<String, dynamic>? textureAttrs,
    Map<String, dynamic>? transformAttrs,
  ) {
    if (filePath.isEmpty) return null;
    
    String cleanPath = filePath;
    if (cleanPath.startsWith('@')) {
      cleanPath = cleanPath.substring(1);
    }
    if (cleanPath.endsWith('@')) {
      cleanPath = cleanPath.substring(0, cleanPath.length - 1);
    }

    // Resolve relative to basePath first
    final String resolvedPath = _resolveFilePath(cleanPath);
    dynamic assetData = assets[resolvedPath];

    // Fallback to unresolved path if missing
    if (assetData == null) {
      assetData = assets[cleanPath];
    }

    // Last resort: search by basename matching parameters
    if (assetData == null) {
      final String baseName = cleanPath.split('/').lastOrNull ?? '';
      if (baseName.isNotEmpty) {
        for (final String key in assets.keys) {
          if (key.endsWith(baseName) || key.endsWith('/$baseName')) {
            return _createTextureFromData(assets[key], textureAttrs, transformAttrs);
          }
        }
      }

      // Standalone .usd/.usda/.usdc files don't pre-load assets; treat the
      // resolved path as a URL relative to basePath so the browser fetches
      // the texture from disk next to the layer.
      if (basePath.isNotEmpty) {
        return _createTextureFromData(resolvedPath, textureAttrs, transformAttrs);
      }

      // Try loading via LoadingManager if available
      // Assuming 'manager' variable layout is declared at your parent class structure level
      if (manager != null) {
        final String url = manager!.resolveURL(baseName);
        if (url != baseName) {
          // URL modifier found a match - load it
          return _createTextureFromData(url, textureAttrs, transformAttrs);
        }
      }

      console.warning('USDLoader: Texture not found: $cleanPath');
      return null;
    }

    return _createTextureFromData(assetData, textureAttrs, transformAttrs);
  }

  /// Create and prepare a Texture from raw data, scheduling an asynchronous load step.
  Texture? _createTextureFromData(
    dynamic data,
    Map<String, dynamic>? textureAttrs,
    Map<String, dynamic>? transformAttrs,
  ) {
    if (data == null) return null;

    // Instantiate standard loaders provided out-of-the-box by three_js_core
    final TextureLoader loader = TextureLoader(manager: manager);
    
    // Initialize a placeholder texture to pass back synchronously to material assignments
    final Texture texture = Texture();

    // We wrap our loading routine in a Future to place onto the track manager array
    final Future<void> loadFuture = () async {
      try {
        dynamic source;

        if (data is String) {
          // Direct string URL path tracking
          source = data;
        } else if (data is Uint8List) {
          source = data;
        } else if (data is ByteBuffer) {
          source = data.asUint8List();
        } else if (data is List<int>) {
          source = Uint8List.fromList(data);
        } else {
          return;
        }

        // LoadAsync handles network string fetches or memory bytes conversions internally 
        // based on the incoming source format signature
        final Texture? loadedTexture = await loader.unknown(source);

        // Map loaded source elements back into our tracking node context window
        texture.image = loadedTexture?.image;
        if(loadedTexture != null) texture.source = loadedTexture.source;

        // Handle wrapping attribute overrides safely
        if (textureAttrs != null) {
          texture.wrapS = _getWrapMode(textureAttrs['inputs:wrapS']?.toString());
          texture.wrapT = _getWrapMode(textureAttrs['inputs:wrapT']?.toString());
        }

        // Apply low-level scalar texture translations
        _applyTextureTransforms(texture, transformAttrs);
        texture.needsUpdate = true;
      } catch (e) {
        console.warning('USDLoader: Failed to load texture from source representation data data: $e');
      }
    }();

    texturePromises.add(loadFuture);

    return texture;
  }

  /// Convert USD wrap configuration tags to Three.js constants.
  int _getWrapMode(String? wrapValue) {
    if (wrapValue == 'repeat') {
      return RepeatWrapping; // Corresponds to RepeatWrapping
    }
    if (wrapValue == 'mirror') {
      return MirroredRepeatWrapping; // Corresponds to MirroredRepeatWrapping
    }
    if (wrapValue == 'clamp') {
      return ClampToEdgeWrapping; // Corresponds to ClampToEdgeWrapping
    }
    return RepeatWrapping;
  }

  /// Build a skeleton structure from a Skeleton spec.
  Map<String, dynamic>? _buildSkeleton(String path) {
    final Map<String, dynamic> attrs = _getAttributes(path);

    // Get joint names (paths like "root", "root/body_joint", etc.)
    final dynamic jointsRaw = attrs['joints'];
    if (jointsRaw is! List || jointsRaw.isEmpty) return null;
    final List<String> joints = List<String>.from(jointsRaw.map((e) => e.toString()));

    // Get bind transforms (world-space bind pose matrices)
    final dynamic rawBindTransforms = attrs['bindTransforms'];
    final dynamic rawRestTransforms = attrs['restTransforms'];
    
    final List<double>? bindTransforms = _flattenMatrixArray(rawBindTransforms, joints.length);
    final List<double>? restTransforms = _flattenMatrixArray(rawRestTransforms, joints.length);

    // Build bones
    final List<Bone> bones = [];
    final Map<String, Map<String, dynamic>> bonesByPath = {};
    final List<Matrix4> boneInverses = [];

    for (int i = 0; i < joints.length; i++) {
      final String jointPath = joints[i];
      final String jointName = jointPath.split('/').lastOrNull ?? '';
      
      final Bone bone = Bone();
      bone.name = jointName;
      bones.add(bone);
      
      bonesByPath[jointPath] = {
        'bone': bone,
        'index': i,
      };

      // Compute inverse bind matrix
      if (bindTransforms != null && bindTransforms.length >= (i + 1) * 16) {
        final Matrix4 bindMatrix = Matrix4();
        // USD matrices are row-major, Three.js is column-major - need to transpose
        final List<double> m = bindTransforms.sublist(i * 16, (i + 1) * 16);
        
        bindMatrix.setValues(
          m[ 0 ], m[ 4 ], m[ 8 ], m[ 12 ],
          m[ 1 ], m[ 5 ], m[ 9 ], m[ 13 ],
          m[ 2 ], m[ 6 ], m[ 10 ], m[ 14 ],
          m[ 3 ], m[ 7 ], m[ 11 ], m[ 15 ]
        );
        
        final Matrix4 inverseBindMatrix = bindMatrix.clone().invert();
        boneInverses.add(inverseBindMatrix);
      } else {
        boneInverses.add(Matrix4());
      }
    }

    // Build parent-child relationships based on joint paths
    for (int i = 0; i < joints.length; i++) {
      final String jointPath = joints[i];
      final List<String> parts = jointPath.split('/');
      
      if (parts.length > 1) {
        final String parentPath = parts.sublist(0, parts.length - 1).join('/');
        final Map<String, dynamic>? parentData = bonesByPath[parentPath];
        if (parentData != null) {
          final Bone parentBone = parentData['bone'] as Bone;
          parentBone.add(bones[i]);
        }
      }
    }

    // Apply rest transforms as bone local transforms
    if (restTransforms != null && restTransforms.length >= joints.length * 16) {
      for (int i = 0; i < joints.length; i++) {
        final Matrix4 matrix = Matrix4();
        final List<double> m = restTransforms.sublist(i * 16, (i + 1) * 16);
        
        matrix.setValues(
          m[ 0 ], m[ 4 ], m[ 8 ], m[ 12 ],
          m[ 1 ], m[ 5 ], m[ 9 ], m[ 13 ],
          m[ 2 ], m[ 6 ], m[ 10 ], m[ 14 ],
          m[ 3 ], m[ 7 ], m[ 11 ], m[ 15 ]
        );
        
        matrix.decompose(bones[i].position, bones[i].quaternion, bones[i].scale);
      }
    }

    // Find root bone(s) - bones without a parent bone layout context
    final List<Bone> rootBones = bones.where((bone) => bone.parent == null || bone.parent is! Bone).toList();

    // Get animation source path
    final dynamic animSourceSpec = specsByPath['$path.skel:animationSource'];
    String? animationPath;
    
    if (animSourceSpec != null && animSourceSpec['fields'] is Map<String, dynamic>) {
      final Map<String, dynamic> fields = animSourceSpec['fields'] as Map<String, dynamic>;
      final dynamic targetPaths = fields['targetPaths'];
      if (targetPaths is List && targetPaths.isNotEmpty) {
        animationPath = targetPaths.first.toString();
      }
    }

    return {
      'skeleton': Skeleton(bones, boneInverses),
      'joints': joints,
      'rootBones': rootBones,
      'animationPath': animationPath,
      'path': path,
    };
  }

  /// Bind skeletons to skinned meshes.
  void _bindSkeletons() {
    // Class-level portfolio definitions assumed:
    // List<Map<String, dynamic>> skinnedMeshes = [];
    // Map<String, Map<String, dynamic>> skeletons = {};

    for (final Map<String, dynamic> meshData in skinnedMeshes) {
      final SkinnedMesh mesh = meshData['mesh'] as SkinnedMesh;
      final String? skeletonPath = meshData['skeletonPath']?.toString();
      final dynamic localJointsRaw = meshData['localJoints'];
      final dynamic geomBindTransformRaw = meshData['geomBindTransform'];

      final List<String>? localJoints = localJointsRaw is List 
          ? List<String>.from(localJointsRaw.map((e) => e.toString())) 
          : null;

      Map<String, dynamic>? skeletonData;

      // 1. Try exact match first
      if (skeletonPath != null && skeletons.containsKey(skeletonPath)) {
        skeletonData = skeletons[skeletonPath];
      }

      // 2. Try includes match as fallback
      if (skeletonData == null) {
        for (final String skelPath in skeletons.keys) {
          if (skeletonPath != null && (skeletonPath.contains(skelPath) || skelPath.contains(skeletonPath))) {
            skeletonData = skeletons[skelPath];
            break;
          }
        }
      }

      // 3. Fallback to first skeleton for single-skeleton files
      if (skeletonData == null) {
        final List<String> skeletonPaths = skeletons.keys.toList();
        if (skeletonPaths.isNotEmpty) {
          skeletonData = skeletons[skeletonPaths.first];
        }
      }

      if (skeletonData == null) {
        console.warning('USDComposer: No skeleton found for skinned mesh: ${mesh.name}');
        continue;
      }

      final Skeleton skeleton = skeletonData['skeleton'] as Skeleton;
      final List<Bone> rootBones = List<Bone>.from(skeletonData['rootBones'] as List);
      final List<String> joints = List<String>.from(skeletonData['joints'] as List);

      // Apply local-to-global joint remapping if sub-mesh influences differ
      if (localJoints != null && localJoints.isNotEmpty) {
        final dynamic skinIndexAttr = mesh.geometry?.getAttributeFromString('skinIndex');
        if (skinIndexAttr != null && skinIndexAttr.array != null) {
          final List<int> localToGlobal = List<int>.filled(localJoints.length, 0);
          
          for (int i = 0; i < localJoints.length; i++) {
            final String jointName = localJoints[i];
            final int globalIdx = joints.indexOf(jointName);
            localToGlobal[i] = globalIdx >= 0 ? globalIdx : 0;
          }

          // Direct typed buffer manipulation matching JavaScript typed array layout overrides
          final dynamic arr = skinIndexAttr.array;
          if (arr is Uint16List || arr is List<int>) {
            for (int i = 0; i < arr.length; i++) {
              final int localIdx = arr[i];
              if (localIdx >= 0){
                arr[i] = List<double>.from(geomBindTransformRaw.map((v) => (v as num).toDouble()));
              }
            }
          }
        }
      }

      for (final rootBone in rootBones ) {
        mesh.add( rootBone );
      }

      final bindMatrix = Matrix4();

    if ( geomBindTransformRaw && geomBindTransformRaw.length == 16 ) {
      final m = geomBindTransformRaw;
      bindMatrix.setValues(
        m[ 0 ], m[ 4 ], m[ 8 ], m[ 12 ],
        m[ 1 ], m[ 5 ], m[ 9 ], m[ 13 ],
        m[ 2 ], m[ 6 ], m[ 10 ], m[ 14 ],
        m[ 3 ], m[ 7 ], m[ 11 ], m[ 15 ]
      );
    }


      mesh.bind(skeleton, bindMatrix);
    }
  }

  /// Build animations from SkelAnimation prims and time-sampled transforms.
  List<AnimationClip> _buildAnimations() {
    final List<AnimationClip> animations = [];

    // Find all SkelAnimation prims
    for (final String path in specsByPath.keys) {
      final dynamic spec = specsByPath[path];
      if (spec == null) continue;

      final int specType = spec['specType'] is int 
          ? spec['specType'] as int 
          : (spec['specType'] is SpecType ? (spec['specType'] as SpecType).value : 0);

      if (specType != SpecType.prim.value) continue;

      final Map<String, dynamic> fields = (spec['fields'] is Map<String, dynamic>)
          ? spec['fields'] as Map<String, dynamic>
          : {};

      if (fields['typeName'] == 'SkelAnimation') {
        final AnimationClip? clip = _buildAnimationClip(path);
        if (clip != null) {
          animations.add(clip);
        }
      }
    }

    // Build transform animations from time-sampled xformOps
    // Assuming _buildTransformAnimations returns a List<KeyframeTrack>
    final List<dynamic> transformTracksRaw = _buildTransformAnimations();
    
    if (transformTracksRaw.isNotEmpty) {
      final List<KeyframeTrack> transformTracks = List<KeyframeTrack>.from(transformTracksRaw);
      
      // In three_js_animations, AnimationClip constructor parameters mirror Three.js:
      // AnimationClip(String name, double duration, List<KeyframeTrack> tracks)
      animations.add(AnimationClip(
        'TransformAnimation', 
        -1.0, 
        transformTracks,
      ));
    }

    return animations;
  }

  /// Build transform animations from time-sampled xformOps.
  List<KeyframeTrack> _buildTransformAnimations() {
    final List<KeyframeTrack> tracks = [];

    for (final String path in specsByPath.keys) {
      final dynamic spec = specsByPath[path];
      if (spec == null) continue;

      final int specType = spec['specType'] is int 
          ? spec['specType'] as int 
          : (spec['specType'] is SpecType ? (spec['specType'] as SpecType).value : 0);

      if (specType != SpecType.prim.value) continue;

      final Map<String, dynamic> fields = (spec['fields'] is Map<String, dynamic>)
          ? spec['fields'] as Map<String, dynamic>
          : {};

      final String typeName = fields['typeName']?.toString() ?? '';
      if (typeName != 'Xform' && typeName != 'Scope' && typeName != 'Mesh') continue;

      final String objectName = path.split('/').lastOrNull ?? '';

      // 1. Check for animated xformOp:orient
      final String orientPath = '$path.xformOp:orient';
      final dynamic orientSpec = specsByPath[orientPath];
      if (orientSpec != null && orientSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> oFields = orientSpec['fields'] as Map<String, dynamic>;
        final dynamic timeSamples = oFields['timeSamples'];
        
        if (timeSamples is Map<String, dynamic>) {
          final List<dynamic> times = timeSamples['times'] as List? ?? [];
          final List<dynamic> values = timeSamples['values'] as List? ?? [];

          final List<double> keyframeTimes = [];
          final List<double> keyframeValues = [];

          for (int i = 0; i < times.length; i++) {
            keyframeTimes.add((times[i] as num).toDouble() / fps);
            final dynamic q = values[i];
            if (q is List && q.length >= 4) {
              keyframeValues.addAll([
                (q[0] as num).toDouble(),
                (q[1] as num).toDouble(),
                (q[2] as num).toDouble(),
                (q[3] as num).toDouble(),
              ]);
            }
          }

          if (keyframeTimes.isNotEmpty) {
            tracks.add(QuaternionKeyframeTrack(
              '$objectName.quaternion',
              Float32List.fromList(keyframeTimes),
              Float32List.fromList(keyframeValues),
            ));
          }
        }
      }

      // 2. Check for animated xformOp:rotateXYZ
      final String rotateXYZPath = '$path.xformOp:rotateXYZ';
      final dynamic rotateXYZSpec = specsByPath[rotateXYZPath];
      if (rotateXYZSpec != null && rotateXYZSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> rFields = rotateXYZSpec['fields'] as Map<String, dynamic>;
        final dynamic timeSamples = rFields['timeSamples'];

        if (timeSamples is Map<String, dynamic>) {
          final List<dynamic> times = timeSamples['times'] as List? ?? [];
          final List<dynamic> values = timeSamples['values'] as List? ?? [];

          final List<double> keyframeTimes = [];
          final List<double> keyframeValues = [];
          
          final Euler tempEuler = Euler();
          final Quaternion tempQuat = Quaternion();

          for (int i = 0; i < times.length; i++) {
            keyframeTimes.add((times[i] as num).toDouble() / fps);
            final dynamic r = values[i];
            if (r is List && r.length >= 3) {
              // USD rotateXYZ: matrix = Rx * Ry * Rz, use 'ZYX' order in Three.js
              tempEuler.set(
                (r[0] as num).toDouble() * math.pi / 180.0,
                (r[1] as num).toDouble() * math.pi / 180.0,
                (r[2] as num).toDouble() * math.pi / 180.0,
                RotationOrders.zyx,
              );
              tempQuat.setFromEuler(tempEuler);
              keyframeValues.addAll([tempQuat.x, tempQuat.y, tempQuat.z, tempQuat.w]);
            }
          }

          if (keyframeTimes.isNotEmpty) {
            tracks.add(QuaternionKeyframeTrack(
              '$objectName.quaternion',
              Float32List.fromList(keyframeTimes),
              Float32List.fromList(keyframeValues),
            ));
          }
        }
      }

      // 3. Check for animated xformOp:translate
      final String translatePath = '$path.xformOp:translate';
      final dynamic translateSpec = specsByPath[translatePath];
      if (translateSpec != null && translateSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> tFields = translateSpec['fields'] as Map<String, dynamic>;
        final dynamic timeSamples = tFields['timeSamples'];

        if (timeSamples is Map<String, dynamic>) {
          final List<dynamic> times = timeSamples['times'] as List? ?? [];
          final List<dynamic> values = timeSamples['values'] as List? ?? [];

          final List<double> keyframeTimes = [];
          final List<double> keyframeValues = [];

          for (int i = 0; i < times.length; i++) {
            keyframeTimes.add((times[i] as num).toDouble() / fps);
            final dynamic t = values[i];
            if (t is List && t.length >= 3) {
              keyframeValues.addAll([
                (t[0] as num).toDouble(),
                (t[1] as num).toDouble(),
                (t[2] as num).toDouble(),
              ]);
            }
          }

          if (keyframeTimes.isNotEmpty) {
            tracks.add(VectorKeyframeTrack(
              '$objectName.position',
              Float32List.fromList(keyframeTimes),
              Float32List.fromList(keyframeValues),
            ));
          }
        }
      }

      // 4. Check for animated xformOp:scale
      final String scalePath = '$path.xformOp:scale';
      final dynamic scaleSpec = specsByPath[scalePath];
      if (scaleSpec != null && scaleSpec['fields'] is Map<String, dynamic>) {
        final Map<String, dynamic> sFields = scaleSpec['fields'] as Map<String, dynamic>;
        final dynamic timeSamples = sFields['timeSamples'];

        if (timeSamples is Map<String, dynamic>) {
          final List<dynamic> times = timeSamples['times'] as List? ?? [];
          final List<dynamic> values = timeSamples['values'] as List? ?? [];

          final List<double> keyframeTimes = [];
          final List<double> keyframeValues = [];

          for (int i = 0; i < times.length; i++) {
            keyframeTimes.add((times[i] as num).toDouble() / fps);
            final dynamic s = values[i];
            if (s is List && s.length >= 3) {
              keyframeValues.addAll([
                (s[0] as num).toDouble(),
                (s[1] as num).toDouble(),
                (s[2] as num).toDouble(),
              ]);
            }
          }

          if (keyframeTimes.isNotEmpty) {
            tracks.add(VectorKeyframeTrack(
              '$objectName.scale',
              Float32List.fromList(keyframeTimes),
              Float32List.fromList(keyframeValues),
            ));
          }
        }
      }

      // 5. Check for animated xformOp:transform (matrix animations)
      final dynamic propertiesRaw = fields['properties'];
      final List<dynamic> properties = propertiesRaw is List ? propertiesRaw : [];

      for (final dynamic propEntry in properties) {
        final String prop = propEntry.toString();
        if (!prop.startsWith('xformOp:transform')) continue;

        final String transformPath = '$path.$prop';
        final dynamic transformSpec = specsByPath[transformPath];
        if (transformSpec == null || transformSpec['fields'] is! Map<String, dynamic>) continue;

        final Map<String, dynamic> trFields = transformSpec['fields'] as Map<String, dynamic>;
        final dynamic timeSamples = trFields['timeSamples'];
        if (timeSamples is! Map<String, dynamic>) continue;

        final List<dynamic> times = timeSamples['times'] as List? ?? [];
        final List<dynamic> values = timeSamples['values'] as List? ?? [];

        final List<double> positionTimes = [];
        final List<double> positionValues = [];
        final List<double> quaternionTimes = [];
        final List<double> quaternionValues = [];
        final List<double> scaleTimes = [];
        final List<double> scaleValues = [];

        final Matrix4 matrix = Matrix4();
        final Vector3 position = Vector3();
        final Quaternion quaternion = Quaternion();
        final Vector3 scale = Vector3();

        for (int i = 0; i < times.length; i++) {
          final dynamic mRaw = values[i];
          if (mRaw is! List || mRaw.length < 16) continue;

          final List<double> m = List<double>.from(mRaw.map((v) => (v as num).toDouble()));
          final double t = (times[i] as num).toDouble() / fps;

          matrix.setValues(
            m[ 0 ], m[ 4 ], m[ 8 ], m[ 12 ],
            m[ 1 ], m[ 5 ], m[ 9 ], m[ 13 ],
            m[ 2 ], m[ 6 ], m[ 10 ], m[ 14 ],
            m[ 3 ], m[ 7 ], m[ 11 ], m[ 15 ]
          );
          matrix.decompose(position, quaternion, scale);

          positionTimes.add(t);
          positionValues.addAll([position.x, position.y, position.z]);

          quaternionTimes.add(t);
          quaternionValues.addAll([quaternion.x, quaternion.y, quaternion.z, quaternion.w]);

          scaleTimes.add(t);
          scaleValues.addAll([scale.x, scale.y, scale.z]);
        }

        if (positionTimes.isNotEmpty) {
          tracks.add(VectorKeyframeTrack(
            '$objectName.position',
            Float32List.fromList(positionTimes),
            Float32List.fromList(positionValues),
          ));
          tracks.add(QuaternionKeyframeTrack(
            '$objectName.quaternion',
            Float32List.fromList(quaternionTimes),
            Float32List.fromList(quaternionValues),
          ));
          tracks.add(VectorKeyframeTrack(
            '$objectName.scale',
            Float32List.fromList(scaleTimes),
            Float32List.fromList(scaleValues),
          ));
        }
        break; // Only process first transform op
      }
    }

    return tracks;
  }

  /// Build an AnimationClip for a SkelAnimation prim.
  AnimationClip? _buildAnimationClip(String path) {
    final Map<String, dynamic> attrs = _getAttributes(path);
    
    final dynamic jointsRaw = attrs['joints'];
    if (jointsRaw is! List || jointsRaw.isEmpty) return null;
    final List<String> joints = List<String>.from(jointsRaw.map((e) => e.toString()));

    final List<KeyframeTrack> tracks = [];

    // 1. Get rotation time samples
    final dynamic rotationsAttr = _getTimeSampledAttribute(path, 'rotations');
    if (rotationsAttr != null && rotationsAttr is Map<String, dynamic>) {
      final List<dynamic> times = rotationsAttr['times'] as List? ?? [];
      final List<dynamic> values = rotationsAttr['values'] as List? ?? [];

      for (int jointIdx = 0; jointIdx < joints.length; jointIdx++) {
        final String jointName = joints[jointIdx].split('/').lastOrNull ?? '';
        final List<double> keyframeTimes = [];
        final List<double> keyframeValues = [];

        for (int t = 0; t < times.length; t++) {
          final dynamic quatData = values[t];
          if (quatData is! List || quatData.length < (jointIdx + 1) * 4) continue;

          keyframeTimes.add((times[t] as num).toDouble() / fps);
          
          // USD GfQuatf stores imaginary (x,y,z) first, then real (w)
          // This matches Three.js quaternion order (x,y,z,w)
          final int baseOffset = jointIdx * 4;
          final double x = (quatData[baseOffset + 0] as num).toDouble();
          final double y = (quatData[baseOffset + 1] as num).toDouble();
          final double z = (quatData[baseOffset + 2] as num).toDouble();
          final double w = (quatData[baseOffset + 3] as num).toDouble();
          
          keyframeValues.addAll([x, y, z, w]);
        }

        if (keyframeTimes.isNotEmpty) {
          tracks.add(QuaternionKeyframeTrack(
            '$jointName.quaternion',
            Float32List.fromList(keyframeTimes),
            Float32List.fromList(keyframeValues),
          ));
        }
      }
    }

    // 2. Get translation time samples
    final dynamic translationsAttr = _getTimeSampledAttribute(path, 'translations');
    if (translationsAttr != null && translationsAttr is Map<String, dynamic>) {
      final List<dynamic> times = translationsAttr['times'] as List? ?? [];
      final List<dynamic> values = translationsAttr['values'] as List? ?? [];

      for (int jointIdx = 0; jointIdx < joints.length; jointIdx++) {
        final String jointName = joints[jointIdx].split('/').lastOrNull ?? '';
        final List<double> keyframeTimes = [];
        final List<double> keyframeValues = [];

        for (int t = 0; t < times.length; t++) {
          final dynamic transData = values[t];
          if (transData is! List || transData.length < (jointIdx + 1) * 3) continue;

          keyframeTimes.add((times[t] as num).toDouble() / fps);
          
          final int baseOffset = jointIdx * 3;
          keyframeValues.addAll([
            (transData[baseOffset + 0] as num).toDouble(),
            (transData[baseOffset + 1] as num).toDouble(),
            (transData[baseOffset + 2] as num).toDouble(),
          ]);
        }

        if (keyframeTimes.isNotEmpty) {
          tracks.add(VectorKeyframeTrack(
            '$jointName.position',
            Float32List.fromList(keyframeTimes),
            Float32List.fromList(keyframeValues),
          ));
        }
      }
    }

    // 3. Get scale time samples
    final dynamic scalesAttr = _getTimeSampledAttribute(path, 'scales');
    if (scalesAttr != null && scalesAttr is Map<String, dynamic>) {
      final List<dynamic> times = scalesAttr['times'] as List? ?? [];
      final List<dynamic> values = scalesAttr['values'] as List? ?? [];

      for (int jointIdx = 0; jointIdx < joints.length; jointIdx++) {
        final String jointName = joints[jointIdx].split('/').lastOrNull ?? '';
        final List<double> keyframeTimes = [];
        final List<double> keyframeValues = [];

        for (int t = 0; t < times.length; t++) {
          final dynamic scaleData = values[t];
          if (scaleData is! List || scaleData.length < (jointIdx + 1) * 3) continue;

          keyframeTimes.add((times[t] as num).toDouble() / fps);
          
          final int baseOffset = jointIdx * 3;
          keyframeValues.addAll([
            (scaleData[baseOffset + 0] as num).toDouble(),
            (scaleData[baseOffset + 1] as num).toDouble(),
            (scaleData[baseOffset + 2] as num).toDouble(),
          ]);
        }

        if (keyframeTimes.isNotEmpty) {
          tracks.add(VectorKeyframeTrack(
            '$jointName.scale',
            Float32List.fromList(keyframeTimes),
            Float32List.fromList(keyframeValues),
          ));
        }
      }
    }

    if (tracks.isEmpty) return null;

    final String clipName = path.split('/').lastOrNull ?? 'SkelAnimation';
    return AnimationClip(clipName, -1.0, tracks);
  }

/// Get a time-sampled attribute map from specsByPath.
Map<String, dynamic>? _getTimeSampledAttribute(String primPath, String attrName) {
  final String attrPath = '$primPath.$attrName';
  final dynamic attrSpec = specsByPath[attrPath];

  if (attrSpec != null && attrSpec['fields'] is Map<String, dynamic>) {
    final Map<String, dynamic> fields = attrSpec['fields'] as Map<String, dynamic>;
    final dynamic timeSamples = fields['timeSamples'];

    if (timeSamples is Map<String, dynamic>) {
      final dynamic times = timeSamples['times'];
      final dynamic values = timeSamples['values'];
      
      if (times is List && values is List) {
        return timeSamples;
      }
    }
  }
  return null;
}

  /// Flattens a matrix array which could be nested arrays (USDA) or flat arrays (USDC).
  List<double>? _flattenMatrixArray(dynamic matrices, int numMatrices) {
    if (matrices is! List || matrices.isEmpty) return null;

    // If already a flat numerical array, cast safely and return
    if (matrices.first is num) {
      return List<double>.from(matrices.map((v) => (v as num).toDouble()));
    }

    final List<double> flatArray = [];

    for (int m = 0; m < numMatrices; m++) {
      for (int row = 0; row < 4; row++) {
        final int matrixRowIndex = m * 4 + row;
        
        dynamic rowData;
        if (matrixRowIndex >= 0 && matrixRowIndex < matrices.length) {
          rowData = matrices[matrixRowIndex];
        }

        if (rowData is List && rowData.length == 4) {
          flatArray.addAll([
            (rowData[0] as num).toDouble(),
            (rowData[1] as num).toDouble(),
            (rowData[2] as num).toDouble(),
            (rowData[3] as num).toDouble(),
          ]);
        } else {
          // Fallback to identity matrix diagonal rows if data is missing/malformed
          flatArray.addAll([
            row == 0 ? 1.0 : 0.0,
            row == 1 ? 1.0 : 0.0,
            row == 2 ? 1.0 : 0.0,
            row == 3 ? 1.0 : 0.0,
          ]);
        }
      }
    }

    return flatArray;
  }
}