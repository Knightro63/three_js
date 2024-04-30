import 'loader.dart';

final defaultLoadingManager = LoadingManager();

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

  LoadingManager([this.onLoad, this.onProgress, this.onError]);

  void itemStart(String url) {
    itemsTotal++;
    if (isLoading == false) {
      if (onStart != null) {
        onStart!(url, itemsLoaded, itemsTotal);
      }
    }
    isLoading = true;
  }

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

  void itemError(String url) {
    if (onError != null) {
      onError!(url);
    }
  }

  String resolveURL(String url) {
    if (urlModifier != null) {
      return urlModifier!(url);
    }
    return url;
  }

  LoadingManager setURLModifier(String Function(String)? transform) {
    urlModifier = transform;
    return this;
  }

  LoadingManager addHandler(RegExp regex, Loader loader) {
    handlers.addAll([regex, loader]);
    return this;
  }

  LoadingManager removeHandler(RegExp regex) {
    final index = handlers.indexOf(regex);
    if (index != -1) {
      handlers.removeRange(index, index + 1);
    }
    return this;
  }

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
