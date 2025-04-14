import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import '../cameras/index.dart';

final _v1 = Vector3.zero();
final _v2 = Vector3.zero();

/// Level of Detail - show meshes with more or less geometry based on distance
/// from the camera.
///
/// Every level is associated with an object, and rendering can be switched
/// between them at the distances specified. Typically you would create, say,
/// three meshes, one for far away (low detail), one for mid range (medium
/// detail) and one for close up (high detail).
/// 
/// ```
/// final lod = LOD();
///
/// //Create spheres with 3 levels of detail and create new LOD levels for them
/// for( int i = 0; i < 3; i++ ) {
///   final geometry = IcosahedronGeometry( 10, 3 - i );
///   final mesh = Mesh( geometry, material );
///   lod.addLevel( mesh, i * 75 );
/// }
//// 
/// ∂scene.add( lod );
/// ```
/// 
class LOD extends Object3D{
  LOD({
    this.object,
    this.distance = 0
  }):super(){
    type = 'LOD';
    autoUpdate = true;
  }

  Object3D? object;
  double distance = 0;
  List<LOD> levels = [];
  bool isLOD = true;
  int currentLevel = 0;

  @override
	LOD copy(Object3D source, [bool? recursive = true]){
		super.copy(source, false);
    if(source is LOD){
      final levels = source.levels;

      for (int i = 0, l = levels.length; i < l; i ++ ) {
        final level = levels[i];
        addLevel(level.object?.clone(), level.distance );
      }
    }

		autoUpdate = source.autoUpdate;
		return this;
	}

  /// [object] - The [page:Object3D] to display at this level.
  /// 
  /// [distance] - The distance at which to display this level of
  /// detail. Default `0.0`.
  /// 
  /// Adds a mesh that will display at a certain distance and greater. Typically
  /// the further away the distance, the lower the detail on the mesh.
	LOD addLevel([Object3D? object, double distance = 0]){
		this.distance = distance.abs();

		final levels = this.levels;

		int l;

		for ( l = 0; l < levels.length; l ++ ) {
			if ( distance < levels[l].distance ) {
				break;
			}
		}

		levels.insert(l, LOD(distance: distance, object: object));

		add(object);
		return this;
	}

  /// Get the currently active LOD level. As index of the levels array.
	int getCurrentLevel(){
		return currentLevel;
	}

  /// Get a reference to the first [page:Object3D] (mesh) that is greater that [distance].
	Object3D? getObjectForDistance(double distance){
		final levels = this.levels;

		if ( levels.isNotEmpty) {
      int i = 1;
      int l = levels.length;
			for (i = 1; i < l; i ++) {
				if (distance < levels[ i ].distance ) {
					break;
				}
			}
			return levels[i - 1].object;
		}

		return null;
	}

  /// Get intersections between a casted [Ray] and this LOD [Raycaster.intersectObject] will call this method.
  @override
	void raycast(Raycaster raycaster, List<Intersection> intersects){
		final levels = this.levels;
		if (levels.isNotEmpty) {
			_v1.setFromMatrixPosition(matrixWorld);
			final distance = raycaster.ray.origin.distanceTo( _v1 );
			getObjectForDistance(distance)?.raycast( raycaster, intersects );
		}
	}

  /// Set the visibility of each [level]'s [object]
  /// based on distance from the [camera].
	void update(Camera camera){
		final levels = this.levels;

		if ( levels.length > 1 ) {

			_v1.setFromMatrixPosition(camera.matrixWorld);
			_v2.setFromMatrixPosition(matrixWorld);

			final distance = _v1.distanceTo( _v2 ) / camera.zoom;

			levels[0].object?.visible = true;

			int i = 1;
      int l = levels.length;

			for(i = 1; i < l; i ++ ) {
				if ( distance >= levels[ i ].distance ) {
					levels[ i - 1 ].object?.visible = false;
					levels[ i ].object?.visible = true;
				} 
        else {
					break;
				}
			}

			currentLevel = i - 1;
  
			for (;i < l;i++) {
				levels[i].object?.visible = false;
			}
		}
	}

  /// Create a JSON structure with details of this LOD object.
  @override
	Map<String,dynamic> toJson({Object3dMeta? meta}){
		final data = super.toJson(meta:meta);

		if(autoUpdate == false) data['object']['autoUpdate'] = false;

		data['object']['levels'] = [];

		final levels = this.levels;

		for (int i = 0, l = levels.length; i < l; i ++ ) {
			final level = levels[ i ];
			data['object']['levels'].add({
				'object': level.object?.uuid,
				'distance': level.distance
			});
		}

		return data;
	}

  @override
  void dispose(){
    if(disposed) return;
    disposed = true;
    super.dispose();
    object?.dispose();
    levels.forEach((level){
      level.dispose();
    });

    levels.clear();
  }
}
