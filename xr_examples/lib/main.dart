import 'package:examples/ar/webxr_ar_cones.dart';
import 'package:examples/vr/webxr_vr_handinput_cubes.dart';
import 'package:examples/vr/webxr_vr_panorama_depth.dart';
import 'package:examples/vr/webxr_vr_teleport.dart';
import 'package:examples/vr/webxr_vr_video.dart';
import 'package:examples/xr/webxr_xr_ballshooter.dart';
import 'package:examples/xr/webxr_xr_cubes.dart';
import 'package:examples/xr/webxr_xr_dragging.dart';
import 'package:examples/xr/webxr_xr_paint.dart';
import 'package:examples/xr/webxr_xr_sculpt.dart';

import 'vr/webxr_vr_rollercoaster.dart';
import 'vr/webxr_vr_panorama.dart';
import 'package:flutter/material.dart';
import 'package:css/css.dart';
import 'src/plugins/plugin.dart';
import './src/files_json.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}
class MyApp extends StatefulWidget{
  const MyApp({super.key,}) ;
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  String onPage = '';
  double pageLocation = 0;
  bool isFullScreen = false;

  void callback(String page, [double? location]){
    onPage = page;
    isFullScreen = false;
    if(location != null){
      pageLocation = location;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
      _navKey.currentState!.popAndPushNamed('/$page');
      setState(() {});
    });
  }

  void fullScreen(bool value){
    isFullScreen = value;
    setState(() {
      
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    widthInifity = MediaQuery.of(context).size.width;
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Three_JS',
        theme: CSS.darkTheme,
        home: Scaffold(
          appBar: onPage != '' && !isFullScreen? PreferredSize(
            preferredSize: Size(widthInifity,65),
            child:AppBar(callback: callback,page: onPage,)
          ):null,
          body: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Three_JS',
            theme: CSS.darkTheme,
            navigatorKey: _navKey,
            routes: {
              '/':(BuildContext context) {
                return Examples(
                  callback: callback,
                  prevLocation: pageLocation,
                );
              },
              '/webxr_ar_cones':(BuildContext context) {
                return const WebXRARCones();
              },
              '/webxr_vr_handinput_cubes':(BuildContext context) {
                return const WebXRVRHandInputCubes();
              },
              '/webxr_vr_rollercoaster':(BuildContext context) {
                return WebXRVRRollercoaster(fullScreen: fullScreen);
              },
              '/webxr_vr_panorama':(BuildContext context) {
                return const WebXRVRPanorama();
              },
              '/webxr_vr_panorama_depth':(BuildContext context) {
                return WebXRVRPanoramaDepth(fullScreen: fullScreen);
              },
              '/webxr_vr_teleport':(BuildContext context) {
                return const WebXRVRTeleport();
              },
              '/webxr_vr_video':(BuildContext context) {
                return const WebXRVRVideo();
              },
              '/webxr_xr_ballshooter':(BuildContext context) {
                return const WebXRXRBallShooter();
              },
              '/webxr_xr_cubes':(BuildContext context) {
                return const WebXRXRCubes();
              },
              '/webxr_xr_dragging':(BuildContext context) {
                return const WebXRXRDragging();
              },
              '/webxr_xr_paint':(BuildContext context) {
                return const WebXRXRPaint();
              },
              '/webxr_xr_sculpt':(BuildContext context) {
                return const WebXRXRSculpt();
              },
            }
          ),
        )
      )
    );
  }
}

@immutable
class AppBar extends StatelessWidget{
  const AppBar({
    super.key,
    required this.page,
    required this.callback
  });
  final String page;
  final void Function(String page,[double? loc]) callback;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(left: 10),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          InkWell(
            onTap: (){
              callback('');
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded
            ),
          ),
          const SizedBox(width: 20,),
          Text(
            (page[0]+page.substring(1)).replaceAll('_', ' ').toUpperCase(),
            style: Theme.of(context).primaryTextTheme.bodyMedium,
          )
        ],
      ),
    );
  }
}

class Examples extends StatefulWidget{
  const Examples({
    super.key,
    required this.callback,
    required this.prevLocation
  });

  final void Function(String page,[double? location]) callback;
  final double prevLocation;

  @override
  ExamplesPageState createState() => ExamplesPageState();
}

class ExamplesPageState extends State<Examples> {
  double deviceHeight = double.infinity;
  double deviceWidth = double.infinity;
  ScrollController controller = ScrollController();

  List<Widget> displayExamples(){
    List<Widget> widgets = [];

    double response = CSS.responsive(width: 480);

    for(int i = 0;i < filesJson.length;i++){
      widgets.add(
        InkWell(
          onTap: (){
            widget.callback(filesJson[i],controller.offset);
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            width: response-65,
            height: response,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ]
            ),
            child: Column(
              children:[
                Container(
                  width: response,
                  height: response-65,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: ExactAssetImage('assets/screenshots/${filesJson[i]}.jpg'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(topRight:Radius.circular(10),topLeft:Radius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  filesJson[i].replaceAll('_',' ').toUpperCase(),
                  style: Theme.of(context).primaryTextTheme.bodyMedium,
                )
              ]
            )
          )
        )
      );
    }

    return widgets;
  }

  @override
  void initState(){
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
      controller.jumpTo(widget.prevLocation);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      controller: controller,
      child: Wrap(
        runAlignment: WrapAlignment.spaceBetween,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: displayExamples(),
      )
    );
  }
}