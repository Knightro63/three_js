import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_audio/positional_audio.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class PositionalAudioHelper extends Line {
  PositionalAudio audio;
  double range;
  int divisionsInnerAngle;
  int divisionsOuterAngle;

	PositionalAudioHelper.create(
    super.geometry,
    super.materials,
    this.audio, 
    [this.range = 1, this.divisionsInnerAngle = 16, this.divisionsOuterAngle = 2 ]
  ){
		type = 'PositionalAudioHelper';
	  update();
	}

  factory PositionalAudioHelper(PositionalAudio audio, [ double range = 1, int divisionsInnerAngle = 16, int divisionsOuterAngle = 2 ]){
		final geometry = BufferGeometry();
		final divisions = divisionsInnerAngle + divisionsOuterAngle * 2;
		final positions = Float32List( ( divisions * 3 + 3 ) * 3 );
		geometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( positions, 3 ) );

		final materialInnerAngle = LineBasicMaterial.fromMap( { 'color': 0x00ff00 } );
		final materialOuterAngle = LineBasicMaterial.fromMap( { 'color': 0xffff00 } );

    return PositionalAudioHelper.create(
      geometry, 
      GroupMaterial([materialOuterAngle, materialInnerAngle]), 
      audio,
      range,divisionsInnerAngle,divisionsOuterAngle
    );
  }

	void update() {
		final audio = this.audio;
		final range = this.range;
		final divisionsInnerAngle = this.divisionsInnerAngle;
		final divisionsOuterAngle = this.divisionsOuterAngle;

		final coneInnerAngle = MathUtils.degToRad( audio.coneInnerAngle );
		final coneOuterAngle = MathUtils.degToRad( audio.coneOuterAngle );

		final halfConeInnerAngle = coneInnerAngle / 2;
		final halfConeOuterAngle = coneOuterAngle / 2;

		int start = 0;
		int count = 0;
		double i;
		int stride;

		final geometry = this.geometry;
		final positionAttribute = geometry?.attributes['position'];

		geometry?.clearGroups();

		void generateSegment(double from,double to,int divisions,int materialIndex ) {
			final double step = ( to - from ) / divisions;

			(positionAttribute as Float32BufferAttribute).setXYZ( start, 0, 0, 0 );
			count ++;

			for ( i = from; i < to; i += step ) {
				stride = start + count;
				positionAttribute.setXYZ( stride, math.sin( i ) * range, 0, math.cos( i ) * range );
				positionAttribute.setXYZ( stride + 1, math.sin( math.min( i + step, to ) ) * range, 0, math.cos( math.min( i + step, to ) ) * range );
				positionAttribute.setXYZ( stride + 2, 0, 0, 0 );

				count += 3;
			}

			geometry?.addGroup( start, count, materialIndex );

			start += count;
			count = 0;
		}

		//

		generateSegment( - halfConeOuterAngle, - halfConeInnerAngle, divisionsOuterAngle, 0 );
		generateSegment( - halfConeInnerAngle, halfConeInnerAngle, divisionsInnerAngle, 1 );
		generateSegment( halfConeInnerAngle, halfConeOuterAngle, divisionsOuterAngle, 0 );

		//

		positionAttribute.needsUpdate = true;

		if ( coneInnerAngle == coneOuterAngle ) (material as GroupMaterial).children[ 0 ].visible = false;

	}
  
  @override
	void dispose() {
		geometry?.dispose();
		(material as GroupMaterial).children[ 0 ].dispose();
		(material as GroupMaterial).children[ 1 ].dispose();
	}
}
