import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_xr/app/index.dart';
import 'package:three_js_xr/renderer/index.dart';

class XRPlanes extends Object3D {

	XRPlanes(WebGLRenderer renderer ):super(){
		final matrix = Matrix4();
		final currentPlanes = {};
		final xr = renderer.xr as WebXRWorker;

		xr.addEventListener( 'planesdetected', (event){
			final frame = event.data as XRFrame;
			final planes = frame.detectedPlanesMap;
      if(planes != null){
        final referenceSpace = xr.getReferenceSpace();

        bool planeschanged = false;

        for ( final plane in currentPlanes.keys ) {
          final Mesh? mesh = currentPlanes[plane];
          if ( planes.containsKey( plane ) == false ) {
            mesh!.geometry?.dispose();
            mesh.material?.dispose();
            remove( mesh );

            currentPlanes.remove( plane );
            planeschanged = true;
          }
        }

        for (final plane in planes.keys ) {
          if ( !currentPlanes.containsKey( plane )) {
            final pose = frame.getPose( plane.planeSpace, referenceSpace !)!;
            matrix.copyFromUnknown( pose.transform!.array);

            final polygon = plane.polygon;

            int minX = double.maxFinite.toInt();
            int maxX = -double.maxFinite.toInt();
            int minZ = double.maxFinite.toInt();
            int maxZ = -double.maxFinite.toInt();

            for ( final point in polygon ) {
              minX = math.min( minX, point.x );
              maxX = math.max( maxX, point.x );
              minZ = math.min( minZ, point.z );
              maxZ = math.max( maxZ, point.z );
            }

            final width = maxX - minX;
            final height = maxZ - minZ;

            final geometry = BoxGeometry( width.toDouble(), 0.01, height.toDouble() );
            final material = MeshBasicMaterial.fromMap( { 'color': (0xffffff * math.Random().nextDouble().toInt()) } );

            final mesh = Mesh( geometry, material );
            mesh.position.setFromMatrixPosition( matrix );
            mesh.quaternion.setFromRotationMatrix( matrix );
            add( mesh );

            currentPlanes[plane] =  mesh;
            planeschanged = true;
          }
        }

        if ( planeschanged ) {
          dispatchEvent(Event(type: 'planeschanged' ));
        }
      }
		});
	}
}