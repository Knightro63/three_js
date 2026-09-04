import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class InstancedGroup {
  // Keeps track of the individual sub-pools (e.g., body, armor, weapon meshes)
  final List<InstancedMesh> _subPools = [];
  
  // Stores the relative local matrix offset for each sub-mesh extracted from the source layout
  final List<Matrix4> _localMatrices = [];
  
  final int maxCapacity;
  int _activeCount = 0;

  // Track the current index counter
  int get count => _activeCount;

  // A reusable matrix cache to avoid garbage collection spikes inside intense update loops
  final Matrix4 _tempMatrix = Matrix4.identity();

  InstancedGroup(Object3D source, this.maxCapacity) {
    // We force a local matrix update on the hierarchy chain first so that 
    // object.matrix accurately reflects positions inside the source GLTF group
    source.updateMatrixWorld(true);

    // Automatically traverse the hierarchy layout and allocate matching pools
    source.traverse((object) {
      if (object is Mesh) {
        // Create the individual native target buffer wrapper pool
        final pool = InstancedMesh(object.geometry!, object.material!, maxCapacity);
        
        // Inherit rendering profiles
        pool.castShadow = object.castShadow;
        pool.receiveShadow = object.receiveShadow;
        pool.frustumCulled = false; // Turned off per-mesh; group updates will compute overall bounds
        pool.count = 0; // Initialize dynamic layout trackers
        
        _subPools.add(pool);

        // Crucial step: Capture the explicit local matrix configuration relative to source container
        _localMatrices.add(object.matrix.clone());
      }
    });
  }

  /// Retrieves the root transformation matrix of an instanced group at [index].
  /// 
  /// Because sub-meshes contain local offsets, this calculates the true base 
  /// transformation matrix by multiplying the component's current matrix 
  /// by the inverse of its original local offset.
  Matrix4 getMatrixAt(int index, Matrix4 matrix) {
    if (index >= _activeCount || _subPools.isEmpty) {
      return matrix.identity();
    }

    // Grab the first sub-pool mesh's current transform matrix as our tracking baseline
    _subPools[0].getMatrixAt(index, matrix);

    // Create a temporary matrix to hold the inverse of the first part's local offset
    final Matrix4 inverseLocal = Matrix4.identity().setFrom(_localMatrices[0]).invert();

    // Base Group Matrix = Component World Matrix * Inverse Component Local Offset
    matrix.multiply(inverseLocal);
    
    return matrix;
  }

  /// Retrieves the color of a specific sub-pool component (e.g., armor, weapon) 
  /// at the given [index]. Pass the [subPoolIndex] to specify which part to read.
  Color getColorAt(int index, int subPoolIndex, Color color) {
    if (index >= _activeCount || subPoolIndex >= _subPools.length) {
      return color; // Return unchanged or default if out of bounds
    }

    final pool = _subPools[subPoolIndex];
    if (pool.instanceColor == null) {
      return color.setRGB(1.0, 1.0, 1.0); // Return plain white if instanceColor buffer hasn't been initialized
    }

    return pool.getColorAt(index, color);
  }


  /// Appends a new group instance at the given transform configuration matrix.
  /// Automatically updates inner attributes and marks buffers dirty for the GPU.
  void addGroupInstance(Matrix4 groupTransformMatrix) {
    if (_activeCount >= maxCapacity) return;

    for (int i = 0; i < _subPools.length; i++) {
      final pool = _subPools[i];
      
      // Compute correct placement: Target Position Matrix * Part Offset Matrix
      _tempMatrix.multiply2(groupTransformMatrix, _localMatrices[i]);

      // Write position straight down into the Float32List via your custom native array binder
      pool.setMatrixAt(_activeCount, _tempMatrix);
      pool.count = _activeCount + 1;
      pool.instanceMatrix!.needsUpdate = true;
    }

    _activeCount++;
  }

  /// THE MAGIC BUTTON: Updates every single sub-mesh instance at a specific index in perfect sync!
  void setMatrixAt(int index, Matrix4 groupTransformMatrix) {
    if (index >= _activeCount) return;

    for (int i = 0; i < _subPools.length; i++) {
      final pool = _subPools[i];
      
      // Calculate layout matching offsets: Group World Position * Sub-Mesh Offset
      _tempMatrix.multiply2(groupTransformMatrix, _localMatrices[i]);
      
      pool.setMatrixAt(index, _tempMatrix);
      pool.instanceMatrix!.needsUpdate = true;
    }
  }


  void setColorAt(int index, Color color) {
    for (final pool in _subPools) {
      pool.setColorAt(index, color);
      pool.instanceColor!.needsUpdate = true;
    }
  }

  /// Loops over internal elements to pass matching intersections down to your active Raycaster layout.
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    for (final pool in _subPools) {
      pool.raycast(raycaster, intersects);
    }
  }

  /// Recalculates spatial bounds across the complete pool matrix array to counter view frustum clipping bugs.
  void computeBoundingSpheres() {
    for (final pool in _subPools) {
      pool.computeBoundingSphere();
    }
  }

  /// Commits instances directly to your main active render loop stage
  void addToScene(Scene scene) {
    for (final pool in _subPools) {
      scene.add(pool);
    }
  }

  /// Removes rendering instances away cleanly from the screen graph
  void removeFromScene(Scene scene) {
    for (final pool in _subPools) {
      scene.remove(pool);
    }
  }

  /// Updates the animation pose for a specific group instance by copying morph target weights.
  /// [sourceObjectWithAnimation] should be an animated Object3D instance driven by an AnimationMixer.
  void setMorphAt(int index, Object3D sourceObjectWithAnimation) {
    if (index >= _activeCount) return;

    // We look up meshes inside the animated source object to match our sub-pools
    int meshIndex = 0;
    sourceObjectWithAnimation.traverse((object) {
      if (object is Mesh && meshIndex < _subPools.length) {
        final pool = _subPools[meshIndex];
        
        // Use the native system you have inside your InstancedMesh class
        pool.setMorphAt(index, object);
        
        if (pool.morphTexture != null) {
          pool.morphTexture!.needsUpdate = true;
        }
        meshIndex++;
      }
    });
  }


  /// Explicitly unloads assets allocations from WebGL/Impeller textures pipeline safely
  void dispose() {
    for (final pool in _subPools) {
      pool.dispose();
    }
    _subPools.clear();
    _localMatrices.clear();
    _activeCount = 0;
  }
}
