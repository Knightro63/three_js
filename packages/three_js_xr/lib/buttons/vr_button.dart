import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:js_interop';
import 'package:three_js_xr/three_js_xr.dart';

class VRButton extends StatefulWidget{
  const VRButton({super.key,required this.threeJs});
  final ThreeJS threeJs;

  @override
  createState() => _State();
}

class _State extends State<VRButton>{
  bool started = false;
  bool disabled = false;
  bool xrSessionIsGranted = false;
  XRSession? currentSession;

  @override
  void initState(){
    super.initState();
    xrSystem?.addEventListener( 'sessiongranted', (){
			xrSessionIsGranted = true;
		}.jsify());

		xrSystem?.isSessionSupported( 'immersive-vr' ).toDart.then( ( supported ) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(supported.dartify() == false){
          disabled = true;
        }
      });
    });
  }

  Future<void> onSessionEnded() async{
    currentSession?.removeEventListener( 'end', onSessionEnded.jsify() );
    currentSession = null;
    started = false;
  }

  Future<void> onSessionStarted(XRSession session) async{
    await (widget.threeJs.renderer!.xr as WebXRWorker).setSession(currentSession);
    widget.threeJs.renderer?.onXRSessionStart(null);
    session.addEventListener( 'end', onSessionEnded.jsify() );
    started = true;
  }

  void button() async{
    if(!started){
      xrSystem?.requestSession('immersive-vr', {
      'optionalFeatures': [
        'local-floor',
        'bounded-floor',
        'layers']
      }.jsify()).toDart.then((s){
        currentSession = s;
        onSessionStarted(currentSession!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: InkWell(
        onTap: disabled?null:button,
        child: Container(
          width: 100,
          height: 50,
          margin: EdgeInsets.only(bottom: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(width: 2, color: Colors.white),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Text(
            disabled?'VR NOT SUPPORTED':
            !started?'ENTER VR':'EXIT VR'
          ),
        ),
      )
    );
  }
}