import 'package:flutter/material.dart';
import 'package:css/css.dart';

class Folder{

  Folder(String name){
    _name = name;
  }

  late String _name;
  String get name => _name;
  bool get isOpen => _isOpen;
  bool _isOpen = false;
  Function? _onFinished; 
  Function? _onChanged;

  List<Widget> get widgets => _widgets;
  List<Widget> _widgets = [];
  List vals = [];

  void open(){
    _isOpen = true;
  }
  void close(){
    _isOpen = false;
  }
  void addDropDown(
    String name, 
    List<String> dropdown,
    {
      Function(dynamic)? onchange,
      String? initialValue
    }
  ){
    List<DropdownMenuItem<String>> ddItem = _SavedWidgets.setDropDownItems(_SavedWidgets.setDropDownFromString(dropdown));
    vals.add(initialValue ?? dropdown[0]);
    int val = vals.length;

    _widgets.add(
      _SavedWidgets._dropDown(
        itemVal: ddItem, 
        value: vals[val],
        radius: 5,
        color: CSS.darkTheme.cardColor,
        onchange: (value){

        }
      )
    );
  }
  void addSlider(String name, int min, int max, int step){

  }
  void addCheckBox(String name, bool selected){

  }
  void addColor(String name, int color){

  }
  void addFunction(String name,void Function()? onTap ){
    widgets.add(
      InkWell(
        onTap: onTap,
        child: ,
      )
    );
  }
  void onFinishChange(Function function){
    _onFinished = function;
  }
  void onChanged(Function function){
    _onChanged = function;
  }

}

class Gui{
  void Function() update;
  List<Folder> _folders = [];
  List<Folder> get folders => _folders;

  Gui(this.update);

  Folder addFolder(String name){
    _folders.add(Folder(name));
    return _folders.last;
  }

  Widget render(){
    List<Widget> widgets = [];

    for(final f in _folders){
      widgets.add(
        Container(
          //height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height/3 - 40,
          margin: const EdgeInsets.fromLTRB(5,5,5,5),
          decoration: BoxDecoration(
            color: CSS.darkTheme.cardColor,
            borderRadius: BorderRadius.circular(5)
          ),
          child: Column(
            children: [
              InkWell(
                onTap: (){
                  if(f.isOpen){
                    f.open();
                  }else{
                    f.close();
                  }
                  update();
                },
                child: Row(
                  children: [
                    Icon(!f.isOpen?Icons.expand_more:Icons.expand_less, size: 15,),
                    const Text('\tTransform'),
                  ],
                )
              ),
              if(f.isOpen) Padding(
                padding: const EdgeInsets.fromLTRB(25,10,5,5),
                child: Column(
                  children: f.widgets,
                ),
              )
            ]
          )
        )
      );
    }
    return ListView(
      children: widgets
    );
  }
}

class DropDownItems{
  DropDownItems({
    required this.value,
    required this.text
  });
  String value;
  String text;
}
class _SavedWidgets{
  static List<DropDownItems> setDropDownFromString(List<String> info){
    List<DropDownItems> items = [];
    for (int i =0; i < info.length;i++) {
      items.add(DropDownItems(
        value: info[i],
        text: info[i]
      ));
    }
    return items;
  }
  static List<DropdownMenuItem<String>> setDropDownItems(List<DropDownItems> info){
    List<DropdownMenuItem<String>> items = [];
    for (int i =0; i < info.length;i++) {
      items.add(DropdownMenuItem(
        value: info[i].value,
        child: Text(
          info[i].text, 
          overflow: TextOverflow.ellipsis,
        )
      ));
    }
    return items;
  }
  static Widget _dropDown({
    Key? key,
    required List<DropdownMenuItem<dynamic>> itemVal, 
    TextStyle style = const TextStyle(
      color: darkGrey,
      fontFamily: 'Klavika',
      package: 'css',
      fontSize: 14
    ),
    required dynamic value,
    Function(dynamic)? onchange,
    double width = 80,
    double height = 36,
    EdgeInsets padding = const EdgeInsets.only(left:10),
    EdgeInsets margin = const EdgeInsets.fromLTRB(0, 5, 0, 5),
    Color color = Colors.transparent,
    double radius = 0,
    Alignment alignment = Alignment.center,
    Border? border,
  }){
    return Container(
      key: key,
      margin: margin,
      alignment: alignment,
      width: width,
      height:height,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        border: border
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton <dynamic>(
          dropdownColor: color,
          isExpanded: true,
          items: itemVal,
          value: value,//ddInfo[i],
          isDense: true,
          focusColor: lightBlue,
          style: style,
          onChanged: onchange,
        ),
      ),
    );
  }
}



