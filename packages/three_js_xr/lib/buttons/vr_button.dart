import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart';
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
    xrSystem?.addListener( 'sessiongranted', (){
			xrSessionIsGranted = true;
		});

		xrSystem?.isSupported( 'immersive-vr' ).then( ( supported ) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(!supported){
          disabled = true;
        }
      });
    });
  }

  Future<void> onSessionEnded() async{
    currentSession?.dispatchEvent(  Event(type: 'end') );
    currentSession?.removeListener( 'end', onSessionEnded );
    currentSession = null;
    started = false;
  }

  Future<void> onSessionStarted(XRSession session) async{
    await (widget.threeJs.renderer!.xr as WebXRWorker).setSession(currentSession);
    widget.threeJs.renderer?.onXRSessionStart(null);
    session.addListener( 'end', onSessionEnded );
    started = true;
  }

  void button() async{
    if(!started){
      xrSystem?.requestInit('immersive-vr', {
      'optionalFeatures': [
        'local-floor',
        'bounded-floor',
        'layers']
      }).then((s){
        currentSession = s;
        onSessionStarted(currentSession!);
      });
    }
    else{
      onSessionEnded();
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