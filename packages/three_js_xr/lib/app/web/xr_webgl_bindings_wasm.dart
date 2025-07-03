import 'dart:js_interop';

@JS('navigator')
external JSObject get navigator; 

@JS('navigator.xr')
external JSObject get xrSystem;