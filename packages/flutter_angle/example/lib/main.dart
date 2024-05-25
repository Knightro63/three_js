import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';

void main() {
  runApp(ExampleDemoTest());
}

class ExampleDemoTest extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExampleDemoTest> {
  late FlutterAngle flutterGlPlugin;

  int? fboId;
  bool ready = false;
  double dpr = 1.0;
  late double width;
  late double height;

  Size? screenSize;

  late FlutterGLTexture sourceTexture;
  late final defaultFramebufferTexture;

  int n = 0;

  int t = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = width;

    // OpenGLOptions _options = OpenGLOptions(
    //   antialias: true,
    //   alpha: false,
    //   width: width.toInt(),
    //   height: height.toInt(),
    //   dpr: dpr
    // );

    // print("_options: ${_options}  ");

    await FlutterAngle.initOpenGL(
      AngleOptions(
        width: width, 
        height: height, 
        dpr: dpr,
        useDebugContext: true
      )
    );

    // print(" flutterGlPlugin: textureid: ${flutterGlPlugin.textureId} ");

    setState(() {});

    // web need wait dom ok!!!
    Future.delayed(Duration(milliseconds: 100), () {
      setup();
    });
  }

  setup() async {
    // web no need use fbo

      sourceTexture = await FlutterAngle.createTexture(width.toInt(),height.toInt());

      RenderingContext _gl = FlutterAngle.getContext();
      var _size = _gl.getParameter(WebGL.MAX_TEXTURE_SIZE);

      print(" setup MAX_TEXTURE_SIZE: ${_size}  ");

      //setupDefaultFBO();
    
    ready = true;

    animate();

    setState(() {});
    print(" setup done.... ");
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mq = MediaQuery.of(context);

    screenSize = mq.size;
    dpr = mq.devicePixelRatio;

    print(" screenSize: ${screenSize} dpr: ${dpr} ");

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example app'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            initSize(context);
            return SingleChildScrollView(child: _build(context));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            render();
          },
          child: Text("Render"),
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Stack(
      children: [
        Container(
            width: width,
            height: height,
            color: Colors.black,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return !ready?Container():HtmlElementView(viewType: sourceTexture.textureId.toString());
              } else {
                return ready?Texture(textureId: sourceTexture.textureId):Container();
              }
            })),
        Row(
          children: [],
        )
      ],
    );
  }

  animate() {
    render();

    Future.delayed(Duration(milliseconds: 40), () {
      sourceTexture.activate();
      animate();
    });
  }

  setupDefaultFBO() {
    final RenderingContext _gl = FlutterAngle.getContext();
    int glWidth = (width * dpr).toInt();
    int glHeight = (height * dpr).toInt();

    final defaultFramebuffer = _gl.createFramebuffer();
    defaultFramebufferTexture = _gl.createTexture();
    _gl.activeTexture(WebGL.TEXTURE0);

    _gl.bindTexture(WebGL.TEXTURE_2D, defaultFramebufferTexture);
    _gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, glWidth, glHeight, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, null);
    _gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);
    _gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);

    _gl.bindFramebuffer(WebGL.FRAMEBUFFER, defaultFramebuffer);
    _gl.framebufferTexture2D(WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, defaultFramebufferTexture, 0);
  }

  render() async {
    //print("render start: ${DateTime.now().millisecondsSinceEpoch} ");
    final RenderingContext _gl = FlutterAngle.getContext();

    int _current = DateTime.now().millisecondsSinceEpoch;

    double _blue = sin((_current - t) / 500);

    // Clear canvas
    _gl.clearColor(1.0, 0.0, _blue, 1.0);
    _gl.clear(WebGL.COLOR_BUFFER_BIT);

    _gl.gl.glFlush();

    if (!kIsWeb) {
      await FlutterAngle.updateTexture(sourceTexture);
    }
  }
}
