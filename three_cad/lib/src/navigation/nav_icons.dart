import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/draw_types.dart';

class ConstraintIcons extends StatelessWidget{
  final onTap;
  final selected;
  final Constraints drawType;
  final ThemeData theme;

  ConstraintIcons(
    this.drawType,
    this.selected,
    this.theme,
    this.onTap,
  );

  Widget getConstraintType(Color color){
    switch (drawType) {
      case Constraints.horizontal:
      case Constraints.vertical:
        return _SketchIcons.horizontalVertical(color);
      case Constraints.coincident:
        return _SketchIcons.coincident(color);
      case Constraints.concentric:
        return _SketchIcons.concentric(color);
      case Constraints.parallel:
        return _SketchIcons.parallel(color);
      case Constraints.perpendicular:
        return _SketchIcons.perpendicular(color);
      case Constraints.tangent:
        return _SketchIcons.tangent(color);
      case Constraints.equal:
        return _SketchIcons.equal(color);
      case Constraints.midpoint:
        return _SketchIcons.midpoint(color);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = (selected?theme.secondaryHeaderColor:theme.hintColor);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color)
        ),
        alignment: Alignment.center,
        child: getConstraintType(color)
      ),
    );
  }
}

class SketchIcons extends StatelessWidget{
  final onTap;
  final selected;
  final DrawType drawType;
  final ThemeData theme;

  SketchIcons(
    this.drawType,
    this.selected,
    this.theme,
    this.onTap,
  );

  Widget getDrawType(Color color){
    switch (drawType) {
      case DrawType.point:
        return _SketchIcons.point(color);
      case DrawType.line:
        return _SketchIcons.line(color);
      case DrawType.box2Point:
        return _SketchIcons.box2Point(color);
      case DrawType.circleCenter:
        return _SketchIcons.circleCenter(color);
      case DrawType.boxCenter:
        return _SketchIcons.boxCenter(color);
      case DrawType.spline:
        return _SketchIcons.spline(color);
      case DrawType.arc3Point:
        return _SketchIcons.arc3Point(color);
      case DrawType.dimensions:
        return _SketchIcons.dimensions(color);
      default:
        return _SketchIcons.sketch(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = (selected?theme.secondaryHeaderColor:theme.hintColor);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color)
        ),
        alignment: Alignment.center,
        child: getDrawType(color)
      ),
    );
  }
}

class _SketchIcons{
  static Widget horizontalVertical(Color color){
    return CustomPaint(
      painter: HorizontalVerticalConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget equal(Color color){
    return CustomPaint(
      painter: EqualConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget tangent(Color color){
    return CustomPaint(
      painter: TangentConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget coincident(Color color){
    return CustomPaint(
      painter: CoincidentConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget concentric(Color color){
    return CustomPaint(
      painter: ConcentricConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget midpoint(Color color){
    return CustomPaint(
      painter: MidpointConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget parallel(Color color){
    return CustomPaint(
      painter: ParallelConstraintIcon(color),
      size: Size(100,100),
    );
  }
  static Widget perpendicular(Color color){
    return CustomPaint(
      painter: PerpendicularConstraintIcon(color),
      size: Size(100,100),
    );
  }

  static Widget sketch(Color color){
    return CustomPaint(
      painter: SketchIcon(color),
      size: Size(100,100),
    );
  }

  static Widget boxCenter(Color color){
    return CustomPaint(
      painter: BoxCenterIcon(color),
      size: Size(100,100),
    );
  }

  static Widget box2Point(Color color){
    return CustomPaint(
      painter: Box2PointIcon(color),
      size: Size(100,100),
    );
  }

  static Widget point(Color color){
    return CustomPaint(
      painter: PointIcon(color),
      size: Size(100,100),
    );
  }  

  static Widget dimensions(Color color){
    return CustomPaint(
      painter: DimensionsIcon(color),
      size: Size(100,100),
    );
  }  

  static Widget line(Color color){
    return CustomPaint(
      painter: LineIcon(color),
      size: Size(100,100),
    );
  }  
  
  static Widget spline(Color color){
    return CustomPaint(
      painter: SplineIcon(color),
      size: Size(100,100),
    );
  }

  static Widget circleCenter(Color color){
    return CustomPaint(
      painter: CircleCenterIcon(color),
      size: Size(100,100),
    );
  }

  static Widget arc3Point(Color color){
    return CustomPaint(
      painter: Arc3PointIcon(color),
      size: Size(100,100),
    );
  }  
}

class LineIcon extends CustomPainter{
  Color color;
  LineIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint);
    canvas.drawLine(Offset(7.5,7.5), Offset(size.width/2,size.height-7.5), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawLine(Offset(size.width/2,size.height-7.5), Offset(size.width-7.5,7.5), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(LineIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class SplineIcon extends CustomPainter{
  Color color;
  SplineIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    final Path path = Path();

    path.moveTo(7.5, size.height-7.5);
    path.cubicTo(
      size.width*0.2,-size.height*0.5,
      size.width*0.8,size.height*1.5,
      size.width-7.5,7.5
    );

    canvas.drawPath(path, paint);

    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,size.height-7.5), width: 4, height: 4), paint..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*1/3,size.height/3), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*2/3,size.height*2/3), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(SplineIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class Arc3PointIcon extends CustomPainter{
  Color color;
  Arc3PointIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    final Path path = Path();
    var firstControlPoint = Offset(7.5,size.height-7.5);
    var firstEndPoint = Offset(size.width/2,size.height-7.5);
    var secondControlPoint = Offset(size.width-7.5, size.height-7.5);
    var secondEndPoint = Offset(size.width-7.5,7.5);

    path.moveTo(7.5, 7.5);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    canvas.drawPath(path, paint);

    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(Arc3PointIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class Box2PointIcon extends CustomPainter{
  Color color;
  Box2PointIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: size.width-15, height: size.height-15), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(Box2PointIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class BoxCenterIcon extends CustomPainter{
  Color color;
  BoxCenterIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: size.width-15, height: size.height-15), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: 4, height: 4), paint..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(BoxCenterIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class CircleCenterIcon extends CustomPainter{
  Color color;
  CircleCenterIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawCircle(Offset(size.width/2,size.height/2), size.height/2-5, paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: 4, height: 4), paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CircleCenterIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class PointIcon extends CustomPainter{
  Color color;
  PointIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawLine(Offset(size.width/2,5), Offset(size.width/2,size.height/2), paint);
    canvas.drawLine(Offset(size.width/2,size.height-5), Offset(size.width/2,size.height/2), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: 4, height: 4), paint);
    canvas.drawLine(Offset(5,size.height/2), Offset(size.width/2,size.height/2), paint);
    canvas.drawLine(Offset(size.width-5,size.height/2), Offset(size.width/2,size.height/2), paint);
  }

  @override
  bool shouldRepaint(PointIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class DimensionsIcon extends CustomPainter{
  Color color;
  DimensionsIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    canvas.drawLine(Offset(5,5), Offset(5,size.height-5), paint);
    canvas.drawLine(Offset(size.width-5,5), Offset(size.width-5,size.height-5), paint);
    canvas.drawLine(Offset(5,size.height/2), Offset(size.width-5,size.height/2), paint);
    
    canvas.drawLine(Offset(5,size.height/2), Offset(10,size.height/2-5), paint);
    canvas.drawLine(Offset(5,size.height/2), Offset(10,size.height/2+5), paint);

    canvas.drawLine(Offset(size.width-5,size.height/2), Offset(size.width-10,size.height/2-5), paint);
    canvas.drawLine(Offset(size.width-5,size.height/2), Offset(size.width-10,size.height/2+5), paint);
  }

  @override
  bool shouldRepaint(DimensionsIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class CoincidentConstraintIcon extends CustomPainter{
  Color color;
  CoincidentConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 1;

    canvas.drawLine(Offset(7,7), Offset(7,size.height-12.5), paint..color = color);
    canvas.drawLine(Offset(10.5,size.height-10), Offset(size.width-5,size.height-10), paint..color = Colors.red);
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,size.height-10), width: 4, height: 4), paint);
  }

  @override
  bool shouldRepaint(CoincidentConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ConcentricConstraintIcon extends CustomPainter{
  Color color;
  ConcentricConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    canvas.drawCircle(Offset(size.width/2,size.height/2), size.height/2-10, paint);
    canvas.drawCircle(Offset(size.width/2,size.height/2), size.height/2-5, paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(ConcentricConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class TangentConstraintIcon extends CustomPainter{
  Color color;
  TangentConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    canvas.drawLine(Offset(size.width/2,1), Offset(size.width-2,size.height/2+1), paint);
    canvas.drawCircle(Offset(size.width/2,size.height/2), size.height/2-7, paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(TangentConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class MidpointConstraintIcon extends CustomPainter{
  Color color;
  MidpointConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.red;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    canvas.drawLine(Offset(5,size.height-10), Offset(size.width-5,size.height-10), paint);
    canvas.drawLine(Offset(size.width/2,5), Offset(5,size.height-10), paint);
    canvas.drawLine(Offset(size.width/2,5), Offset(size.width-5,size.height-10), paint);
  }

  @override
  bool shouldRepaint(MidpointConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class EqualConstraintIcon extends CustomPainter{
  Color color;
  EqualConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;

    canvas.drawLine(Offset(5,size.height/2-5), Offset(size.width-5,size.height/2-5), paint);
    canvas.drawLine(Offset(5,size.height/2+5), Offset(size.width-5,size.height/2+5), paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(EqualConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ParallelConstraintIcon extends CustomPainter{
  Color color;
  ParallelConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    canvas.drawLine(Offset(7,size.height-5), Offset(size.width-5,size.height/2-5), paint);
    canvas.drawLine(Offset(5,size.height-12), Offset(size.width-7,size.height/2-12), paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(ParallelConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class PerpendicularConstraintIcon extends CustomPainter{
  Color color;
  PerpendicularConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    canvas.drawLine(Offset(size.width/2-1,size.height/2+1), Offset(size.width-5,5), paint);
    canvas.drawLine(Offset(7,10), Offset(size.width-10,size.height-7), paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(PerpendicularConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class HorizontalVerticalConstraintIcon extends CustomPainter{
  Color color;
  HorizontalVerticalConstraintIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    final double width = size.height/2;

    canvas.drawLine(Offset(size.width/2+2,5), Offset(size.width/2+2,size.height/2+2), paint);
    canvas.drawLine(Offset(width/2,size.height/2+6), Offset(width+width/2,size.height/2+6), paint);

    canvas.drawLine(Offset(size.width/2-2,5), Offset(size.width/2-2,size.height/2+2), paint..color = Colors.red);
    canvas.drawLine(Offset(size.width/2-7.5,5), Offset(size.width/2-2,9), paint);
    canvas.drawLine(Offset(size.width/2-7.5,10), Offset(size.width/2-2,14), paint);
    canvas.drawLine(Offset(size.width/2-7.5,15), Offset(size.width/2-2,19), paint);

    canvas.drawLine(Offset(width/2,size.height/2+10), Offset(width+width/2,size.height/2+10), paint);
    canvas.drawLine(Offset(width/2,size.height/2+14), Offset(width+width/2-12,size.height/2+10), paint);
    canvas.drawLine(Offset(width/2+5,size.height/2+14), Offset(width+width/2-6,size.height/2+10), paint);
    canvas.drawLine(Offset(width/2+10,size.height/2+14), Offset(width+width/2,size.height/2+10), paint);

    // canvas.drawLine(Offset(5,size.height/2), Offset(size.width-5,size.height/2), paint);
  }

  @override
  bool shouldRepaint(HorizontalVerticalConstraintIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}

class SketchIcon extends CustomPainter{
  Color color;
  SketchIcon(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2,size.height/2), width: size.width-15, height: size.height-15), paint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width*1/3,size.height*1/3), width: size.width*2/3, height: size.height*2/3), 
      0, 
      math.pi/2, 
      false, 
      paint
    );
    
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,7.5), width: 4, height: 4), paint..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromCenter(center: Offset(7.5,size.height-7.5), width: 4, height: 4), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,7.5), width: 4, height: 4), paint);

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*1/3,size.height*1/3), width: 2, height: 2), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*2/3,size.height*1/3), width: 2, height: 2), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width*1/3,size.height*2/3), width: 2, height: 2), paint);

    canvas.drawLine(Offset(size.width*1/3,size.height*1/3), Offset(size.width*2/3,size.height*1/3), paint);
    canvas.drawLine(Offset(size.width*1/3,size.height*1/3), Offset(size.width*1/3,size.height*2/3), paint);

    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 2, height: 8), paint..color = Colors.green);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width-7.5,size.height-7.5), width: 8, height: 2), paint..color = Colors.green);
  }

  @override
  bool shouldRepaint(SketchIcon oldDelegate) {
    return oldDelegate.color != color;
  }
}