import 'loader.dart';

final defaultLoadingManager = LoadingManager();

/// Handles and keeps track of loaded and pending data. A default global
/// instance of this class is created and used by loaders if not supplied
/// manually - see [DefaultLoadingManager].
///
/// In general that should be sufficient, however there are times when it can
/// be useful to have separate loaders - for example if you want to show
/// separate loading bars for objects and textures.
class LoadingManager {
  bool isLoading = false;
  int itemsLoaded = 0;
  int itemsTotal = 0;
  List handlers = [];

  String Function(String)? urlModifier;
  void Function(String,int,int)? onStart;
  void Function()? onLoad;
  void Function(String,int,int)? onProgress;
  void Function(String)? onError;


  /// [onLoad] — (optional) this function will be called when all
  /// loaders are done.
  /// 
  /// [onProgress] — (optional) this function will be called when
  /// an item is complete.
  /// 
  /// [onError] — (optional) this function will be called a loader
  /// encounters errors.
  /// 
  LoadingManager([this.onLoad, this.onProgress, this.onError]);

  /// [url] — the url to load
  /// 
  /// This should be called by any loader using the manager when the loader
  /// starts loading an url.
  void itemStart(String url) {
    itemsTotal++;
    if (isLoading == false) {
      if (onStart != null) {
        onStart!(url, itemsLoaded, itemsTotal);
      }
    }
    isLoading = true;
  }

  /// [url] — the loaded url
  /// 
  /// This should be called by any loader using the manager when the loader
  /// ended loading an url.
  void itemEnd(String url) {
    itemsLoaded++;

    if (onProgress != null) {
      onProgress!(url, itemsLoaded, itemsTotal);
    }

    if (itemsLoaded == itemsTotal) {
      isLoading = false;

      if (onLoad != null) {
        onLoad!();
      }
    }
  }

  /// [url] — the loaded url
  /// 
  /// This should be called by any loader using the manager when the loader
  /// errors loading an url.
  void itemError(String url) {
    if (onError != null) {
      onError!(url);
    }
  }

  /// [url] — the url to load
  /// 
  /// Given a URL, uses the URL modifier callback (if any) and returns a
  /// resolved URL. If no URL modifier is set, returns the original URL.
  String resolveURL(String url) {
    if (urlModifier != null) {
      return urlModifier!(url);
    }
    return url;
  }

  /// [callback] — URL modifier callback. Called with [url] argument, 
  /// and must return [resolvedURL].
  /// 
  /// If provided, the callback will be passed each resource URL before a
  /// request is sent. The callback may return the original URL, or a new URL to
  /// override loading behavior. This behavior can be used to load assets from
  /// .ZIP files, drag-and-drop APIs, and Data URIs.
  /// 
  /// <em>
  ///   Note: The following methods are designed to be called internally by
  ///   loaders. You shouldn't call them directly.
  /// </em>
  LoadingManager setURLModifier(String Function(String)? transform) {
    urlModifier = transform;
    return this;
  }

  /// [regex] — A regular expression.
  /// 
  /// [loader] — The loader.
  /// 
  /// Registers a loader with the given regular expression. Can be used to
  /// define what loader should be used in order to load specific files. A
  /// typical use case is to overwrite the default loader for textures.
  LoadingManager addHandler(RegExp regex, Loader loader) {
    handlers.addAll([regex, loader]);
    return this;
  }

  /// [regex] — A regular expression.
  /// 
  /// Removes the loader for the given regular expression.
  LoadingManager removeHandler(RegExp regex) {
    final index = handlers.indexOf(regex);
    if (index != -1) {
      handlers.removeRange(index, index + 1);
    }
    return this;
  }
  
  /// [file] — The file path.
  /// 
  /// Can be used to retrieve the registered loader for the given file path.
  Loader? getHandler(String file) {
    for (int i = 0, l = handlers.length; i < l; i += 2) {
      final RegExp regex = handlers[i];
      final Loader loader = handlers[i + 1];

      // if (regex.global){ 
      //   regex.lastIndex = 0; // see #17920
      // }

      if (regex.hasMatch(file)) {// .test(file)
        return loader;
      }
    }

    return null;
  }
}
