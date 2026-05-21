import "package:three_js_core/three_js_core.dart";

class BundleGroup extends GroupMaterial {
  bool static = true;

	BundleGroup():super(){
    type = 'BundleGroup';
    version = 0;
  }

  @override
	set needsUpdate( value ) {
		if ( value == true ) version ++;
	}
}
