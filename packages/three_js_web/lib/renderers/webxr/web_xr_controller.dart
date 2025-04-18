import 'package:three_js_math/three_js_math.dart';
import '../../objects/index.dart';

final _moveEvent = {'type': 'move'};

class WebXRController {
  dynamic _targetRay;
  dynamic _grip;
  dynamic _hand;

	WebXRController();

	getHandSpace(){
		if(_hand == null) {
			_hand = Group();
			_hand!.matrixAutoUpdate = false;
			_hand!.visible = false;

			_hand.joints = {};
			_hand.inputState = {'pinching': false };
		}

		return _hand;
	}

	getTargetRaySpace() {
		if ( _targetRay == null ) {
			_targetRay = Group();
			_targetRay.matrixAutoUpdate = false;
			_targetRay.visible = false;
			_targetRay.hasLinearVelocity = false;
			_targetRay.linearVelocity = Vector3.zero();
			_targetRay.hasAngularVelocity = false;
			_targetRay.angularVelocity = Vector3.zero();

		}

		return _targetRay;
	}

	getGripSpace() {
		if (_grip == null ) {
			_grip = Group();
			_grip.matrixAutoUpdate = false;
			_grip.visible = false;
			_grip.hasLinearVelocity = false;
			_grip.linearVelocity = Vector3.zero();
			_grip.hasAngularVelocity = false;
			_grip.angularVelocity = Vector3.zero();
		}

		return _grip;
	}

	WebXRController dispatchEvent( event ) {
		if ( _targetRay != null ) {
			_targetRay.dispatchEvent( event );
		}

		if ( _grip != null ) {
			_grip.dispatchEvent( event );
		}

		if ( _hand != null ) {
			_hand.dispatchEvent( event );
		}

		return this;
	}

	WebXRController disconnect( inputSource ) {
		dispatchEvent({'type': 'disconnected', 'data': inputSource});

		if ( _targetRay != null ) {
			_targetRay.visible = false;
		}

		if ( _grip != null ) {
			_grip.visible = false;
		}

		if ( _hand != null ) {
			_hand!.visible = false;
		}

		return this;
	}

	WebXRController update(inputSource, frame, referenceSpace ) {
		dynamic inputPose;
		dynamic gripPose;
		dynamic handPose;

		final targetRay = _targetRay;
		final grip = _grip;
		final hand = _hand;

		if ( inputSource && frame.session.visibilityState != 'visible-blurred' ) {
			if ( targetRay != null ) {
				inputPose = frame.getPose( inputSource.targetRaySpace, referenceSpace );

				if ( inputPose != null ) {
					targetRay.matrix.fromArray( inputPose.transform.matrix );
					targetRay.matrix.decompose( targetRay.position, targetRay.rotation, targetRay.scale );

					if ( inputPose.linearVelocity ) {
						targetRay.hasLinearVelocity = true;
						targetRay.linearVelocity.copy( inputPose.linearVelocity );
					} 
          else {
						targetRay.hasLinearVelocity = false;
					}

					if ( inputPose.angularVelocity ) {
						targetRay.hasAngularVelocity = true;
						targetRay.angularVelocity.copy( inputPose.angularVelocity );
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

				if ( hand.inputState.pinching && distance > distanceToPinch + threshold ) {
					hand.inputState.pinching = false;
					dispatchEvent({
						'type': 'pinchend',
						'handedness': inputSource.handedness,
						'target': this
					});
				} 
        else if ( ! hand.inputState.pinching && distance <= distanceToPinch - threshold ) {

					hand.inputState.pinching = true;
					dispatchEvent({
						'type': 'pinchstart',
						'handedness': inputSource.handedness,
						'target': this
					});
				}
			} 
      else {
				if ( grip != null && inputSource.gripSpace ) {
					gripPose = frame.getPose( inputSource.gripSpace, referenceSpace );

					if ( gripPose != null ) {
						grip.matrix.fromArray( gripPose.transform.matrix );
						grip.matrix.decompose( grip.position, grip.rotation, grip.scale );

						if ( gripPose.linearVelocity ) {
							grip.hasLinearVelocity = true;
							grip.linearVelocity.copy( gripPose.linearVelocity );
						} 
            else {
							grip.hasLinearVelocity = false;
						}

						if ( gripPose.angularVelocity ) {
							grip.hasAngularVelocity = true;
							grip.angularVelocity.copy( gripPose.angularVelocity );
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
			hand.visible = ( handPose != null );
		}

		return this;
	}
}
