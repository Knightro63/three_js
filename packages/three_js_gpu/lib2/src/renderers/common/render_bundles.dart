import 'package:three_js_core/three_js_core.dart';
import './render_bundle.dart';
import './bundle_group.dart';
import './chain_map.dart';

List _chainKeys = [];

class RenderBundles {
  ChainMap bundles = ChainMap();

	RenderBundles();

	RenderBundle get(BundleGroup bundleGroup, Camera camera ) {
		final bundles = this.bundles;

		_chainKeys[ 0 ] = bundleGroup;
		_chainKeys[ 1 ] = camera;

		dynamic bundle = bundles.get( _chainKeys );

		if ( bundle == null ) {
			bundle = RenderBundle( bundleGroup, camera );
			bundles.set( _chainKeys, bundle );
		}

		_chainKeys.length = 0;

		return bundle;
	}

	void dispose() {
		bundles = ChainMap();
	}
}