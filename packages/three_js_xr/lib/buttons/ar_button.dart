import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/three_js_xr.dart';

class ARButton extends StatefulWidget{
  const ARButton({super.key,required this.threeJs});
  final ThreeJS threeJs;

  @override
  createState() => _State();
}

class _State extends State<ARButton>{
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

		xrSystem?.isSupported( 'immersive-ar' ).then( ( supported ) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(!supported){
          disabled = true;
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
    (widget.threeJs.renderer!.xr as WebXRWorker).setReferenceSpaceType( 'local' );
    await (widget.threeJs.renderer!.xr as WebXRWorker).setSession(currentSession);
    widget.threeJs.renderer?.onXRSessionStart(null);
    session.addListener( 'end', onSessionEnded );
    started = true;
  }

  void button() async{
    if(!started){
      xrSystem?.requestInit('immersive-ar', {
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
            disabled?'AR NOT SUPPORTED':
            !started?'START AR':'STOP AR'
          ),
        ),
      )
    );
  }
}