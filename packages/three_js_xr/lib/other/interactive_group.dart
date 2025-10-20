import 'package:flutter/widgets.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_xr/three_js_xr.dart';

final _pointer = Vector2.fromJson();
final _event = Event(type: '', data: _pointer );

// The XR events that are mapped to "standard" pointer events.
final _events = {
	'move': 'mousemove',
	'select': 'click',
	'selectstart': 'mousedown',
	'selectend': 'mouseup'
};

final _raycaster = Raycaster();

class InteractiveGroup extends Group {
  Raycaster raycaster = Raycaster();
  PeripheralsState? element;
  Camera? camera;
  List<WebXRController> controllers = [];

	InteractiveGroup():super();

	void onPointerEvent(event ) {
		//event.stopPropagation();

		final rb = element?.context.findRenderObject() as RenderBox;//element.getBoundingClientRect();
    final rect = rb.paintBounds;
    
		_pointer.x = ( event.clientX - rect.left ) / rect.width * 2 - 1;
		_pointer.y = - ( event.clientY - rect.top ) / rect.height * 2 + 1;

		raycaster.setFromCamera( _pointer, camera! );

		final intersects = raycaster.intersectObjects( children, false );

		if ( intersects.isNotEmpty ) {
			final intersection = intersects[ 0 ];

			final object = intersection.object;
			final uv = intersection.uv;

			_event.type = event.type;
			_event.data.setValues( uv!.x, 1 - uv.y );

			object?.dispatchEvent( _event );
		}
	}

	void onXRControllerEvent(Event event ) {
		final controller = event.target;

		_raycaster.setFromXRController( controller );

		final intersections = _raycaster.intersectObjects( children, false );

		if ( intersections.isNotEmpty) {
			final intersection = intersections[ 0 ];
			final object = intersection.object;
			final uv = intersection.uv;

			_event.type = _events[ event.type ];
			_event.data.setValues( uv!.x, 1 - uv.y );

			object?.dispatchEvent( _event );
		}
	}

	void listenToPointerEvents( renderer, Camera camera ) {
		this.camera = camera;
		element = renderer.domElement;
		element?.addEventListener( PeripheralType.pointerdown, onPointerEvent );
		element?.addEventListener( PeripheralType.pointerup, onPointerEvent );
		element?.addEventListener( PeripheralType.pointermove, onPointerEvent );
		// element?.addEventListener( 'mousedown', onPointerEvent );
		// element?.addEventListener( 'mouseup', onPointerEvent );
		// element?.addEventListener( 'mousemove', onPointerEvent );
		// element?.addEventListener( 'click', onPointerEvent );
	}

	void disconnectionPointerEvents() {
		if ( element != null ) {
			element?.removeEventListener( PeripheralType.pointerdown, onPointerEvent );
			element?.removeEventListener( PeripheralType.pointerup, onPointerEvent );
			element?.removeEventListener( PeripheralType.pointermove, onPointerEvent );
			// element?.removeEventListener( 'mousedown', onPointerEvent );
			// element?.removeEventListener( 'mouseup', onPointerEvent );
			// element?.removeEventListener( 'mousemove', onPointerEvent );
			// element?.removeEventListener( 'click', onPointerEvent );
		}
	}

	void listenToXRControllerEvents(WebXRController controller ) {
		controllers.add( controller );
		controller.addEventListener( 'move', onXRControllerEvent );
		controller.addEventListener( 'select', onXRControllerEvent );
		controller.addEventListener( 'selectstart', onXRControllerEvent );
		controller.addEventListener( 'selectend', onXRControllerEvent );
	}

	void disconnectXrControllerEvents() {
		for ( final controller in controllers ) {
			controller.removeEventListener( 'move', onXRControllerEvent );
			controller.removeEventListener( 'select', onXRControllerEvent );
			controller.removeEventListener( 'selectstart', onXRControllerEvent );
			controller.removeEventListener( 'selectend', onXRControllerEvent );
		}
	}

	void disconnect() {
		disconnectionPointerEvents();
		disconnectXrControllerEvents();
		camera = null;
		element = null;
		controllers = [];
	}
}
