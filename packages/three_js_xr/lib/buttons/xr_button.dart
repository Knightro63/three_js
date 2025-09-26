import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/three_js_xr.dart';

class XRButton extends StatefulWidget{
  const XRButton({super.key,required this.threeJs});
  final ThreeJS threeJs;

  @override
  createState() => _State();
}

class _State extends State<VRButton>{
  bool started = false;
  bool disabled = false;
  bool xrSessionIsGranted = false;
  bool isAr = false;
  XRSession? currentSession;

  @override
  void initState(){
    super.initState();
    xrSystem?.addListener( 'sessiongranted', (){
			xrSessionIsGranted = true;
		});

		xrSystem?.isSupported( 'immersive-ar' ).then( ( supported ) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(!supported){
          disabled = true;
          isAr = true;
        }
        else{
          xrSystem?.isSupported( 'immersive-vr' ).then( ( supported ) {
            if(!supported){
              disabled = true;
            }
          });
        }
      });
    });
  }

  Future<void> onSessionEnded() async{
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
      xrSystem?.requestInit(isAr?'immersive-ar':'immersive-vr', {
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
            disabled?'AR and VR NOT SUPPORTED':
            !started?'ENTER ${isAr?'AR':'VR'}':'EXIT ${isAr?'AR':'VR'}'
          ),
        ),
      )
    );
  }
}