import 'package:three_js_advanced_loaders/usd/usd_loader.dart';
import 'package:three_js_core/three_js_core.dart';

class USDZLoader extends USDLoader {
	USDZLoader([super.manager]) {
		console.warning( 'USDZLoader has been deprecated. Please use USDLoader instead.' );
	}
}