import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglPeriodictable extends StatefulWidget {
  const WebglPeriodictable({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglPeriodictable> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    kinematicsTween.forEach((t){
      t.dispose();
    });
    table.clear();
    kinematicsTween.clear();
    objects.clear();
    controls.dispose();
    targets.clear();
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: (){
                    transform( targets['table'], 2000 );
                  },
                  child: Container(
                    width: 75,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255,0, 127, 127),
                      border: Border.all(
                        color: Colors.white,
                        width: 2
                      )
                    ),
                    child: const Text(
                      'table',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white
                      ),
                    ),
                  )
                ),
                InkWell(
                  onTap: (){
                    transform( targets['sphere'], 2000 );
                  },
                  child: Container(
                    width: 75,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255,0, 127, 127),
                      border: Border.all(
                        color: Colors.white,
                        width: 2
                      )
                    ),
                    child: const Text(
                      'sphere',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white
                      ),
                    ),
                  )
                ),
                InkWell(
                  onTap: (){
                    transform( targets['helix'], 2000 );
                  },
                  child: Container(
                    width: 75,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255,0, 127, 127),
                      border: Border.all(
                        color: Colors.white,
                        width: 2
                      )
                    ),
                    child: const Text(
                      'helix',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white
                      ),
                    ),
                  )
                ),
                InkWell(
                  onTap: (){
                    transform( targets['grid'], 2000 );
                  },
                  child: Container(
                    width: 75,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255,0, 127, 127),
                      border: Border.all(
                        color: Colors.white,
                        width: 2
                      )
                    ),
                    child: const Text(
                      'grid',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white
                      ),
                    ),
                  )
                )
              ],
            ),
          )
        ],
      ) 
    );
  }

  final List<dynamic> table = [
    'H', 'Hydrogen', '1.00794', 1, 1,
    'He', 'Helium', '4.002602', 18, 1,
    'Li', 'Lithium', '6.941', 1, 2,
    'Be', 'Beryllium', '9.012182', 2, 2,
    'B', 'Boron', '10.811', 13, 2,
    'C', 'Carbon', '12.0107', 14, 2,
    'N', 'Nitrogen', '14.0067', 15, 2,
    'O', 'Oxygen', '15.9994', 16, 2,
    'F', 'Fluorine', '18.9984032', 17, 2,
    'Ne', 'Neon', '20.1797', 18, 2,
    'Na', 'Sodium', '22.98976...', 1, 3,
    'Mg', 'Magnesium', '24.305', 2, 3,
    'Al', 'Aluminium', '26.9815386', 13, 3,
    'Si', 'Silicon', '28.0855', 14, 3,
    'P', 'Phosphorus', '30.973762', 15, 3,
    'S', 'Sulfur', '32.065', 16, 3,
    'Cl', 'Chlorine', '35.453', 17, 3,
    'Ar', 'Argon', '39.948', 18, 3,
    'K', 'Potassium', '39.948', 1, 4,
    'Ca', 'Calcium', '40.078', 2, 4,
    'Sc', 'Scandium', '44.955912', 3, 4,
    'Ti', 'Titanium', '47.867', 4, 4,
    'V', 'Vanadium', '50.9415', 5, 4,
    'Cr', 'Chromium', '51.9961', 6, 4,
    'Mn', 'Manganese', '54.938045', 7, 4,
    'Fe', 'Iron', '55.845', 8, 4,
    'Co', 'Cobalt', '58.933195', 9, 4,
    'Ni', 'Nickel', '58.6934', 10, 4,
    'Cu', 'Copper', '63.546', 11, 4,
    'Zn', 'Zinc', '65.38', 12, 4,
    'Ga', 'Gallium', '69.723', 13, 4,
    'Ge', 'Germanium', '72.63', 14, 4,
    'As', 'Arsenic', '74.9216', 15, 4,
    'Se', 'Selenium', '78.96', 16, 4,
    'Br', 'Bromine', '79.904', 17, 4,
    'Kr', 'Krypton', '83.798', 18, 4,
    'Rb', 'Rubidium', '85.4678', 1, 5,
    'Sr', 'Strontium', '87.62', 2, 5,
    'Y', 'Yttrium', '88.90585', 3, 5,
    'Zr', 'Zirconium', '91.224', 4, 5,
    'Nb', 'Niobium', '92.90628', 5, 5,
    'Mo', 'Molybdenum', '95.96', 6, 5,
    'Tc', 'Technetium', '(98)', 7, 5,
    'Ru', 'Ruthenium', '101.07', 8, 5,
    'Rh', 'Rhodium', '102.9055', 9, 5,
    'Pd', 'Palladium', '106.42', 10, 5,
    'Ag', 'Silver', '107.8682', 11, 5,
    'Cd', 'Cadmium', '112.411', 12, 5,
    'In', 'Indium', '114.818', 13, 5,
    'Sn', 'Tin', '118.71', 14, 5,
    'Sb', 'Antimony', '121.76', 15, 5,
    'Te', 'Tellurium', '127.6', 16, 5,
    'I', 'Iodine', '126.90447', 17, 5,
    'Xe', 'Xenon', '131.293', 18, 5,
    'Cs', 'Caesium', '132.9054', 1, 6,
    'Ba', 'Barium', '132.9054', 2, 6,
    'La', 'Lanthanum', '138.90547', 4, 9,
    'Ce', 'Cerium', '140.116', 5, 9,
    'Pr', 'Praseodymium', '140.90765', 6, 9,
    'Nd', 'Neodymium', '144.242', 7, 9,
    'Pm', 'Promethium', '(145)', 8, 9,
    'Sm', 'Samarium', '150.36', 9, 9,
    'Eu', 'Europium', '151.964', 10, 9,
    'Gd', 'Gadolinium', '157.25', 11, 9,
    'Tb', 'Terbium', '158.92535', 12, 9,
    'Dy', 'Dysprosium', '162.5', 13, 9,
    'Ho', 'Holmium', '164.93032', 14, 9,
    'Er', 'Erbium', '167.259', 15, 9,
    'Tm', 'Thulium', '168.93421', 16, 9,
    'Yb', 'Ytterbium', '173.054', 17, 9,
    'Lu', 'Lutetium', '174.9668', 18, 9,
    'Hf', 'Hafnium', '178.49', 4, 6,
    'Ta', 'Tantalum', '180.94788', 5, 6,
    'W', 'Tungsten', '183.84', 6, 6,
    'Re', 'Rhenium', '186.207', 7, 6,
    'Os', 'Osmium', '190.23', 8, 6,
    'Ir', 'Iridium', '192.217', 9, 6,
    'Pt', 'Platinum', '195.084', 10, 6,
    'Au', 'Gold', '196.966569', 11, 6,
    'Hg', 'Mercury', '200.59', 12, 6,
    'Tl', 'Thallium', '204.3833', 13, 6,
    'Pb', 'Lead', '207.2', 14, 6,
    'Bi', 'Bismuth', '208.9804', 15, 6,
    'Po', 'Polonium', '(209)', 16, 6,
    'At', 'Astatine', '(210)', 17, 6,
    'Rn', 'Radon', '(222)', 18, 6,
    'Fr', 'Francium', '(223)', 1, 7,
    'Ra', 'Radium', '(226)', 2, 7,
    'Ac', 'Actinium', '(227)', 4, 10,
    'Th', 'Thorium', '232.03806', 5, 10,
    'Pa', 'Protactinium', '231.0588', 6, 10,
    'U', 'Uranium', '238.02891', 7, 10,
    'Np', 'Neptunium', '(237)', 8, 10,
    'Pu', 'Plutonium', '(244)', 9, 10,
    'Am', 'Americium', '(243)', 10, 10,
    'Cm', 'Curium', '(247)', 11, 10,
    'Bk', 'Berkelium', '(247)', 12, 10,
    'Cf', 'Californium', '(251)', 13, 10,
    'Es', 'Einstenium', '(252)', 14, 10,
    'Fm', 'Fermium', '(257)', 15, 10,
    'Md', 'Mendelevium', '(258)', 16, 10,
    'No', 'Nobelium', '(259)', 17, 10,
    'Lr', 'Lawrencium', '(262)', 18, 10,
    'Rf', 'Rutherfordium', '(267)', 4, 7,
    'Db', 'Dubnium', '(268)', 5, 7,
    'Sg', 'Seaborgium', '(271)', 6, 7,
    'Bh', 'Bohrium', '(272)', 7, 7,
    'Hs', 'Hassium', '(270)', 8, 7,
    'Mt', 'Meitnerium', '(276)', 9, 7,
    'Ds', 'Darmstadium', '(281)', 10, 7,
    'Rg', 'Roentgenium', '(280)', 11, 7,
    'Cn', 'Copernicium', '(285)', 12, 7,
    'Nh', 'Nihonium', '(286)', 13, 7,
    'Fl', 'Flerovium', '(289)', 14, 7,
    'Mc', 'Moscovium', '(290)', 15, 7,
    'Lv', 'Livermorium', '(293)', 16, 7,
    'Ts', 'Tennessine', '(294)', 17, 7,
    'Og', 'Oganesson', '(294)', 18, 7
  ];

  late final three.OrbitControls controls;
  final objects = [];
	final targets = { 'table': [], 'sphere': [], 'helix': [], 'grid': [] };
  late final List<three.Tween> kinematicsTween = [];

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.z = 3000;
    threeJs.scene = three.Scene();

    // table

    for ( int i = 0; i < table.length; i += 5 ) {
      final texture = await three.FlutterTexture.fromWidget(
        context,
        Transform.flip(
          //flipX: !kIsWeb?true:false,
          flipY: !kIsWeb?true:false,
          child: Container(
            width: 155,
            height: 200,
            padding: const EdgeInsets.all(10),
            color: Color.fromRGBO(0, 127, 127,( math.Random().nextDouble() * 0.5 + 0.25 )),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  alignment: Alignment.topRight,
                  child: Text(
                    (( i / 5 ) + 1).toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white
                    ),
                  ),
                ),
                Text(
                  table[ i ].toString(),
                  style: const TextStyle(
                    fontSize: 64,
                    color: Colors.white
                  ),
                ),
                Column(
                  children: [
                    Text(
                      table[ i + 1 ].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white
                      ),
                    ),
                    Text(
                      table[ i + 2 ].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        )
      );
      final geometry = three.PlaneGeometry(150*(1.55/2),150);
      final material = three.MeshBasicMaterial.fromMap( {
        'map': texture,
        'side': three.DoubleSide,
        'transparent': true,
      } );
      final objectCSS = three.Mesh( geometry, material );
      objectCSS.position.x = math.Random().nextDouble() * 4000 - 2000;
      objectCSS.position.y = math.Random().nextDouble() * 4000 - 2000;
      objectCSS.position.z = math.Random().nextDouble() * 4000 - 2000;
      threeJs.scene.add( objectCSS );

      objects.add( objectCSS );

      final object = three.Object3D();
      object.position.x = ( table[ i + 3 ] * 140 ) - 1330.0;
      object.position.y = - ( table[ i + 4 ] * 180 ) + 990.0;

      targets['table']!.add( object );
    }

    // sphere

    final vector = three.Vector3();

    for (int i = 0, l = objects.length; i < l; i ++ ) {
      final phi = math.acos( - 1 + ( 2 * i ) / l );
      final theta = math.sqrt( l * math.pi ) * phi;
      final object = three.Object3D();

      object.position.setFromSphericalCoords( 800, phi, theta );
      vector.setFrom( object.position ).scale( 2 );
      object.lookAt( vector );
      targets['sphere']!.add( object );
    }

    // helix

    for (int i = 0, l = objects.length; i < l; i ++ ) {
      final theta = i * 0.175 + math.pi;
      final double y = - ( i * 8 ) + 450;
      final object = three.Object3D();

      object.position.setFromCylindricalCoords( 900, theta, y );

      vector.x = object.position.x * 2;
      vector.y = object.position.y;
      vector.z = object.position.z * 2;

      object.lookAt( vector );

      targets['helix']!.add( object );
    }

    // grid

    for (int i = 0; i < objects.length; i ++ ) {
      final object = three.Object3D();

      object.position.x = ( ( i % 5 ) * 400 ) - 800;
      object.position.y = ( - ( ( i / 5 ).floor() % 5 ) * 400 ) + 800;
      object.position.z = ( ( i / 25 ).floor() ) * 1000 - 2000;

      targets['grid']!.add( object );
    }

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 500;
    controls.maxDistance = 6000;
    //controls.addEventListener( 'change', render );

    transform( targets['table'], 2000 );

    threeJs.addAnimationEvent((dt){
      for(final tweens in kinematicsTween){
        tweens.update();
      }
			controls.update();
    });
  }

  transform( targets, duration ) {

    //kinematicsTween.removeAll();

    for (int i = 0; i < objects.length; i ++ ) {
      final object = objects[ i ];
      final target = targets[ i ];
      kinematicsTween.add(
        three.Tween( object.position )
        .to( { 0: target.position.x, 1: target.position.y, 2: target.position.z }, (math.Random().nextDouble() * duration + duration).toInt() )
        .easing( three.Easing.Exponential[three.ETTypes.InOut] )
        .start()
      );

      kinematicsTween.add(
        three.Tween( object.rotation )
        .to( { 0: target.rotation.x, 1: target.rotation.y, 2: target.rotation.z }, (math.Random().nextDouble() * duration + duration).toInt() )
        .easing( three.Easing.Exponential[three.ETTypes.InOut] )
        .start()
      );
    }

    kinematicsTween.add(
      three.Tween( this )
      .to( {}, duration * 2 )
      .onUpdate( render )
      .start()
    );
  }

  render(i,j) {
    threeJs.render();
  }
}
