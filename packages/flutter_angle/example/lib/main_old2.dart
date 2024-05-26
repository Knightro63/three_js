import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';

void main() {
  runApp(ExampleTriangle01());
}


class ExampleTriangle01 extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExampleTriangle01> {
  int? fboId;
  double dpr = 1.0;
  bool ready = false;
  late double width;
  late double height;

  late final glProgram;

  Size? screenSize;
  late final RenderingContext _gl;

  late FlutterGLTexture sourceTexture;

  late int defaultFramebufferTexture;

  int n = 0;

  int t = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();

    print(" init state..... ");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = width;

    await FlutterAngle.initOpenGL(true);
    setState(() {});

    // web need wait dom ok!!!
    Future.delayed(Duration(milliseconds: 100), () {
      setup();
    });
  }

  void setup() async {
    // web no need use fbo
    sourceTexture = await FlutterAngle.createTexture(      
      AngleOptions(
        width: width.toInt(), 
        height: height.toInt(), 
        dpr: dpr,
      )
    );
    _gl = sourceTexture.getContext();
    ready = true;

    setState(() {});

    prepare();
    animate();
  }

  void initSize(BuildContext context) {
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
            clickRender();
          },
          child: Text("Render"),
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
            width: width,
            height: width,
            color: Colors.black,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return ready
                    ? HtmlElementView(
                        viewType: sourceTexture.textureId.toString())
                    : Container();
              } else {
                return ready
                    ? Texture(textureId: sourceTexture.textureId)
                    : Container();
              }
            })),
      ],
    );
  }

  void animate() {
    render();

    Future.delayed(Duration(milliseconds: 40), () {
      animate();
    });
  }

  void clickRender() {
    print(" click render ... ");
    render();
  }

  Future<void> render() async{
    int _current = DateTime.now().millisecondsSinceEpoch;

    _gl.viewport(0, 0, width.toInt(), height.toInt());

    double _blue = sin((_current - t) / 500);
    // Clear canvas
    _gl.clearColor(0.0, 0.0, _blue, 1.0);
    _gl.clear(WebGL.COLOR_BUFFER_BIT);
    
    //_gl.gl.glBindVertexArray(_vao);
    _gl.useProgram(glProgram);
    _gl.drawArrays(WebGL.TRIANGLES, 0, n);

    //print(" render n: ${n} ");

     _gl.gl.glFinish();

    if (!kIsWeb) {
      await FlutterAngle.updateTexture(sourceTexture);
    }
  }

  void prepare() {
    String _version = "300 es";

    if(!kIsWeb) {
      if (Platform.isWindows) {
        _version = "150";
      }
    }
    

    var vs = """#version ${_version}
      #define attribute in
      #define varying out
      attribute vec3 a_Position;
      // layout (location = 0) in vec3 a_Position;
      void main() {
          gl_Position = vec4(a_Position, 1.0);
      }
    """;

    var fs = """#version ${_version}
      out highp vec4 pc_fragColor;
      #define gl_FragColor pc_fragColor

      void main() {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
      }
    """;

    if (!initShaders(_gl, vs, fs)) {
      print('Failed to intialize shaders.');
      return;
    }

    // Write the positions of vertices to a vertex shader
    n = initVertexBuffers(_gl);
    if (n < 0) {
      print('Failed to set the positions of the vertices');
      return;
    }
  }

  int initVertexBuffers(RenderingContext gl) {
    // Vertices
    final dim = 3;
    final vertices = Float32List.fromList([
      -0.5, -0.5, 0, // Vertice #2
      0.5, -0.5, 0, // Vertice #3
      0, 0.5, 0, // Vertice #1
    ]);
    
    // Create a buffer object
    dynamic vertexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(WebGL.ARRAY_BUFFER, vertices, WebGL.STATIC_DRAW);

    // Assign the vertices in buffer object to a_Position variable
    final a_Position = gl.getAttribLocation(glProgram, 'a_Position').id;
    if (a_Position < 0) {
      print('Failed to get the storage location of a_Position');
      return -1;
    }

    gl.vertexAttribPointer(a_Position, dim, WebGL.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(a_Position);

    // Return number of vertices
    return vertices.length ~/ dim;
  }

  bool initShaders(RenderingContext gl, String vs_source, String fs_source) {
    // Compile shaders
    final vertexShader = makeShader(gl, vs_source, WebGL.VERTEX_SHADER);
    final fragmentShader = makeShader(gl, fs_source, WebGL.FRAGMENT_SHADER);

    // Create program
    glProgram = gl.createProgram();

    // Attach and link shaders to the program
    gl.attachShader(glProgram, vertexShader);
    gl.attachShader(glProgram, fragmentShader);
    gl.linkProgram(glProgram);
    final _res = gl.getProgramParameter(glProgram, WebGL.LINK_STATUS);
    print(" initShaders LINK_STATUS _res: ${_res} ");
    if (_res == false || _res == 0) {
      print("Unable to initialize the shader program");
      return false;
    }

    // Use program
    gl.useProgram(glProgram);

    return true;
  }

  dynamic makeShader(RenderingContext gl, String src, int type) {
    dynamic shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);
    gl.shaderSource(shader, WebGL.COMPILE_STATUS.toString());
    // if (_res == 0 || _res == false) {
    //   print("Error compiling shader: ${gl.getShaderInfoLog(shader)}");
    //   return;
    // }
    return shader;
  }
}
