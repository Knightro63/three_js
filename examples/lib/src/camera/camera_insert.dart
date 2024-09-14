import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imgLib;
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'input_image.dart';

class PictureInfo{
  PictureInfo({
    this.file,
    this.error,
  });

  Uint8List? file;
  String? error;
}

class InsertCamera{
  InsertCamera([this.onSetupFinished]);

  Function? onSetupFinished;
  bool restartStream = false;
  bool streaming = false;

  List<CameraDescription> _cameras = [];
  late List<CameraMacOSDevice> _camerasMacos;
  CameraController? controller;
  CameraMacOSController? controllerMacos;

  bool isReady = false;
  //bool isMounted = false;
  Timer? _liveTimerMacos;
  bool _processingLiveFeed = false;
  bool isLive = false;
  double aspectRatio = 0.75;
  int cameraSides = 0;
  int cameraIndex = 0;
  int cameraRotation = 0;
  int? textureId;//widget.camera.controllerMacos!.args.textureId!
  Size? imageSize;

  void Function(InputImage image)? _returnImage;

  final orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void dispose(){
    controller?.dispose();
    controllerMacos?.destroy();
  }

  Future<void> setupCameras() async {
    print("Setting up Cameras");
    try {
      late PermissionStatus p;
      if(!kIsWeb){
        p = await Permission.camera.request();
        if(p.isPermanentlyDenied){
          openAppSettings();
        }
      }
      
      if(kIsWeb || p.isGranted){
        if(!kIsWeb && Platform.isMacOS){
          await CameraMacOS.instance.listDevices(deviceType: CameraMacOSDeviceType.video).then((value){
            _camerasMacos = value;
            cameraSides = _camerasMacos.length;
          });
          await _setupController(0);
        }
        else{
          print("Checking Cameras");
          _cameras = await availableCameras();
          cameraSides = _cameras.length;
          await _setupController(cameraSides-1);
        }
      }
    }on CameraException catch (_) {
      print('error');
    }
    return;
  }

  Future<void> _setupController(int side) async{
    cameraIndex = side;
    if(_cameras.isNotEmpty){
      cameraRotation = _cameras[side].sensorOrientation;
    }
    print("Setting up Controller");
    if(isReady){
      await controllerMacos?.destroy();
      await controller?.dispose();
    }
    isReady = false;
    try {
      if(!kIsWeb && Platform.isMacOS){
        var value = await CameraMacOSPlatform.instance.initialize(
          deviceId: null,
          audioDeviceId: null,
          cameraMacOSMode: CameraMacOSMode.video,
          enableAudio: false,
          resolution: PictureResolution.low,
          pictureFormat: PictureFormat.jpg,
          orientation: CameraOrientation.orientation0deg
        );
        controllerMacos = CameraMacOSController(value!);
        textureId = controllerMacos!.args.textureId!;
        isReady = true;
      }
      else{
        // initialize camera controllers.
        controller = CameraController(
          _cameras[side], 
          ResolutionPreset.low, 
          enableAudio: false,
          imageFormatGroup: !kIsWeb && Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
        );
        await controller!.initialize().then((_)async{
          aspectRatio = controller!.value.aspectRatio;
          isReady = true;
        });
        textureId = controller!.cameraId;
      }
    } on CameraException catch (_) {
      print('error');
    }
    onSetupFinished?.call();
    return;
  }
  Future stopFeed([int? camera]) async {
    await controller?.stopImageStream();
    await controller?.dispose();
    _liveTimerMacos?.cancel();
    _liveTimerMacos = null;
    isLive = false;
    controller = null;
    if(camera != null){
      _setupController(camera);
    }
  }

  Future startLiveFeed(void Function(InputImage image)? returnImage) async {
    _returnImage = returnImage;
    isLive = true;
    if(kIsWeb || Platform.isIOS || Platform.isAndroid){
      _liveTimerMacos = Timer.periodic(const Duration(milliseconds: 16),(_){
        if(!_processingLiveFeed){
          _processingLiveFeed = true;
          takePicture().then((data){
            Uint8List send = data.file!;
            Uint8List toSend;
            //if(kIsWeb){
              imgLib.Image? img = imgLib.decodeImage(data.file!);
              if(img != null) {
                img = imgLib.flipVertical(img);
              }
              imageSize = Size(img!.width.toDouble(),img.height.toDouble());
              send = img.data!.buffer.asUint8List();
              if(img.data!.numChannels == 3){
                int n = send.length~/3;
                toSend = Uint8List(n*4);
                toSend.setRange(0, send.length, send);
                int j = 0;
                for(int i = 0; i < send.length;i+=3){
                  //toSend.insert(i*4-1, 254);
                  toSend[j] = send[i];
                  toSend[j+1] = send[i+1];
                  toSend[j+2] = send[i+2];
                  toSend[j+3] = 255;
                  j+=4;
                }
              }else{
                toSend = send;
              }
            // }else{
            //   toSend = send;
            // }
            InputImage i = InputImage.fromBytes(
              bytes: toSend, 
              metadata: InputImageMetadata(
                size: imageSize!,
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.bgra8888,
                bytesPerRow: 0,
              )
            );
            _returnImage!(i);
            _processingLiveFeed = false;
          });
        }
      });
    }
    else if(!kIsWeb && Platform.isMacOS){
      controllerMacos?.startImageStream((p){
        imageSize ??= Size(p.width.toDouble(), p.height.toDouble());
        InputImage i = InputImage.fromBytes(
          bytes: p.bytes,
          metadata: InputImageMetadata(
            size: imageSize!,
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: 0,
          )
        );
        _returnImage!(i);
      });
    }
    else{
      controller?.startImageStream(_processCameraImage);
    }
  }
  Future switchCamera(int camera) async {
    await stopFeed(camera);
    if(isLive){
      await startLiveFeed(_returnImage);
    }
  }
  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _returnImage!(inputImage);
  }
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (controller == null) return null;

    // get camera rotation
    final camera = _cameras[cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    var rotation = InputImageRotationValue.fromRawValue(sensorOrientation);

    if (!kIsWeb && Platform.isAndroid) {
      var rotationCompensation =
          orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotation.values[rotationCompensation];
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
  Future<PictureInfo> takePicture() async {
    String? error;
    Uint8List? filePath;
    if(!kIsWeb && Platform.isMacOS){
      await controllerMacos?.takePicture().then((value){
        if(value != null){
          filePath = value.bytes;
        }
      });
    }
    else{
      if (!controller!.value.isInitialized){
        error = 'Error: select a camera first.';
      }
      else{
        if (controller!.value.isTakingPicture){
          error = "Taking Picture";
        }
        try {
          await controller!.takePicture().then((value) async{
            filePath = await value.readAsBytes();
          });
        } on CameraException catch (e) {
          error = 'Error: ${e.code}\n${e.description}';
        }
      }
    }
    PictureInfo send = PictureInfo(
      file: filePath,
      error: error,
    );
    return send;
  }
}

class CameraSetup extends StatefulWidget {
  const CameraSetup({
    Key? key,
    required this.camera,
    this.size = const Size(640,480)
  }):super(key: key);

  final InsertCamera camera;
  final Size size;

  @override
  _CameraSetupState createState() => _CameraSetupState();
}

class _CameraSetupState extends State<CameraSetup> {
  final GlobalKey cameraKey = GlobalKey(debugLabel: "cameraKey");

  late CameraController? controller;
  late CameraMacOSController? controllerMacos;
  Offset offset = const Offset(0,0);
  
  @override
  void initState() {
    controller = widget.camera.controller;
    controllerMacos = widget.camera.controllerMacos;
    if(controllerMacos != null){
      // widget.camera.controllerMacos!.args = CameraMacOSArguments(
      //   size: widget.size,
      //   devices: widget.camera.controllerMacos!.args.devices,
      //   textureId: widget.camera.controllerMacos!.args.textureId
      // );
    }
    super.initState();
  }
  @override
  void dispose() async{
    super.dispose();
  }
  Widget _macosCamera() {
    return ClipRect(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: widget.camera.controllerMacos!.args.size.width,
            height: widget.camera.controllerMacos!.args.size.height,
            child: Texture(textureId: widget.camera.controllerMacos!.args.textureId!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(widget.camera.restartStream){
      print('reset Camera Insert');
      widget.camera.restartStream = false;
    }
    return Stack(
      children:[
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: widget.size.height,
            width: widget.size.width,
            child: !kIsWeb && Platform.isMacOS?_macosCamera():CameraPreview(controller!)
          )
        ),
      ]
    );
  }
}