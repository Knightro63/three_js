import 'package:flutter/material.dart';
import 'package:css/css.dart';

class GuiWidget{
  GuiWidget(this.name,this.icon,this.update,this.selected,this.visible);

  Map<String,dynamic>? value;
  bool selected;
  bool visible;
  String name;
  IconData icon;
  String get property => name;
  void Function() update;
  void Function(bool)? _onFinished;
  Function(bool)? _onChanged;

  void onVisibilityChange(Function(bool)? function){
    _onChanged = function;
  }
  void onSelected(Function(bool)? function){
    _onFinished = function;
  }

  Widget _visible(BuildContext context){
    return Container(
      height: 20,
      margin: const EdgeInsets.only(left: 20,top: 2,bottom: 2),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: (){
          selected = !selected;
          _onFinished?.call(selected);
          update();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 25,
                  color: selected?lightBlue:Colors.grey,
                  margin: const EdgeInsets.only(right: 5),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: Icon(icon, size: 15,),
                ),
                Text(name.toUpperCase()),
              ]
            ),
            InkWell(
              onTap: (){
                visible = !visible;
                _onChanged?.call(visible);
                update();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(visible?Icons.visibility:Icons.visibility_off, size: 15,)
              
              ),
            )
          ]
        )
      )
    );
  }

  Widget render(BuildContext context){
    return _visible(context);
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
  void Function(bool)? onVisibilityChange;

  GuiWidget add(String name,IconData icon ,update,bool selected, bool visible){
    _widgets.add(GuiWidget(name, icon, update, selected,visible));
    return _widgets.last;
  }

  List<Widget> render(BuildContext context){
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

  Widget render(BuildContext context){
    List<Widget> widgets = [];
    for(final f in _folders){
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          color: Colors.transparent,
          //height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height/3 - 40,
          // margin: const EdgeInsets.fromLTRB(5,5,5,5),
          child: Column(
            children: [
              Container(
                color: Theme.of(context).cardColor,
                child: Row(
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
                      child: Icon(!f.isOpen?Icons.expand_more:Icons.expand_less, size: 15,),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Icon(Icons.folder, size: 15,),
                    ),
                    Text(f.name),
                  ],
                )
              ),
              if(f.isOpen) Column(
                children: f.render(context),
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