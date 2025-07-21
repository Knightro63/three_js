import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/objects/clipping_group.dart';
import 'package:three_js_math/three_js_math.dart';

final _plane = Plane();

/**
 * Represents the state that is used to perform clipping via clipping planes.
 * There is a default clipping context for each render context. When the
 * scene holds instances of `ClippingGroup`, there will be a context for each
 * group.
 *
 * @private
 */
class ClippingContext {
  ClippingContext? parentContext;
  int version = 0;
  bool? clipIntersection;
  String cacheKey = '';
  bool shadowPass = false;
  Matrix3 viewNormalMatrix = Matrix3.identity();
  WeakMap clippingGroupContexts = WeakMap();
  List<Vector4> intersectionPlanes = [];
  List<Vector4> unionPlanes = [];
  int? parentVersion;
  Matrix4 viewMatrix = Matrix4.identity();

	ClippingContext(this.parentContext) {
		if ( parentContext != null ) {
			this.viewNormalMatrix = parentContext!.viewNormalMatrix;
			this.clippingGroupContexts = parentContext!.clippingGroupContexts;

			this.shadowPass = parentContext!.shadowPass;
			this.viewMatrix = parentContext!.viewMatrix;
		}
	}

	void projectPlanes(List<Plane> source, List<Vector4> destination, int offset ) {
		final l = source.length;

		for ( int i = 0; i < l; i ++ ) {
			_plane.copyFrom( source[ i ] ).applyMatrix4( this.viewMatrix, this.viewNormalMatrix );

			final v = destination[ offset + i ];
			final normal = _plane.normal;

			v.x = - normal.x;
			v.y = - normal.y;
			v.z = - normal.z;
			v.w = _plane.constant;
		}
	}

	void updateGlobal(Scene scene, Camera camera ) {
		this.shadowPass = ( scene.overrideMaterial != null && scene.overrideMaterial.isShadowPassMaterial );
		this.viewMatrix = camera.matrixWorldInverse;

		this.viewNormalMatrix.getNormalMatrix( this.viewMatrix );
	}

	void update(ClippingContext parentContext, ClippingGroup clippingGroup ) {

		bool update = false;

		if ( parentContext.version != this.parentVersion ) {
			this.intersectionPlanes = parentContext.intersectionPlanes.sublist(0);
			this.unionPlanes = parentContext.unionPlanes.sublist(0);
			this.parentVersion = parentContext.version;
		}

		if ( this.clipIntersection != clippingGroup.clipIntersection ) {
			this.clipIntersection = clippingGroup.clipIntersection;

			if ( this.clipIntersection == true) {
				this.unionPlanes.length = parentContext.unionPlanes.length;
			} 
      else {
				this.intersectionPlanes.length = parentContext.intersectionPlanes.length;
			}
		}

		final srcClippingPlanes = clippingGroup.clippingPlanes;
		final l = srcClippingPlanes.length;

		dynamic dstClippingPlanes;
		int offset;

		if ( this.clipIntersection == true) {
			dstClippingPlanes = this.intersectionPlanes;
			offset = parentContext.intersectionPlanes.length;
		} 
    else {
			dstClippingPlanes = this.unionPlanes;
			offset = parentContext.unionPlanes.length;
		}

		if ( dstClippingPlanes.length != offset + l ) {
			dstClippingPlanes.length = offset + l;

			for (int i = 0; i < l; i ++ ) {
				dstClippingPlanes[ offset + i ] = new Vector4();
			}

			update = true;
		}

		this.projectPlanes( srcClippingPlanes, dstClippingPlanes, offset );
		if ( update ) {
			this.version ++;
			this.cacheKey = '${ this.intersectionPlanes.length }:${ this.unionPlanes.length }';
		}
	}

	ClippingContext getGroupContext(ClippingGroup clippingGroup ) {
		if ( this.shadowPass && ! clippingGroup.clipShadows ) return this;
		ClippingContext? context = this.clippingGroupContexts.get( clippingGroup );

		if ( context == null ) {
			context = ClippingContext( this );
			this.clippingGroupContexts.set( clippingGroup, context );
		}

		context.update( this, clippingGroup );
		return context;
	}

	int get unionClippingCount => this.unionPlanes.length;
}
