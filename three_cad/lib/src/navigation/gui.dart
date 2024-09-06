import 'package:flutter/material.dart';
import 'package:css/css.dart';

// class GuiWidget{
//   GuiWidget(this.name,this.icon,this.update,this.selected,this.visible);

//   Map<String,dynamic>? value;
//   bool selected;
//   bool visible;
//   String name;
//   IconData icon;
//   String get property => name;
//   void Function() update;
//   void Function(bool)? _onFinished;
//   Function(bool)? _onChanged;

//   void onVisibilityChange(Function(bool)? function){
//     _onChanged = function;
//   }
//   void onSelected(Function(bool)? function){
//     _onFinished = function;
//   }

//   Widget _visible(BuildContext context){
//     return Container(
//       height: 20,
//       margin: const EdgeInsets.only(left: 20,top: 2,bottom: 2),
//       color: Theme.of(context).cardColor,
//       child: InkWell(
//         onDoubleTap: (){
          
//         },
//         onTap: (){
//           selected = !selected;
//           _onFinished?.call(selected);
//           update();
//         },
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 3,
//                   height: 25,
//                   color: selected?lightBlue:Colors.grey,
//                   margin: const EdgeInsets.only(right: 5),
//                 ),
//                 Container(
//                   margin: const EdgeInsets.only(right: 5),
//                   child: Icon(icon, size: 15,),
//                 ),
//                 Text(name.toUpperCase()),
//               ]
//             ),
//             InkWell(
//               onTap: (){
//                 visible = !visible;
//                 _onChanged?.call(visible);
//                 print('here');
//                 update();
//               },
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 5),
//                 child: Icon(visible?Icons.visibility:Icons.visibility_off, size: 15,)

//               ),
//             )
//           ]
//         )
//       )
//     );
//   }

//   Widget render(BuildContext context){
//     return _visible(context);
//   }
// }

class GuiWidget extends StatefulWidget{
  final String name;
  final IconData icon;
  bool selected;
  final bool visible;

  GuiWidget(this.name,this.icon,this.selected,this.visible);

  void Function(bool)? _onFinished;
  void Function(bool)? _onChanged;
  void Function(bool)? _onEdited;

  void onVisibilityChange(void Function(bool)? function){
    _onChanged = function;
  }
  void onSelected(void Function(bool)? function){
    _onFinished = function;
  }
  void onEdit(void Function(bool)? function){
    _onEdited = function;
  }

  @override
  _GuiWidgetState createState() => _GuiWidgetState();
}

class _GuiWidgetState extends State<GuiWidget>{
  Map<String,dynamic>? value;
  bool visible = false;

  @override
  void initState(){
    super.initState();
    visible = widget.visible;
  }

  Widget _visible(BuildContext context){
    return Container(
      height: 20,
      margin: const EdgeInsets.only(left: 20,top: 2,bottom: 2),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onDoubleTap: (){
          widget.selected = !widget.selected;
          widget._onEdited?.call(widget.selected);
          setState(() {});
        },
        onTap: (){
          widget.selected = !widget.selected;
          widget._onFinished?.call(widget.selected);
          setState(() {});
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 25,
                  color: widget.selected?lightBlue:Colors.grey,
                  margin: const EdgeInsets.only(right: 5),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: Icon(widget.icon, size: 15,),
                ),
                Text(widget.name),
              ]
            ),
            InkWell(
              onTap: (){
                visible = !visible;
                widget._onChanged?.call(visible);
                setState(() {
                  
                });
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

  @override
  Widget build(BuildContext context){
    return _visible(context);
  }
}

class Folder{
  void Function() update;
  Folder(String name,this.update){
    _name = name;
  }

  late String _name;
  String get name => _name;
  bool get isOpen => _isOpen;
  bool _isOpen = false;
  bool visible = true;

  void Function(bool)? onVisibilityChange;

  final Map<String,GuiWidget> widgets = {};

  void open(){
    _isOpen = true;
  }
  void close(){
    _isOpen = false;
  }

  GuiWidget add(
    String name,
    IconData icon,
    bool selected, 
    bool visible
  ){
    widgets[name] = GuiWidget(name, icon,selected, visible);
    return widgets[name]!;
  }

  List<Widget> render(BuildContext context){
    List<Widget> w = [];
    for(final key in widgets.keys){
      w.add(widgets[key]!);
    }
    return w;
  }
}
class Gui extends StatefulWidget{
  final Map<String,Folder> folders = {};

  Gui({
    super.key
  });

  Folder addFolder(String name,update){
    folders[name] = Folder(name,update);
    return folders[name]!;
  }

  @override
  _GuiState createState() => _GuiState();
}

class _GuiState extends State<Gui>{
  @override
  Widget build(BuildContext context){
    List<Widget> widgets = [];
    for(final key in widget.folders.keys){
      final f = widget.folders[key]!;
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
                        setState(() {
                          
                        });
                      },
                      child: Icon(!f.isOpen?Icons.expand_more:Icons.expand_less, size: 15,),
                    ),
                    if(f.onVisibilityChange != null)Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: InkWell(
                        onTap: (){
                          f.visible = !f.visible;
                          f.onVisibilityChange?.call(f.visible);
                          setState(() {
                            
                          });
                        },
                        child: Icon(f.visible?Icons.visibility:Icons.visibility_off, size: 15,),
                      )
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