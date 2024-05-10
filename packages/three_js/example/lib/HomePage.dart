import 'src/filesJson.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  Function chooseExample;

  HomePage({Key? key, required this.chooseExample}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
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
            return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return _buildItem(context, index);
                },
                itemCount: filesJson.length);
          },
        ),
      ),
    );
  }

  String getName(String file) {
    List<String> name = file.split('_');
    if(name.length > 2){
      name.removeAt(0);
    }
    return name.join(' / ');
  }

  Widget _buildItem(BuildContext context, int index) {
    String fileName = filesJson[index];

    String assetFile = "assets/screenshots/$fileName.jpg";
    String name = getName(fileName);

    return TextButton(
        onPressed: () {
          widget.chooseExample(fileName);
        },
        child: Container(
            child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 50),
              child: Image.asset(assetFile,height: 240,),
            ),
            Container(
              child: Text(name),
            )
          ],
        )));
  }
}
