import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import '../cameras/index.dart';

final _v1 = Vector3.zero();
final _v2 = Vector3.zero();

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

	int getCurrentLevel(){
		return currentLevel;
	}

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

  @override
	void raycast(Raycaster raycaster, List<Intersection> intersects){
		final levels = this.levels;
		if (levels.isNotEmpty) {
			_v1.setFromMatrixPosition(matrixWorld);
			final distance = raycaster.ray.origin.distanceTo( _v1 );
			getObjectForDistance(distance)?.raycast( raycaster, intersects );
		}
	}

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
}
