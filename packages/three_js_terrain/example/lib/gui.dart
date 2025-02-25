import 'package:flutter/material.dart';
import 'package:css/css.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum GuiWidgetType{dropdown,checkbox,color,function,slider}

class GuiWidget{
  GuiWidget(this.name,this.type,this.update,[this.value,this.items]);

  void Function() update;
  Map<String,dynamic>? value;
  GuiWidgetType type;
  dynamic items;
  String name;

  double _step = 1;

  void Function()? _onFinished;
  Function(dynamic)? _onChanged;

  void onFinishChange(void Function() function){
    _onFinished = function;
  }
  void onChange(Function(dynamic)? function){
    _onChanged = function;
  }
  void step(double val){
    _step = val;
  }

  Widget _createDD(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 35,
              color: Colors.green,
              margin: const EdgeInsets.only(right: 5),
            ),
            Text(name),
          ]
        ),
        _SavedWidgets._dropDown(
          itemVal: items, 
          value: value?[name],
          radius: 5,
          color: CSS.darkTheme.canvasColor,
          width: 135,
          margin: const EdgeInsets.all(0),
          height: 25,
          onchange: (value){
            this.value?[name] = value;
            _onChanged?.call(this.value?[name]);
            _onFinished?.call();
            update();
          }
        )
      ],
    );
  }
  Widget _checkBox(){
    return InkWell(
      onTap: (){
        value?[name] = !value?[name];
        _onChanged?.call(value?[name]);
        _onFinished?.call();
        update();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 35,
                color: Colors.grey,
                margin: const EdgeInsets.only(right: 5),
              ),
              Text(name),
            ]
          ),
          _SavedWidgets.checkBox(value?[name])
        ]
      )
    );
  }
  Widget _slider(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 35,
              color: Colors.blue,
              margin: const EdgeInsets.only(right: 5),
            ),
            Text(name),
          ]
        ),
        SizedBox(
          height: 35,
          width: 135,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 7,
            ),
            child: Slider(
              activeColor: CSS.darkTheme.secondaryHeaderColor,
              inactiveColor: CSS.darkTheme.primaryTextTheme.bodyMedium!.color,
              min: items[0],
              divisions: (items[1]-items[0])~/_step,
              max: items[1],
              onChanged: (newRating){
                value?[name] = newRating;
                _onChanged?.call(value?[name]);
                update();
              },
              onChangeEnd: (newRating) {
                value?[name] = newRating;
                _onFinished?.call();
                update();
              },
              value: value?[name],
            ),
          ),
        )
      ]
    );
  }
  Widget _createFunction(){
    return InkWell(
      onTap: (){
        _onFinished?.call();
        update();
      },
      child: SizedBox(
        width: 240,
        child: Row(
          children: [
            Container(
              width: 3,
              height: 35,
              color: Colors.red,
              margin: const EdgeInsets.only(right: 5),
            ),
            Text(name),
          ]
        )
      ),
    );
  }
  Widget _color([BuildContext? context]){
    final r = (0xff0000 & value?[name]) >> 16;
    final g = (0x00ff00 & value?[name]) >> 8;
    final b = (0x0000ff & value?[name]) >> 0;
    final color = Color.fromARGB(255, r, g, b);
    
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 35,
              color: color,
              margin: const EdgeInsets.only(right: 5),
            ),
            Text(name),
          ]
        ),
        InkWell(
          onTap: (){
            if(context == null) throw('To change color context is required in the render function.');
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Pick a color!'),
                  content: SizedBox(
                    width: 250,
                    height: 260,
                    child: ColorPicker(
                      pickerColor: color,
                      onColorChanged: (color) {
                        final red = color.red;
                        final green = color.green;
                        final blue = color.blue;
                        value?[name] = red << 16 ^green << 8 ^blue << 0;
                        update();
                      },
                      colorPickerWidth: 250,
                      pickerAreaHeightPercent: 0.7,
                      portraitOnly: true,
                      enableAlpha: false,
                      labelTypes: const [],
                      pickerAreaBorderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('Got it'),
                      onPressed: () {
                        _onChanged?.call(value?[name]);
                        _onFinished?.call();
                        update();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              }).then((value) {
              _onChanged?.call(this.value?[name]);
              _onFinished?.call();
              update();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            width: 125,
            height: 25,
            color: color,
            alignment: Alignment.center,
            child: Text('0x${color.value.toRadixString(16)}'),
          )
        )
      ]
    );
  }

  Widget render([BuildContext? context]){
    switch (type) {
      case GuiWidgetType.dropdown:
        return _createDD();
      case GuiWidgetType.checkbox:
        return _checkBox();
      case GuiWidgetType.slider:
        return _slider();
      case GuiWidgetType.color:
        return _color(context);
      default:
        return _createFunction();
    }
  }
}

class Folder{
  void Function() update;

  Folder(String name, this.update){
    _name = name;
  }

  late String _name;
  String get name => _name;
  bool get isOpen => _isOpen;
  bool _isOpen = false;

  List<GuiWidget> get widgets => _widgets;
  final List<GuiWidget> _widgets = [];

  void open(){
    _isOpen = true;
  }
  void close(){
    _isOpen = false;
  }
  GuiWidget addDropDown(
    Map<String,dynamic> value,
    String name, 
    List<String> dropdown,
  ){
    List<DropdownMenuItem<String>> ddItem = _SavedWidgets.setDropDownItems(_SavedWidgets.setDropDownFromString(dropdown));
    _widgets.add(GuiWidget(name, GuiWidgetType.dropdown, update, value, ddItem));
    return _widgets.last;
  }
  GuiWidget addSlider(Map<String,dynamic> value, String name, double min, double max){
    _widgets.add(GuiWidget(name, GuiWidgetType.slider, update, value, [min,max]));
    return _widgets.last;
  }
  GuiWidget addCheckBox(Map<String,dynamic> value, String name){
    _widgets.add(GuiWidget(name, GuiWidgetType.checkbox, update, value));
    return _widgets.last;
  }
  GuiWidget addColor(Map<String,dynamic> value, String name){
    _widgets.add(GuiWidget(name, GuiWidgetType.color, update, value));
    return _widgets.last;
  }
  GuiWidget addFunction(String name){
    _widgets.add(GuiWidget(name, GuiWidgetType.function, update));
    return _widgets.last;
  }

  List<Widget> render([BuildContext? context]){
    List<Widget> w = [];

    for(final wids in widgets){
      w.add(wids.render(context));
    }

    return w;
  }
}

class Gui{
  void Function() update;
  final List<Folder> _folders = [];
  List<Folder> get folders => _folders;

  Gui(this.update);

  Folder addFolder(String name){
    _folders.add(Folder(name,update));
    return _folders.last;
  }

  Widget render([BuildContext? context]){
    List<Widget> widgets = [];
    bool first = true;
    for(final f in _folders){
      widgets.add(
        Container(
          //height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height/3 - 40,
          // margin: const EdgeInsets.fromLTRB(5,5,5,5),
          decoration: BoxDecoration(
            color: CSS.darkTheme.cardColor,
            borderRadius: first?const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5)
            ):const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0)
            )
          ),
          child: Column(
            children: [
              InkWell(
                onTap: (){
                  if(!f.isOpen){
                    f.open();
                  }else{
                    f.close();
                  }
                  update();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: CSS.darkTheme.canvasColor,
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: Row(
                    children: [
                      Icon(!f.isOpen?Icons.expand_more:Icons.expand_less, size: 15,),
                      Text(f.name),
                    ],
                  )
                )
              ),
              if(f.isOpen) Column(
                children: f.render(context),
              )
            ]
          )
        )
      );
      first = false;
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
  static Widget checkBox(bool enable){
    return Container(
      margin: const EdgeInsets.only(right:10),
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: (enable)?CSS.darkTheme.secondaryHeaderColor:CSS.darkTheme.cardColor,
        border: (enable)?Border.all(width: 2, color: CSS.darkTheme.secondaryHeaderColor):Border.all(width: 2, color: CSS.darkTheme.primaryTextTheme.bodyMedium!.color!),
        boxShadow: [BoxShadow(
          color: CSS.darkTheme.shadowColor,
          blurRadius: 5,
          offset: const Offset(0,2),
        ),]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
        Icon(
          Icons.check,
          color: CSS.darkTheme.cardColor,
          size: 10,
        ),
      ]),
    );
  }
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



