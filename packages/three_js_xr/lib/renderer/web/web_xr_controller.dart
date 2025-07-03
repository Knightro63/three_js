import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../../app/web/wrapper.dart';

final Event _moveEvent = Event(type: 'move');

class WebXRController extends Object3D{
  bool isGroup = true;
  bool hasLinearVelocity = false;
  Vector3 linearVelocity = Vector3.zero();
	bool hasAngularVelocity = false;
	Vector3 angularVelocity = Vector3.zero();
  Map joints = {};
  Map<String,dynamic> inputState = {'pinching': false};
  
  WebXRController? _targetRay;
  WebXRController? _grip;
  WebXRController? _hand;

	WebXRController();

	WebXRController? getHandSpace(){
		if(_hand == null) {
			_hand = WebXRController();
			_hand!.matrixAutoUpdate = false;
			_hand!.visible = false;

			_hand!.joints = {};
			_hand!.inputState = {'pinching': false };
		}

		return _hand;
	}

	WebXRController? getTargetRaySpace() {
		if ( _targetRay == null ) {
			_targetRay = WebXRController();
			_targetRay!.matrixAutoUpdate = false;
			_targetRay!.visible = false;
			_targetRay!.hasLinearVelocity = false;
			_targetRay!.linearVelocity = Vector3.zero();
			_targetRay!.hasAngularVelocity = false;
			_targetRay!.angularVelocity = Vector3.zero();
		}

		return _targetRay;
	}

	WebXRController? getGripSpace() {
		if (_grip == null ) {
			_grip = WebXRController();
			_grip!.matrixAutoUpdate = false;
			_grip!.visible = false;
			_grip!.hasLinearVelocity = false;
			_grip!.linearVelocity = Vector3.zero();
			_grip!.hasAngularVelocity = false;
			_grip!.angularVelocity = Vector3.zero();
		}

		return _grip;
	}

  @override
	WebXRController dispatchEvent( event ) {
    super.dispatchEvent(event);

		_targetRay?.dispatchEvent( event );
		_grip?.dispatchEvent( event );
		_hand?.dispatchEvent( event );

		return this;
	}

	WebXRController disconnect(XRInputSource inputSource ) {
		dispatchEvent(Event(type: 'disconnected', data: inputSource));
		_targetRay?.visible = false;
		_grip?.visible = false;
		_hand?.visible = false;

		return this;
	}

	WebXRController update(XRInputSource? inputSource, XRFrame frame, XRReferenceSpace referenceSpace ) {
		dynamic inputPose;
		dynamic gripPose;
		bool handPose = false;

		final WebXRController? targetRay = _targetRay;
		final WebXRController? grip = _grip;
		final WebXRController? hand = _hand;

		if ( inputSource != null && frame.session.visibilityState != 'visible-blurred' ) {
			if ( targetRay != null ) {
				inputPose = frame.getPose( inputSource.targetRaySpace, referenceSpace );

				if ( inputPose != null ) {
					targetRay.matrix.copyFromUnknown( inputPose.transform.matrix );
					targetRay.matrix.decomposeEuler( targetRay.position, targetRay.rotation, targetRay.scale );

					if ( inputPose.linearVelocity ) {
						targetRay.hasLinearVelocity = true;
						targetRay.linearVelocity.setFrom( inputPose.linearVelocity );
					} 
          else {
						targetRay.hasLinearVelocity = false;
					}

					if ( inputPose.angularVelocity ) {
						targetRay.hasAngularVelocity = true;
						targetRay.angularVelocity.setFrom( inputPose.angularVelocity );
					} 
          else {
						targetRay.hasAngularVelocity = false;
					}

					dispatchEvent( _moveEvent );
				}
			}

			if ( hand != null && inputSource.hand ) {
				handPose = true;

				for ( final inputjoint in inputSource.hand.values() ) {
					// Update the joints groups with the XRJoint poses
					final jointPose = frame.getJointPose( inputjoint, referenceSpace );

					if ( hand.joints[ inputjoint.jointName ] == null ) {
						// The transform of this joint will be updated with the joint pose on each frame
						final joint = Group();
						joint.matrixAutoUpdate = false;
						joint.visible = false;
						hand.joints[ inputjoint.jointName ] = joint;
						// ??
						hand.add( joint );
					}

					final joint = hand.joints[ inputjoint.jointName ];

					if ( jointPose != null ) {
						joint.matrix.fromArray( jointPose.transform.matrix );
						joint.matrix.decompose( joint.position, joint.rotation, joint.scale );
						joint.jointRadius = jointPose.radius;
					}

					joint.visible = jointPose != null;
				}

				// Custom events

				// Check pinchz
				final indexTip = hand.joints[ 'index-finger-tip' ];
				final thumbTip = hand.joints[ 'thumb-tip' ];
				final distance = indexTip.position.distanceTo( thumbTip.position );

				const distanceToPinch = 0.02;
				const threshold = 0.005;

				if ( hand.inputState['pinching'] && distance > distanceToPinch + threshold ) {
					hand.inputState['pinching'] = false;
					dispatchEvent(Event(
						type: 'pinchend',
						handedness: inputSource.handedness,
						target: this
          ));
				} 
        else if ( ! hand.inputState['pinching'] && distance <= distanceToPinch - threshold ) {

					hand.inputState['pinching'] = true;
					dispatchEvent(Event(
						type: 'pinchstart',
						handedness: inputSource.handedness,
						target: this
          ));
				}
			} 
      else {
				if ( grip != null && inputSource.gripSpace != null) {
					gripPose = frame.getPose( inputSource.gripSpace, referenceSpace );

					if ( gripPose != null ) {
						grip.matrix.copyFromUnknown( gripPose.transform.matrix );
						grip.matrix.decomposeEuler( grip.position, grip.rotation, grip.scale );

						if ( gripPose.linearVelocity ) {
							grip.hasLinearVelocity = true;
							grip.linearVelocity.setFrom( gripPose.linearVelocity );
						} 
            else {
							grip.hasLinearVelocity = false;
						}

						if ( gripPose.angularVelocity ) {
							grip.hasAngularVelocity = true;
							grip.angularVelocity.setFrom( gripPose.angularVelocity );
						} 
            else {
							grip.hasAngularVelocity = false;
						}
					}
				}
			}
		}

		if ( targetRay != null ) {
			targetRay.visible = ( inputPose != null );
		}

		if ( grip != null ) {
			grip.visible = ( gripPose != null );
		}

		if ( hand != null ) {
			hand.visible = handPose;
		}

		return this;
	}
}
