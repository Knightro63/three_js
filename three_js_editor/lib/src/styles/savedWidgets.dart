import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/css.dart';

class EnterTextFormField extends StatelessWidget{
  const EnterTextFormField({
    Key? key,
    this.maxLines,
    this.minLines,
    this.label, 
    required this.controller,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.width,
    this.height,
    this.color,
    this.textStyle,
    this.margin = const EdgeInsets.fromLTRB(10, 0, 10, 0),
    this.readOnly = false,
    this.keyboardType = TextInputType.multiline,
    this.padding = const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
    this.inputFormatters
  }):super(key: key);
  
  final int? minLines;
  final int? maxLines;
  final String? label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function()? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Function()? onEditingComplete;
  final double? width;
  final double? height;
  final Color? color;
  final bool readOnly;
  final EdgeInsets margin;
  final TextInputType keyboardType;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context){
    return Container(
      margin: margin,
      width: width,
      height: height,
      alignment: Alignment.center,
      child: TextField(
        //textAlign: TextAlign.,
        readOnly: readOnly,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        autofocus: false,
        focusNode: focusNode,
        //textAlignVertical: TextAlignVertical.center,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete:onEditingComplete,
        inputFormatters: inputFormatters,
        controller: controller,
        style: (textStyle == null)?Theme.of(context).primaryTextTheme.bodyMedium:textStyle,
        decoration: InputDecoration(
          isDense: true,
          //labelText: label,
          filled: true,
          fillColor: (color == null)?Theme.of(context).splashColor:color,
          contentPadding: padding,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
                width: 0, 
                style: BorderStyle.none,
            ),
          ),
          hintText: label
        ),
      )
    );
  }
}

class LSIWidgets{
  static Widget squareButton({
    Key? key,
    bool iconFront = false,
    Widget? icon,
    Color buttonColor = lightBlue,
    Color textColor = darkGrey,
    required String text,
    Function()? onTap,
    String fontFamily = 'Klavika Bold',
    double fontSize = 18.0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    double height = 75,
    double width = 100,
    double radius = 5,
    Alignment? alignment,
    EdgeInsets? margin,
    EdgeInsets? padding,
    List<BoxShadow>? boxShadow,
    Color? borderColor
  }){
    Widget totalIcon = (icon != null)?icon:Container();
    return InkWell(
      onTap: onTap,
      child:Container(
        alignment: alignment,//Alignment.center,
        height: height,//75,
        width: width,//deviceWidth,
        margin: margin,//EdgeInsets.fromLTRB(10,5,10,5),
        padding: padding,//EdgeInsets.fromLTRB(25,0,10,0),
        decoration: BoxDecoration(
          color: buttonColor,//(light)?Colors.white:lsi.darkBlue,
          border: Border.all(
            color: (borderColor == null)?buttonColor:borderColor,
            width: 2
          ),
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          boxShadow: boxShadow
        ),
        child:Row(
          key: key,
          mainAxisAlignment: mainAxisAlignment,//MainAxisAlignment.spaceBetween,
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (iconFront)?totalIcon:Container(),
            Text(
              text.toUpperCase(),
              
              textAlign: TextAlign.start,
              style:TextStyle(
                color: textColor,//(light)?lsi.darkGrey:Colors.white,
                fontSize: fontSize,
                fontFamily: fontFamily,
                decoration: TextDecoration.none
              )
            ),
            (!iconFront)?totalIcon:Container(),
        ],)
      )
    );
  }
}