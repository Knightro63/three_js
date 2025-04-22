import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import './projector.dart';
import 'svg_edge_finder.dart';
import 'dart:math' as math;

extension on Vector4{
  Vector3 toVector3(){
    return Vector3(x,y,z);
  }
}
// SVGObject = SVGObject;
// SVGRenderer = SVGRenderer;
enum SVGQuality{low,high}

class SVGDocument{
  SVGDocument({
    bool addHeader = false, 
    this.edgeOnly = false,
  }){
    if(addHeader){
      setAttribute('xmlns', 'http://www.w3.org/2000/svg');
      setAttribute('version', '1.1');
    }
  }

  bool edgeOnly;

  Map<String,String> attributes = {};
  Map<String,String> style = {};
  List<Map<String,String>> styleNodes = [];
  List<Map<String,String>> childNodes = [];

  void setAttribute(String attribute,String info){
    if(attribute == 'style'){
      style[attribute] = info;
    }
    else{
      attributes[attribute] = info;
    }
  }
  void appendChild(SVGDocument document){
    childNodes.add(document.attributes);
    styleNodes.add(document.style);
  }
  void removeChild(Map<String,String> node){
    //childNodes.remove(node);
  }

  @override
  String toString() {
    String tosend = '<svg';

    for(String key in attributes.keys){
      tosend += ' $key="${attributes[key]}"';
    }
    if(style.isNotEmpty){
      tosend += ' style=';
      for(String key in style.keys){
        tosend += '"$key: ${style[key]};"';
      }
    }
    tosend += '>';

    if(styleNodes.isNotEmpty){
      tosend += '<style type="text/css">.st{stroke:#33333;stroke-width:1;}';
      for(int i = 0; i < styleNodes.length; i++){
        tosend += '.st$i{';
        for(String key in styleNodes[i].keys){
          if(styleNodes[i][key] != 'null'){
            tosend += '${styleNodes[i][key]}';
          }
        }
        tosend += '}';
      }
      tosend += '</style>';
    }
    if(childNodes.isNotEmpty){
      for(int i = 0; i < childNodes.length;i++){
        tosend += '<path';
        for(String key in childNodes[i].keys){
          String? data = childNodes[i][key];
          if(edgeOnly){
            data = SvgEdgeFinder().reduce(childNodes[i][key]!);
          }
          tosend += ' $key="$data"';
        }
        tosend += ' class="st$i st"></path>';
      }
    }

    tosend += '</svg>';

    return tosend;
  }
}

class SVGRendererInfo{
  int vertices = 0;
  int faces = 0;
}

class SVGObject extends Object3D{
  SVGObject(node):super();
  SVGDocument node = SVGDocument();
  bool isSVGObject = true;
}


/// [SVGRenderer] can be used to render geometric data using SVG. The produced vector graphics are particular useful in the following use cases:
/// 
/// * Animated logos or icons
/// * Interactive 2D/3D diagrams or graphs
/// * Interactive maps
/// * Complex or animated user interfaces
/// 
/// [SVGRenderer] has various advantages. It produces crystal-clear and sharp output which is independent of the actual viewport resolution.
/// 
/// SVG elements can be styled via CSS. And they have good accessibility since it's possible to add metadata like title or description (useful for search engines or screen readers).
/// 
/// There are, however, some important limitations:
/// 
/// * No advanced shading
/// * No texture support
/// * No shadow support
class SVGRenderer {
  SVGRenderer({
    quality = SVGQuality.high,
    required this.width,
    required this.height,
    this.autoClear = false,
    this.precision,
    this.overdraw = 0.5,
    this.edgeOnly = false
  }){
    setSize(width,height);
    setQuality(quality);
  }
  late List<Object3D> _elements;
  List<Light>? lights;

  double width;
  double height;
  late double widthHalf;
  late double heightHalf;
  bool edgeOnly;
  
  //int _pathCount = 0;
  int? precision;
  SVGQuality quality = SVGQuality.low;
  String _currentPath = '';
  String _currentStyle = '';

  final BoundingBox _clipBox = BoundingBox();
  final BoundingBox _elemBox = BoundingBox();
  final Color _color = Color();
  final Color _diffuseColor = Color();
  final Color _ambientLight = Color();
  final Color _directionalLights = Color();
  final Color _pointLights = Color();
  final Color _clearColor = Color();

  final Vector3 _vector3 = Vector3();
  final Vector3 _centroid = Vector3();
  final Vector3 _normal = Vector3();
  final Matrix3 _normalViewMatrix = Matrix3.identity();
  final Matrix4 _viewMatrix = Matrix4.identity();
  final Matrix4 _viewProjectionMatrix = Matrix4.identity();

  SVGDocument svg = SVGDocument(addHeader:true,edgeOnly: true);
  SVGDocument _svgNode = SVGDocument();

  bool autoClear;
  bool sortObjects = true;
  bool sortElements = true;
  double overdraw = 0;
  SVGRendererInfo info = SVGRendererInfo();

  Vector2 get size => Vector2(width,height);

  /// Sets the render quality. Possible values are `low` and `high` (default).
  void setQuality(SVGQuality quality) {
    this.quality = quality;
  }
  
  /// Sets the clearColor and the clearAlpha.
  void setClearColor(Color color){
    _clearColor.setFrom( color );
  }
  void setPixelRatio(){

  }
  
  /// Resizes the renderer to (width, height).
  void setSize(double width,double height) {
    this.width = width;
    this.height = height;
    widthHalf = width/2;
    heightHalf = height/2;

    svg.setAttribute('viewBox','${-widthHalf} ${-heightHalf} $width $height');
    svg.setAttribute('width', width.toString());
    svg.setAttribute('height', height.toString());

    _clipBox.min.setValues(-widthHalf, -heightHalf, double.negativeInfinity);
    _clipBox.max.setValues(widthHalf, heightHalf, double.infinity );
  }
  
  /// Sets the precision of the data used to create a path.
  void setPrecision(int precision){
    this.precision = precision;
  }
  void removeChildNodes() {
    //_pathCount = 0;
    //svg.childNodes = [];
    // while(svg.childNodes.isNotEmpty){
    //   svg.removeChild(svg.childNodes[0]);
    // }
  }
  String convert(num c){
    return (precision != null ? c.toStringAsFixed(precision!) : c.toString());
  }
  
  /// Tells the renderer to clear its drawing surface.
  void clear() {
    svg = SVGDocument(addHeader:true,edgeOnly: true);
    svg.setAttribute('viewBox','${-widthHalf} ${-heightHalf} $width $height');
    svg.setAttribute('width', width.toString());
    svg.setAttribute('height', height.toString());
    //_pathCount = 0;
    _currentPath = '';
    _currentStyle = '';
    svg.style['background-color'] = _clearColor.getStyle();
  }

  /// Renders a [scene] using a [camera].
  void render(Scene scene, Camera camera){
    Projector projector = Projector();
    RenderData renderData = RenderData();
    dynamic background = scene.background;

    if(background != null && background is Color){
      removeChildNodes();
      svg.style['background-color'] = background.getStyle();
    } 
    else if(autoClear) {
      clear();
    }
    
    info.vertices = 0;
    info.faces = 0;
    _viewMatrix.setFrom( camera.matrixWorldInverse );
    _viewProjectionMatrix.multiply2( camera.projectionMatrix, _viewMatrix );
    renderData = projector.projectScene( scene, camera, sortObjects, sortElements );
    _elements = renderData.elements;
    lights = renderData.lights;
    _normalViewMatrix.getNormalMatrix( camera.matrixWorldInverse );
    calculateLights(lights!); // reset accumulated path

    _currentPath = '';
    _currentStyle = '';

    for (int e = 0; e < _elements.length; e ++ ) {
      Object3D element = _elements[e];
      Material? material = element.material;
      if(material == null || material.opacity == 0) continue;

      _elemBox.empty();

      if(element is RenderableSprite){
        RenderableSprite v1 = element;
        v1.x *= widthHalf;
        v1.y *= - heightHalf;
        renderSprite(v1, element, material );
      } 
      else if(element is RenderableLine){
        RenderableVertex v1 = element.v1;
        RenderableVertex v2 = element.v2;

        v1.positionScreen.x *= widthHalf;
        v1.positionScreen.y *= -heightHalf;
        v2.positionScreen.x *= widthHalf;
        v2.positionScreen.y *= -heightHalf;

        _elemBox.setFromPoints([v1.positionScreen.toVector3(), v2.positionScreen.toVector3()]);
        
        if (_clipBox.intersectsBox(_elemBox)) {
          renderLine(v1, v2, material);
        }
      } 
      else if(element is RenderableFace){
        RenderableVertex v1 = element.v1;
        RenderableVertex v2 = element.v2;
        RenderableVertex v3 = element.v3;
        if ( v1.positionScreen.z < - 1 || v1.positionScreen.z > 1 ) continue;
        if ( v2.positionScreen.z < - 1 || v2.positionScreen.z > 1 ) continue;
        if ( v3.positionScreen.z < - 1 || v3.positionScreen.z > 1 ) continue;
        v1.positionScreen.x *= widthHalf;
        v1.positionScreen.y *= - heightHalf;
        v2.positionScreen.x *= widthHalf;
        v2.positionScreen.y *= - heightHalf;
        v3.positionScreen.x *= widthHalf;
        v3.positionScreen.y *= - heightHalf;

        if (overdraw > 0 && !edgeOnly) {
          expand( v1.positionScreen, v2.positionScreen, overdraw );
          expand( v2.positionScreen, v3.positionScreen, overdraw );
          expand( v3.positionScreen, v1.positionScreen, overdraw );
        }

        _elemBox.setFromPoints([ v1.positionScreen.toVector3(), v2.positionScreen.toVector3(), v3.positionScreen.toVector3()]);

        if(_clipBox.intersectsBox(_elemBox)){
          renderFace3( v1, v2, v3, element, material );
        }
      }
    }

    flushPath(); // just to flush last svg:path

    scene.traverseVisible((object){
      if(object is SVGObject){
        _vector3.setFromMatrixPosition( object.matrixWorld );
        _vector3.applyMatrix4( _viewProjectionMatrix );

        if ( _vector3.z < - 1 || _vector3.z > 1 ) return;
        double x = _vector3.x * widthHalf;
        double y = - _vector3.y * heightHalf;
        SVGDocument node = object.node;
        node.setAttribute('transform', 'translate($x,$y)');
        svg.appendChild( node );
      }
    });
  }

  void calculateLights(List<Light> lights){
    _ambientLight.setValues( 0, 0, 0 );
    _directionalLights.setValues( 0, 0, 0 );
    _pointLights.setValues( 0, 0, 0 );

    for(int l = 0; l < lights.length; l ++ ) {
      Light light = lights[l];
      Color lightColor = light.color ?? Color();

      if (light is AmbientLight) {
        _ambientLight.red += lightColor.red;
        _ambientLight.green += lightColor.green;
        _ambientLight.blue += lightColor.blue;
      } else if (light is DirectionalLight) {
        _directionalLights.red += lightColor.red;
        _directionalLights.green += lightColor.green;
        _directionalLights.blue += lightColor.blue;
      } else if (light is PointLight) {
        _pointLights.red += lightColor.red;
        _pointLights.green += lightColor.green;
        _pointLights.blue += lightColor.blue;
      }
    }
  }
  void calculateLight(List<Light> lights,Vector3 position,Vector3 normal,Color color){
    for(int l = 0; l < lights.length; l ++ ) {
      Light light = lights[l];
      Color lightColor = light.color ?? Color();

      if(light is DirectionalLight){
        Vector3 lightPosition = _vector3.setFromMatrixPosition( light.matrixWorld ).normalize();

        num amount = normal.dot( lightPosition );
        if ( amount <= 0 ) continue;
        amount *= light.intensity;
        color.red += lightColor.red * amount;
        color.green += lightColor.green * amount;
        color.blue += lightColor.blue * amount;
      } 
      else if (light is PointLight){
        Vector3 lightPosition = _vector3.setFromMatrixPosition( light.matrixWorld );

        num amount = normal.dot( _vector3.sub2( lightPosition, position ).normalize() );
        if ( amount <= 0 ) continue;
        amount *= light.distance == 0 ? 1 : 1 - math.min( position.distanceTo( lightPosition ) / light.distance!, 1 );
        if ( amount == 0 ) continue;
        amount *= light.intensity;
        color.red += lightColor.red * amount;
        color.green += lightColor.green * amount;
        color.blue += lightColor.blue * amount;
      }
    }
  }
  void renderSprite(RenderableSprite v1,RenderableSprite element, Material material){
    double scaleX = element.scale.x * widthHalf;
    double scaleY = element.scale.y * heightHalf;

    if (material is PointsMaterial) {
      scaleX *= material.size!;
      scaleY *= material.size!;
    }

    String path = 'M${convert( v1.x - scaleX * 0.5 )},${convert( v1.y - scaleY * 0.5 )}h${convert( scaleX )}v${convert( scaleY )}h${convert( - scaleX )}z';
    String style = '';

    if ( material is SpriteMaterial || material is PointsMaterial ) {
      style = 'fill:${material.color.getStyle()};fill-opacity:${material.opacity}';
    }
    addPath(style, path);
  }
  void renderLine(RenderableVertex v1, RenderableVertex v2, Material material ) {
    try{
      String path = 'M${convert(v1.positionScreen.x)},${convert( v1.positionScreen.y )}L${convert( v2.positionScreen.x )},${convert( v2.positionScreen.y )}';
      if (material is LineBasicMaterial) {
        String style = 'fill:none;stroke:${material.color.getStyle()};stroke-opacity:${material.opacity};stroke-width:${material.linewidth};stroke-linecap:${material.linecap}';
        if ( material is LineDashedMaterial ) {
          style = '$style;stroke-dasharray:${material.dashSize!},${material.gapSize!}';
        }
        addPath(style, path);
      }
    }
    catch(e){
      print('svg_renderer.dart -> renderLine -> Exception: $e');
    }
  }

  void renderFace3(RenderableVertex v1,RenderableVertex v2,RenderableVertex v3, RenderableFace element, Material material) {
    try{
    info.vertices += 3;
    info.faces ++;
    String path = 'M${convert(v1.positionScreen.x)},${convert( v1.positionScreen.y )}L${convert( v2.positionScreen.x )},${convert( v2.positionScreen.y )}L${convert( v3.positionScreen.x )},${convert( v3.positionScreen.y )}z';
    String style = '';

    if ( material is MeshBasicMaterial) {
      _color.setFrom(material.color);
      if ( material.vertexColors ) {
        _color.multiply(element.color);
      }
    } 
    else if ( material is MeshLambertMaterial || material is MeshPhongMaterial || material is MeshStandardMaterial ) {
      _diffuseColor.setFrom( material.color );

      if ( material.vertexColors ) {
        _diffuseColor.multiply( element.color );
      }

      _color.setFrom( _ambientLight );
      _centroid.setFrom( v1.positionWorld ).add( v2.positionWorld ).add( v3.positionWorld ).divideScalar( 3 );
      calculateLight(lights!, _centroid, element.normalModel, _color);
      _color.multiply( _diffuseColor ).add(material.emissive!);

    } 
    else if ( material is MeshNormalMaterial ) {
      _normal.setFrom( element.normalModel ).applyMatrix3( _normalViewMatrix ).normalize();
      _color..setValues( _normal.x, _normal.y, _normal.z )..scale( 0.5 )..addScalar( 0.5 );
    }

    String colorStyle = _color.getStyle();

    if ( material.wireframe ) {
      style = 'fill:none;stroke:$colorStyle;stroke-opacity:${material.opacity};stroke-width:${material.wireframeLinewidth};stroke-linecap:${material.wireframeLinecap};stroke-linejoin:${material.wireframeLinejoin}';
    } 
    else {
      style = 'fill:$colorStyle;fill-opacity:${material.opacity}';
    }
    addPath(style, path);
    }
    catch(e){
      print('svg_renderer.dart -> renderFace3 -> Exception: $e');
    }
  } // Hide anti-alias gaps
  void expand(Vector4 v1,Vector4 v2, double pixels) {
    num x = v2.x - v1.x;
    num y = v2.y - v1.y;
    num det = x * x + y * y;
    if (det == 0) return;
    num idet = pixels / math.sqrt( det );
    x *= idet;
    y *= idet;
    v2.x += x;
    v2.y += y;
    v1.x -= x;
    v1.y -= y;
  }
  void addPath(String style, String path) {
    try{
      if(_currentStyle == style) {
        _currentPath += path;
      } 
      else {
        flushPath();
        _currentStyle = style;
        _currentPath = path;
      }
    }
    catch(e){
      print('svg_renderer.dart -> addPath -> Exception: $e');
    }
  }
  void flushPath() {
    try{
    if(_currentPath != '') {
      //_pathCount++;
      _svgNode.setAttribute('d', _currentPath);
      _svgNode.setAttribute('style', _currentStyle);
      svg.appendChild(_svgNode);
      _svgNode= SVGDocument();
    }
    _currentPath = '';
    _currentStyle = '';
    }
    catch(e){
      print('svg_renderer.dart -> flushPath -> Exception: $e');
    }
  }
}
