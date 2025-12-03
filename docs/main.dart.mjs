// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _4: (o, c) => o instanceof c,
      _5: o => Object.keys(o),
      _8: (o, a) => o + a,
      _36: x0 => new Array(x0),
      _38: x0 => x0.length,
      _40: (x0,x1) => x0[x1],
      _41: (x0,x1,x2) => { x0[x1] = x2 },
      _43: x0 => new Promise(x0),
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _65: (x0,x1,x2) => x0.call(x1,x2),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _73: (s) => +s,
      _74: x0 => new Uint8Array(x0),
      _75: (x0,x1,x2) => x0.set(x1,x2),
      _76: (x0,x1) => x0.transferFromImageBitmap(x1),
      _77: x0 => x0.arrayBuffer(),
      _78: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._78(f,arguments.length,x0) }),
      _79: x0 => new window.FinalizationRegistry(x0),
      _80: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _81: (x0,x1) => x0.unregister(x1),
      _82: (x0,x1,x2) => x0.slice(x1,x2),
      _83: (x0,x1) => x0.decode(x1),
      _84: (x0,x1) => x0.segment(x1),
      _85: () => new TextDecoder(),
      _87: x0 => x0.buffer,
      _88: x0 => x0.wasmMemory,
      _89: () => globalThis.window._flutter_skwasmInstance,
      _90: x0 => x0.rasterStartMilliseconds,
      _91: x0 => x0.rasterEndMilliseconds,
      _92: x0 => x0.imageBitmaps,
      _196: x0 => x0.stopPropagation(),
      _197: x0 => x0.preventDefault(),
      _199: x0 => x0.remove(),
      _200: (x0,x1) => x0.append(x1),
      _201: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _246: x0 => x0.unlock(),
      _247: x0 => x0.getReader(),
      _248: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _249: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _250: (x0,x1) => x0.item(x1),
      _251: x0 => x0.next(),
      _252: x0 => x0.now(),
      _253: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._253(f,arguments.length,x0) }),
      _254: (x0,x1) => x0.addListener(x1),
      _255: (x0,x1) => x0.removeListener(x1),
      _256: (x0,x1) => x0.matchMedia(x1),
      _257: (x0,x1) => x0.revokeObjectURL(x1),
      _258: x0 => x0.close(),
      _259: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _260: x0 => new window.ImageDecoder(x0),
      _261: x0 => ({frameIndex: x0}),
      _262: (x0,x1) => x0.decode(x1),
      _263: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._263(f,arguments.length,x0) }),
      _264: (x0,x1) => x0.getModifierState(x1),
      _265: (x0,x1) => x0.removeProperty(x1),
      _266: (x0,x1) => x0.prepend(x1),
      _267: x0 => new Intl.Locale(x0),
      _268: x0 => x0.disconnect(),
      _269: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._269(f,arguments.length,x0) }),
      _270: (x0,x1) => x0.getAttribute(x1),
      _271: (x0,x1) => x0.contains(x1),
      _272: (x0,x1) => x0.querySelector(x1),
      _273: x0 => x0.blur(),
      _274: x0 => x0.hasFocus(),
      _275: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _276: (x0,x1) => x0.hasAttribute(x1),
      _277: (x0,x1) => x0.getModifierState(x1),
      _278: (x0,x1) => x0.createTextNode(x1),
      _279: (x0,x1) => x0.appendChild(x1),
      _280: (x0,x1) => x0.removeAttribute(x1),
      _281: x0 => x0.getBoundingClientRect(),
      _282: (x0,x1) => x0.observe(x1),
      _283: x0 => x0.disconnect(),
      _284: (x0,x1) => x0.closest(x1),
      _707: () => globalThis.window.flutterConfiguration,
      _709: x0 => x0.assetBase,
      _714: x0 => x0.canvasKitMaximumSurfaces,
      _715: x0 => x0.debugShowSemanticsNodes,
      _716: x0 => x0.hostElement,
      _717: x0 => x0.multiViewEnabled,
      _718: x0 => x0.nonce,
      _720: x0 => x0.fontFallbackBaseUrl,
      _730: x0 => x0.console,
      _731: x0 => x0.devicePixelRatio,
      _732: x0 => x0.document,
      _733: x0 => x0.history,
      _734: x0 => x0.innerHeight,
      _735: x0 => x0.innerWidth,
      _736: x0 => x0.location,
      _737: x0 => x0.navigator,
      _738: x0 => x0.visualViewport,
      _739: x0 => x0.performance,
      _741: x0 => x0.URL,
      _743: (x0,x1) => x0.getComputedStyle(x1),
      _744: x0 => x0.screen,
      _745: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._745(f,arguments.length,x0) }),
      _746: (x0,x1) => x0.requestAnimationFrame(x1),
      _751: (x0,x1) => x0.warn(x1),
      _753: (x0,x1) => x0.debug(x1),
      _754: x0 => globalThis.parseFloat(x0),
      _755: () => globalThis.window,
      _756: () => globalThis.Intl,
      _757: () => globalThis.Symbol,
      _758: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _760: x0 => x0.clipboard,
      _761: x0 => x0.maxTouchPoints,
      _762: x0 => x0.vendor,
      _763: x0 => x0.language,
      _764: x0 => x0.platform,
      _765: x0 => x0.userAgent,
      _766: (x0,x1) => x0.vibrate(x1),
      _767: x0 => x0.languages,
      _768: x0 => x0.documentElement,
      _769: (x0,x1) => x0.querySelector(x1),
      _772: (x0,x1) => x0.createElement(x1),
      _775: (x0,x1) => x0.createEvent(x1),
      _776: x0 => x0.activeElement,
      _779: x0 => x0.head,
      _780: x0 => x0.body,
      _782: (x0,x1) => { x0.title = x1 },
      _785: x0 => x0.visibilityState,
      _786: () => globalThis.document,
      _787: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._787(f,arguments.length,x0) }),
      _788: (x0,x1) => x0.dispatchEvent(x1),
      _796: x0 => x0.target,
      _798: x0 => x0.timeStamp,
      _799: x0 => x0.type,
      _801: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _808: x0 => x0.firstChild,
      _812: x0 => x0.parentElement,
      _814: (x0,x1) => { x0.textContent = x1 },
      _815: x0 => x0.parentNode,
      _816: x0 => x0.nextSibling,
      _817: (x0,x1) => x0.removeChild(x1),
      _818: x0 => x0.isConnected,
      _826: x0 => x0.clientHeight,
      _827: x0 => x0.clientWidth,
      _828: x0 => x0.offsetHeight,
      _829: x0 => x0.offsetWidth,
      _830: x0 => x0.id,
      _831: (x0,x1) => { x0.id = x1 },
      _834: (x0,x1) => { x0.spellcheck = x1 },
      _835: x0 => x0.tagName,
      _836: x0 => x0.style,
      _838: (x0,x1) => x0.querySelectorAll(x1),
      _839: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _840: (x0,x1) => { x0.tabIndex = x1 },
      _841: x0 => x0.tabIndex,
      _842: (x0,x1) => x0.focus(x1),
      _843: x0 => x0.scrollTop,
      _844: (x0,x1) => { x0.scrollTop = x1 },
      _845: x0 => x0.scrollLeft,
      _846: (x0,x1) => { x0.scrollLeft = x1 },
      _847: x0 => x0.classList,
      _849: (x0,x1) => { x0.className = x1 },
      _851: (x0,x1) => x0.getElementsByClassName(x1),
      _852: x0 => x0.click(),
      _853: (x0,x1) => x0.attachShadow(x1),
      _856: x0 => x0.computedStyleMap(),
      _857: (x0,x1) => x0.get(x1),
      _863: (x0,x1) => x0.getPropertyValue(x1),
      _864: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _865: x0 => x0.offsetLeft,
      _866: x0 => x0.offsetTop,
      _867: x0 => x0.offsetParent,
      _869: (x0,x1) => { x0.name = x1 },
      _870: x0 => x0.content,
      _871: (x0,x1) => { x0.content = x1 },
      _875: (x0,x1) => { x0.src = x1 },
      _876: x0 => x0.naturalWidth,
      _877: x0 => x0.naturalHeight,
      _881: (x0,x1) => { x0.crossOrigin = x1 },
      _883: (x0,x1) => { x0.decoding = x1 },
      _884: x0 => x0.decode(),
      _889: (x0,x1) => { x0.nonce = x1 },
      _894: (x0,x1) => { x0.width = x1 },
      _896: (x0,x1) => { x0.height = x1 },
      _899: (x0,x1) => x0.getContext(x1),
      _960: x0 => x0.width,
      _961: x0 => x0.height,
      _963: (x0,x1) => x0.fetch(x1),
      _964: x0 => x0.status,
      _966: x0 => x0.body,
      _967: x0 => x0.arrayBuffer(),
      _970: x0 => x0.read(),
      _971: x0 => x0.value,
      _972: x0 => x0.done,
      _979: x0 => x0.name,
      _980: x0 => x0.x,
      _981: x0 => x0.y,
      _984: x0 => x0.top,
      _985: x0 => x0.right,
      _986: x0 => x0.bottom,
      _987: x0 => x0.left,
      _997: x0 => x0.height,
      _998: x0 => x0.width,
      _999: x0 => x0.scale,
      _1000: (x0,x1) => { x0.value = x1 },
      _1003: (x0,x1) => { x0.placeholder = x1 },
      _1005: (x0,x1) => { x0.name = x1 },
      _1006: x0 => x0.selectionDirection,
      _1007: x0 => x0.selectionStart,
      _1008: x0 => x0.selectionEnd,
      _1011: x0 => x0.value,
      _1013: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1014: x0 => x0.readText(),
      _1015: (x0,x1) => x0.writeText(x1),
      _1017: x0 => x0.altKey,
      _1018: x0 => x0.code,
      _1019: x0 => x0.ctrlKey,
      _1020: x0 => x0.key,
      _1021: x0 => x0.keyCode,
      _1022: x0 => x0.location,
      _1023: x0 => x0.metaKey,
      _1024: x0 => x0.repeat,
      _1025: x0 => x0.shiftKey,
      _1026: x0 => x0.isComposing,
      _1028: x0 => x0.state,
      _1029: (x0,x1) => x0.go(x1),
      _1031: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1032: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1033: x0 => x0.pathname,
      _1034: x0 => x0.search,
      _1035: x0 => x0.hash,
      _1039: x0 => x0.state,
      _1042: (x0,x1) => x0.createObjectURL(x1),
      _1044: x0 => new Blob(x0),
      _1046: x0 => new MutationObserver(x0),
      _1047: (x0,x1,x2) => x0.observe(x1,x2),
      _1048: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1048(f,arguments.length,x0,x1) }),
      _1051: x0 => x0.attributeName,
      _1052: x0 => x0.type,
      _1053: x0 => x0.matches,
      _1054: x0 => x0.matches,
      _1058: x0 => x0.relatedTarget,
      _1060: x0 => x0.clientX,
      _1061: x0 => x0.clientY,
      _1062: x0 => x0.offsetX,
      _1063: x0 => x0.offsetY,
      _1066: x0 => x0.button,
      _1067: x0 => x0.buttons,
      _1068: x0 => x0.ctrlKey,
      _1072: x0 => x0.pointerId,
      _1073: x0 => x0.pointerType,
      _1074: x0 => x0.pressure,
      _1075: x0 => x0.tiltX,
      _1076: x0 => x0.tiltY,
      _1077: x0 => x0.getCoalescedEvents(),
      _1080: x0 => x0.deltaX,
      _1081: x0 => x0.deltaY,
      _1082: x0 => x0.wheelDeltaX,
      _1083: x0 => x0.wheelDeltaY,
      _1084: x0 => x0.deltaMode,
      _1091: x0 => x0.changedTouches,
      _1094: x0 => x0.clientX,
      _1095: x0 => x0.clientY,
      _1098: x0 => x0.data,
      _1101: (x0,x1) => { x0.disabled = x1 },
      _1103: (x0,x1) => { x0.type = x1 },
      _1104: (x0,x1) => { x0.max = x1 },
      _1105: (x0,x1) => { x0.min = x1 },
      _1106: x0 => x0.value,
      _1107: (x0,x1) => { x0.value = x1 },
      _1108: x0 => x0.disabled,
      _1109: (x0,x1) => { x0.disabled = x1 },
      _1111: (x0,x1) => { x0.placeholder = x1 },
      _1112: (x0,x1) => { x0.name = x1 },
      _1115: (x0,x1) => { x0.autocomplete = x1 },
      _1116: x0 => x0.selectionDirection,
      _1117: x0 => x0.selectionStart,
      _1119: x0 => x0.selectionEnd,
      _1122: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1123: (x0,x1) => x0.add(x1),
      _1126: (x0,x1) => { x0.noValidate = x1 },
      _1127: (x0,x1) => { x0.method = x1 },
      _1128: (x0,x1) => { x0.action = x1 },
      _1129: (x0,x1) => new OffscreenCanvas(x0,x1),
      _1135: (x0,x1) => x0.getContext(x1),
      _1137: x0 => x0.convertToBlob(),
      _1154: x0 => x0.orientation,
      _1155: x0 => x0.width,
      _1156: x0 => x0.height,
      _1157: (x0,x1) => x0.lock(x1),
      _1176: x0 => new ResizeObserver(x0),
      _1179: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1179(f,arguments.length,x0,x1) }),
      _1187: x0 => x0.length,
      _1188: x0 => x0.iterator,
      _1189: x0 => x0.Segmenter,
      _1190: x0 => x0.v8BreakIterator,
      _1191: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1194: x0 => x0.language,
      _1195: x0 => x0.script,
      _1196: x0 => x0.region,
      _1214: x0 => x0.done,
      _1215: x0 => x0.value,
      _1216: x0 => x0.index,
      _1220: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1221: (x0,x1) => x0.adoptText(x1),
      _1222: x0 => x0.first(),
      _1223: x0 => x0.next(),
      _1224: x0 => x0.current(),
      _1238: x0 => x0.hostElement,
      _1239: x0 => x0.viewConstraints,
      _1242: x0 => x0.maxHeight,
      _1243: x0 => x0.maxWidth,
      _1244: x0 => x0.minHeight,
      _1245: x0 => x0.minWidth,
      _1246: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1246(f,arguments.length,x0) }),
      _1247: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1247(f,arguments.length,x0) }),
      _1248: (x0,x1) => ({addView: x0,removeView: x1}),
      _1251: x0 => x0.loader,
      _1252: () => globalThis._flutter,
      _1253: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1254: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1254(f,arguments.length,x0) }),
      _1255: f => finalizeWrapper(f, function() { return dartInstance.exports._1255(f,arguments.length) }),
      _1256: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1259: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1259(f,arguments.length,x0) }),
      _1260: x0 => ({runApp: x0}),
      _1262: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1262(f,arguments.length,x0,x1) }),
      _1263: x0 => x0.length,
      _1264: () => globalThis.window.ImageDecoder,
      _1265: x0 => x0.tracks,
      _1267: x0 => x0.completed,
      _1269: x0 => x0.image,
      _1275: x0 => x0.displayWidth,
      _1276: x0 => x0.displayHeight,
      _1277: x0 => x0.duration,
      _1280: x0 => x0.ready,
      _1281: x0 => x0.selectedTrack,
      _1282: x0 => x0.repetitionCount,
      _1283: x0 => x0.frameCount,
      _1338: (x0,x1) => x0.getUserMedia(x1),
      _1339: x0 => x0.getSupportedConstraints(),
      _1340: x0 => x0.getVideoTracks(),
      _1341: x0 => x0.getCapabilities(),
      _1342: x0 => x0.getSettings(),
      _1343: (x0,x1,x2) => x0.setProperty(x1,x2),
      _1344: (x0,x1) => x0.append(x1),
      _1345: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1346: x0 => x0.play(),
      _1347: x0 => x0.pause(),
      _1348: x0 => x0.getTracks(),
      _1349: x0 => x0.stop(),
      _1350: (x0,x1,x2) => x0.translate(x1,x2),
      _1351: (x0,x1,x2) => x0.scale(x1,x2),
      _1352: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1352(f,arguments.length,x0) }),
      _1353: (x0,x1,x2) => x0.toBlob(x1,x2),
      _1354: x0 => globalThis.URL.createObjectURL(x0),
      _1355: x0 => ({torch: x0}),
      _1356: (x0,x1) => x0.applyConstraints(x1),
      _1370: x0 => x0.load(),
      _1371: x0 => globalThis.MediaRecorder.isTypeSupported(x0),
      _1372: x0 => ({type: x0}),
      _1373: (x0,x1) => new Blob(x0,x1),
      _1374: x0 => x0.enumerateDevices(),
      _1375: x0 => new Event(x0),
      _1379: (x0,x1) => x0.createElement(x1),
      _1380: (x0,x1) => x0.getContext(x1),
      _1381: (x0,x1,x2,x3,x4,x5) => x0.drawImage(x1,x2,x3,x4,x5),
      _1382: x0 => x0.arrayBuffer(),
      _1383: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1383(f,arguments.length,x0) }),
      _1384: (x0,x1,x2,x3) => x0.toBlob(x1,x2,x3),
      _1385: x0 => new Blob(x0),
      _1386: (x0,x1,x2,x3) => x0.drawImage(x1,x2,x3),
      _1387: (x0,x1,x2,x3,x4) => x0.getImageData(x1,x2,x3,x4),
      _1389: (x0,x1) => x0.removeAttribute(x1),
      _1390: x0 => globalThis.glGetError(x0),
      _1391: (x0,x1) => globalThis.glCanvas(x0,x1),
      _1392: (x0,x1,x2,x3,x4) => globalThis.glScissor(x0,x1,x2,x3,x4),
      _1393: (x0,x1,x2,x3,x4) => globalThis.glViewport(x0,x1,x2,x3,x4),
      _1394: (x0,x1) => globalThis.glGetExtension(x0,x1),
      _1395: (x0,x1,x2) => globalThis.glGetUniformBlockIndex(x0,x1,x2),
      _1397: x0 => globalThis.glCreateTexture(x0),
      _1398: (x0,x1,x2) => globalThis.glBindTexture(x0,x1,x2),
      _1399: (x0,x1,x2,x3,x4,x5) => globalThis.glDrawElementsInstanced(x0,x1,x2,x3,x4,x5),
      _1400: (x0,x1) => globalThis.glActiveTexture(x0,x1),
      _1401: (x0,x1,x2,x3) => globalThis.glTexParameteri(x0,x1,x2,x3),
      _1402: (x0,x1) => globalThis.glGetParameter(x0,x1),
      _1403: (x0,x1,x2,x3,x4,x5,x6) => globalThis.glTexImage2D_NOSIZE(x0,x1,x2,x3,x4,x5,x6),
      _1404: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => globalThis.glTexImage2D(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1405: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) => globalThis.glTexImage3D(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10),
      _1406: (x0,x1) => globalThis.glDepthFunc(x0,x1),
      _1407: (x0,x1) => globalThis.glDepthMask(x0,x1),
      _1408: (x0,x1) => globalThis.glEnable(x0,x1),
      _1409: (x0,x1) => globalThis.glDisable(x0,x1),
      _1410: (x0,x1) => globalThis.glBlendEquation(x0,x1),
      _1411: (x0,x1) => globalThis.glUseProgram(x0,x1),
      _1412: (x0,x1,x2,x3,x4) => globalThis.glBlendFuncSeparate(x0,x1,x2,x3,x4),
      _1413: (x0,x1,x2) => globalThis.glBlendFunc(x0,x1,x2),
      _1414: (x0,x1,x2) => globalThis.glBlendEquationSeparate(x0,x1,x2),
      _1415: (x0,x1) => globalThis.glFrontFace(x0,x1),
      _1416: (x0,x1) => globalThis.glCullFace(x0,x1),
      _1417: (x0,x1) => globalThis.glLineWidth(x0,x1),
      _1418: (x0,x1,x2) => globalThis.glPolygonOffset(x0,x1,x2),
      _1419: (x0,x1) => globalThis.glStencilMask(x0,x1),
      _1420: (x0,x1,x2,x3) => globalThis.glStencilFunc(x0,x1,x2,x3),
      _1421: (x0,x1,x2,x3) => globalThis.glStencilOp(x0,x1,x2,x3),
      _1422: (x0,x1) => globalThis.glClearStencil(x0,x1),
      _1423: (x0,x1) => globalThis.glClearDepth(x0,x1),
      _1424: (x0,x1,x2,x3,x4) => globalThis.glColorMask(x0,x1,x2,x3,x4),
      _1425: (x0,x1,x2,x3,x4) => globalThis.glClearColor(x0,x1,x2,x3,x4),
      _1427: (x0,x1) => globalThis.glGenerateMipmap(x0,x1),
      _1428: (x0,x1) => globalThis.glDeleteTexture(x0,x1),
      _1429: (x0,x1) => globalThis.glDeleteFramebuffer(x0,x1),
      _1430: (x0,x1) => globalThis.glDeleteRenderbuffer(x0,x1),
      _1431: (x0,x1,x2,x3) => globalThis.glTexParameterf(x0,x1,x2,x3),
      _1432: (x0,x1,x2) => globalThis.glPixelStorei(x0,x1,x2),
      _1434: (x0,x1,x2) => globalThis.glGetProgramParameter(x0,x1,x2),
      _1435: (x0,x1,x2) => globalThis.glGetActiveUniform(x0,x1,x2),
      _1436: (x0,x1,x2) => globalThis.glGetActiveAttrib(x0,x1,x2),
      _1437: (x0,x1,x2) => globalThis.glGetUniformLocation(x0,x1,x2),
      _1438: (x0,x1) => globalThis.glClear(x0,x1),
      _1439: x0 => globalThis.glCreateBuffer(x0),
      _1440: (x0,x1,x2,x3) => globalThis.glClearBufferuiv(x0,x1,x2,x3),
      _1441: (x0,x1,x2,x3) => globalThis.glClearBufferiv(x0,x1,x2,x3),
      _1442: (x0,x1,x2) => globalThis.glBindBuffer(x0,x1,x2),
      _1444: (x0,x1,x2,x3) => globalThis.glBufferDatai(x0,x1,x2,x3),
      _1445: (x0,x1,x2,x3) => globalThis.glBufferData(x0,x1,x2,x3),
      _1446: (x0,x1,x2,x3,x4,x5,x6) => globalThis.glVertexAttribPointer(x0,x1,x2,x3,x4,x5,x6),
      _1447: (x0,x1,x2,x3) => globalThis.glDrawArrays(x0,x1,x2,x3),
      _1448: (x0,x1,x2,x3,x4) => globalThis.glDrawArraysInstanced(x0,x1,x2,x3,x4),
      _1449: (x0,x1,x2) => globalThis.glBindFramebuffer(x0,x1,x2),
      _1451: (x0,x1,x2,x3,x4,x5) => globalThis.glFramebufferTextureLayer(x0,x1,x2,x3,x4,x5),
      _1452: (x0,x1,x2,x3,x4,x5) => globalThis.glFramebufferTexture2D(x0,x1,x2,x3,x4,x5),
      _1453: (x0,x1,x2,x3,x4,x5,x6,x7) => globalThis.glReadPixels(x0,x1,x2,x3,x4,x5,x6,x7),
      _1456: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => globalThis.glCopyTexSubImage2D(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      _1458: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => globalThis.glTexSubImage2D(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1459: (x0,x1,x2,x3,x4,x5,x6,x7) => globalThis.glTexSubImage2D_NOSIZE(x0,x1,x2,x3,x4,x5,x6,x7),
      _1460: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11) => globalThis.glTexSubImage3D(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11),
      _1464: (x0,x1,x2) => globalThis.glBindRenderbuffer(x0,x1,x2),
      _1465: (x0,x1,x2,x3,x4,x5) => globalThis.glRenderbufferStorageMultisample(x0,x1,x2,x3,x4,x5),
      _1466: (x0,x1,x2,x3,x4) => globalThis.glRenderbufferStorage(x0,x1,x2,x3,x4),
      _1467: (x0,x1,x2,x3,x4) => globalThis.glFramebufferRenderbuffer(x0,x1,x2,x3,x4),
      _1468: x0 => globalThis.glCreateRenderbuffer(x0),
      _1469: x0 => globalThis.glCreateFramebuffer(x0),
      _1470: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) => globalThis.glBlitFramebuffer(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10),
      _1471: (x0,x1,x2,x3) => globalThis.glBufferSubData(x0,x1,x2,x3),
      _1472: x0 => globalThis.glCreateVertexArray(x0),
      _1473: x0 => globalThis.glCreateProgram(x0),
      _1474: (x0,x1,x2) => globalThis.glAttachShader(x0,x1,x2),
      _1475: (x0,x1,x2,x3) => globalThis.glBindAttribLocation(x0,x1,x2,x3),
      _1476: (x0,x1) => globalThis.glLinkProgram(x0,x1),
      _1477: (x0,x1) => globalThis.glGetProgramInfoLog(x0,x1),
      _1478: (x0,x1) => globalThis.glGetShaderInfoLog(x0,x1),
      _1479: (x0,x1) => globalThis.glDeleteShader(x0,x1),
      _1480: (x0,x1) => globalThis.glDeleteProgram(x0,x1),
      _1481: (x0,x1) => globalThis.glDeleteBuffer(x0,x1),
      _1482: (x0,x1) => globalThis.glBindVertexArray(x0,x1),
      _1483: (x0,x1) => globalThis.glDeleteVertexArray(x0,x1),
      _1484: (x0,x1) => globalThis.glEnableVertexAttribArray(x0,x1),
      _1485: (x0,x1) => globalThis.glDisableVertexAttribArray(x0,x1),
      _1486: (x0,x1,x2,x3,x4,x5) => globalThis.glVertexAttribIPointer(x0,x1,x2,x3,x4,x5),
      _1487: (x0,x1,x2) => globalThis.glVertexAttrib2fv(x0,x1,x2),
      _1488: (x0,x1,x2) => globalThis.glVertexAttrib3fv(x0,x1,x2),
      _1489: (x0,x1,x2) => globalThis.glVertexAttrib4fv(x0,x1,x2),
      _1490: (x0,x1,x2) => globalThis.glVertexAttrib1fv(x0,x1,x2),
      _1491: (x0,x1,x2,x3,x4) => globalThis.glDrawElements(x0,x1,x2,x3,x4),
      _1492: (x0,x1) => globalThis.glDrawBuffers(x0,x1),
      _1493: (x0,x1) => globalThis.glCreateShader(x0,x1),
      _1494: (x0,x1,x2) => globalThis.glShaderSource(x0,x1,x2),
      _1495: (x0,x1) => globalThis.glCompileShader(x0,x1),
      _1496: (x0,x1,x2) => globalThis.glGetShaderParameter(x0,x1,x2),
      _1497: (x0,x1) => globalThis.glGetShaderSource(x0,x1),
      _1498: (x0,x1,x2) => globalThis.glUniform1i(x0,x1,x2),
      _1499: (x0,x1,x2,x3,x4) => globalThis.glUniform3f(x0,x1,x2,x3,x4),
      _1500: (x0,x1,x2,x3,x4,x5) => globalThis.glUniform4f(x0,x1,x2,x3,x4,x5),
      _1501: (x0,x1,x2) => globalThis.glUniform1fv(x0,x1,x2),
      _1502: (x0,x1,x2) => globalThis.glUniform2fv(x0,x1,x2),
      _1503: (x0,x1,x2) => globalThis.glUniform3fv(x0,x1,x2),
      _1504: (x0,x1,x2) => globalThis.glUniform1f(x0,x1,x2),
      _1505: (x0,x1,x2,x3) => globalThis.glUniformMatrix2fv(x0,x1,x2,x3),
      _1506: (x0,x1,x2,x3) => globalThis.glUniformMatrix3fv(x0,x1,x2,x3),
      _1507: (x0,x1,x2,x3) => globalThis.glUniformMatrix4fv(x0,x1,x2,x3),
      _1508: (x0,x1,x2) => globalThis.glGetAttribLocation(x0,x1,x2),
      _1509: (x0,x1,x2,x3) => globalThis.glUniform2f(x0,x1,x2,x3),
      _1510: (x0,x1,x2) => globalThis.glUniform1iv(x0,x1,x2),
      _1511: (x0,x1,x2) => globalThis.glUniform2iv(x0,x1,x2),
      _1512: (x0,x1,x2) => globalThis.glUniform3iv(x0,x1,x2),
      _1513: (x0,x1,x2) => globalThis.glUniform4iv(x0,x1,x2),
      _1514: (x0,x1,x2) => globalThis.glUniform1uiv(x0,x1,x2),
      _1515: (x0,x1,x2) => globalThis.glUniform2uiv(x0,x1,x2),
      _1516: (x0,x1,x2) => globalThis.glUniform3uiv(x0,x1,x2),
      _1517: (x0,x1,x2) => globalThis.glUniform4uiv(x0,x1,x2),
      _1518: (x0,x1,x2) => globalThis.glUniform1ui(x0,x1,x2),
      _1522: (x0,x1,x2) => globalThis.glUniform4fv(x0,x1,x2),
      _1523: (x0,x1,x2) => globalThis.glVertexAttribDivisor(x0,x1,x2),
      _1524: x0 => globalThis.glFlush(x0),
      _1525: x0 => globalThis.glFinish(x0),
      _1526: (x0,x1,x2,x3,x4,x5) => globalThis.glTexStorage2D(x0,x1,x2,x3,x4,x5),
      _1527: (x0,x1,x2,x3,x4,x5,x6) => globalThis.glTexStorage3D(x0,x1,x2,x3,x4,x5,x6),
      _1538: (x0,x1,x2) => globalThis.glInvalidateFramebuffer(x0,x1,x2),
      _1540: (x0,x1) => globalThis.glDrawingBufferColorSpace(x0,x1),
      _1541: (x0,x1) => globalThis.glUnpackColorSpace(x0,x1),
      _1542: () => globalThis.Module_soloud._createWorkerInWasm(),
      _1543: x0 => globalThis.Module_soloud._malloc(x0),
      _1544: (x0,x1,x2) => globalThis.Module_soloud.setValue(x0,x1,x2),
      _1546: x0 => globalThis.Module_soloud._free(x0),
      _1547: () => globalThis.Module_soloud._areOpusOggLibsAvailable(),
      _1548: (x0,x1,x2,x3) => globalThis.Module_soloud._initEngine(x0,x1,x2,x3),
      _1551: (x0,x1) => globalThis.Module_soloud.getValue(x0,x1),
      _1554: () => globalThis.Module_soloud._dispose(),
      _1555: () => globalThis.Module_soloud._isInited(),
      _1556: (x0,x1,x2,x3,x4) => globalThis.Module_soloud._loadMem(x0,x1,x2,x3,x4),
      _1574: x0 => globalThis.Module_soloud._getPause(x0),
      _1575: (x0,x1) => globalThis.Module_soloud._setRelativePlaySpeed(x0,x1),
      _1577: (x0,x1,x2,x3,x4,x5,x6) => globalThis.Module_soloud._play(x0,x1,x2,x3,x4,x5,x6),
      _1580: () => globalThis.Module_soloud._disposeAllSound(),
      _1586: () => globalThis.Module_soloud._getVisualizationEnabled(),
      _1597: x0 => globalThis.Module_soloud._getVolume(x0),
      _1598: (x0,x1) => globalThis.Module_soloud._setVolume(x0,x1),
      _1599: x0 => globalThis.Module_soloud._getPan(x0),
      _1600: (x0,x1) => globalThis.Module_soloud._setPan(x0,x1),
      _1658: (x0,x1) => ({video: x0,audio: x1}),
      _1659: () => new AudioContext(),
      _1660: (x0,x1) => x0.createMediaElementSource(x1),
      _1661: x0 => x0.createStereoPanner(),
      _1662: (x0,x1) => x0.connect(x1),
      _1663: x0 => x0.remove(),
      _1675: (x0,x1) => x0.querySelector(x1),
      _1677: () => new FileReader(),
      _1679: (x0,x1) => x0.readAsArrayBuffer(x1),
      _1685: x0 => x0.click(),
      _1686: x0 => globalThis.URL.revokeObjectURL(x0),
      _1688: Date.now,
      _1690: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1691: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1692: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1693: () => typeof dartUseDateNowForTicks !== "undefined",
      _1694: () => 1000 * performance.now(),
      _1695: () => Date.now(),
      _1696: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1697: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1698: () => new WeakMap(),
      _1699: (map, o) => map.get(o),
      _1700: (map, o, v) => map.set(o, v),
      _1701: x0 => new WeakRef(x0),
      _1702: x0 => x0.deref(),
      _1703: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1703(f,arguments.length,x0) }),
      _1704: x0 => new FinalizationRegistry(x0),
      _1706: (x0,x1,x2) => x0.register(x1,x2),
      _1709: () => globalThis.WeakRef,
      _1710: () => globalThis.FinalizationRegistry,
      _1713: s => JSON.stringify(s),
      _1714: s => printToConsole(s),
      _1715: (o, p, r) => o.replaceAll(p, () => r),
      _1716: (o, p, r) => o.replace(p, () => r),
      _1717: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1718: s => s.toUpperCase(),
      _1719: s => s.trim(),
      _1720: s => s.trimLeft(),
      _1721: s => s.trimRight(),
      _1722: (string, times) => string.repeat(times),
      _1723: Function.prototype.call.bind(String.prototype.indexOf),
      _1724: (s, p, i) => s.lastIndexOf(p, i),
      _1725: (string, token) => string.split(token),
      _1726: Object.is,
      _1727: o => o instanceof Array,
      _1728: (a, i) => a.push(i),
      _1729: (a, i) => a.splice(i, 1)[0],
      _1731: (a, l) => a.length = l,
      _1732: a => a.pop(),
      _1733: (a, i) => a.splice(i, 1),
      _1734: (a, s) => a.join(s),
      _1735: (a, s, e) => a.slice(s, e),
      _1736: (a, s, e) => a.splice(s, e),
      _1737: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1738: a => a.length,
      _1739: (a, l) => a.length = l,
      _1740: (a, i) => a[i],
      _1741: (a, i, v) => a[i] = v,
      _1742: (a, t) => a.concat(t),
      _1743: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _1744: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1746: o => o instanceof Uint8Array,
      _1747: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1748: o => o instanceof Int8Array,
      _1749: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1750: o => o instanceof Uint8ClampedArray,
      _1751: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1752: o => o instanceof Uint16Array,
      _1753: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1754: o => o instanceof Int16Array,
      _1755: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1756: o => o instanceof Uint32Array,
      _1757: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1758: o => o instanceof Int32Array,
      _1759: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1761: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1762: o => o instanceof Float32Array,
      _1763: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1764: o => o instanceof Float64Array,
      _1765: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1766: (t, s) => t.set(s),
      _1767: l => new DataView(new ArrayBuffer(l)),
      _1768: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1769: o => o.byteLength,
      _1770: o => o.buffer,
      _1771: o => o.byteOffset,
      _1772: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1773: (b, o) => new DataView(b, o),
      _1774: (b, o, l) => new DataView(b, o, l),
      _1775: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1776: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1777: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1778: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1779: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1780: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1781: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1782: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1783: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1784: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1785: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1786: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1789: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1790: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1791: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1792: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1793: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1794: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1796: () => globalThis.performance,
      _1797: () => globalThis.JSON,
      _1798: x0 => x0.measure,
      _1799: x0 => x0.mark,
      _1800: x0 => x0.clearMeasures,
      _1801: x0 => x0.clearMarks,
      _1802: (x0,x1,x2,x3) => x0.measure(x1,x2,x3),
      _1803: (x0,x1,x2) => x0.mark(x1,x2),
      _1804: x0 => x0.clearMeasures(),
      _1805: x0 => x0.clearMarks(),
      _1806: (x0,x1) => x0.parse(x1),
      _1807: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1808: (handle) => clearTimeout(handle),
      _1809: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1810: (handle) => clearInterval(handle),
      _1811: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1812: () => Date.now(),
      _1813: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _1814: (x0,x1) => x0.exec(x1),
      _1815: (x0,x1) => x0.test(x1),
      _1816: x0 => x0.pop(),
      _1818: o => o === undefined,
      _1820: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _1822: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _1823: o => o instanceof RegExp,
      _1824: (l, r) => l === r,
      _1825: o => o,
      _1826: o => o,
      _1827: o => o,
      _1828: b => !!b,
      _1829: o => o.length,
      _1831: (o, i) => o[i],
      _1832: f => f.dartFunction,
      _1833: () => ({}),
      _1834: () => [],
      _1836: () => globalThis,
      _1837: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _1839: (o, p) => o[p],
      _1840: (o, p, v) => o[p] = v,
      _1841: (o, m, a) => o[m].apply(o, a),
      _1843: o => String(o),
      _1844: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _1845: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1845(f,arguments.length,x0) }),
      _1846: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1846(f,arguments.length,x0,x1) }),
      _1847: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _1848: o => [o],
      _1849: (o0, o1) => [o0, o1],
      _1850: (o0, o1, o2) => [o0, o1, o2],
      _1851: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _1852: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1853: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1854: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1855: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1856: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1857: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1858: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1859: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1860: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1861: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1862: x0 => new ArrayBuffer(x0),
      _1863: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _1864: x0 => x0.input,
      _1865: x0 => x0.index,
      _1867: x0 => x0.flags,
      _1868: x0 => x0.multiline,
      _1869: x0 => x0.ignoreCase,
      _1870: x0 => x0.unicode,
      _1871: x0 => x0.dotAll,
      _1872: (x0,x1) => { x0.lastIndex = x1 },
      _1873: (o, p) => p in o,
      _1874: (o, p) => o[p],
      _1875: (o, p, v) => o[p] = v,
      _1876: (o, p) => delete o[p],
      _1877: (x0,x1) => x0.end(x1),
      _1878: (x0,x1) => x0.item(x1),
      _1879: (x0,x1) => x0.appendChild(x1),
      _1883: x0 => ({xhrSetup: x0}),
      _1884: x0 => new Hls(x0),
      _1885: (x0,x1) => x0.loadSource(x1),
      _1886: (x0,x1) => x0.attachMedia(x1),
      _1887: (x0,x1) => x0.canPlayType(x1),
      _1888: () => globalThis.Hls.isSupported(),
      _1889: () => new XMLHttpRequest(),
      _1890: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1893: x0 => x0.send(),
      _1895: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1895(f,arguments.length,x0) }),
      _1896: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1896(f,arguments.length,x0) }),
      _1897: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1898: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1907: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1907(f,arguments.length,x0) }),
      _1910: (x0,x1) => x0.append(x1),
      _1917: () => globalThis.Module_soloud.wasmWorker,
      _1921: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _1922: (x0,x1) => globalThis.fetch(x0,x1),
      _1923: (x0,x1) => x0.get(x1),
      _1924: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1924(f,arguments.length,x0,x1,x2) }),
      _1925: (x0,x1) => x0.forEach(x1),
      _1926: x0 => x0.abort(),
      _1927: () => new AbortController(),
      _1928: x0 => x0.getReader(),
      _1929: x0 => x0.read(),
      _1930: x0 => x0.cancel(),
      _1935: x0 => x0.torch,
      _1936: x0 => x0.facingMode,
      _1945: x0 => x0.random(),
      _1946: (x0,x1) => x0.getRandomValues(x1),
      _1947: () => globalThis.crypto,
      _1948: () => globalThis.Math,
      _1957: Function.prototype.call.bind(Number.prototype.toString),
      _1958: Function.prototype.call.bind(BigInt.prototype.toString),
      _1959: Function.prototype.call.bind(Number.prototype.toString),
      _1960: (d, digits) => d.toFixed(digits),
      _1963: (d, precision) => d.toPrecision(precision),
      _2064: (x0,x1) => { x0.responseType = x1 },
      _2065: x0 => x0.response,
      _2141: x0 => x0.style,
      _2500: (x0,x1) => { x0.download = x1 },
      _2525: (x0,x1) => { x0.href = x1 },
      _2573: (x0,x1) => { x0.src = x1 },
      _2579: (x0,x1) => { x0.crossOrigin = x1 },
      _2584: x0 => x0.width,
      _2585: (x0,x1) => { x0.width = x1 },
      _2586: x0 => x0.height,
      _2587: (x0,x1) => { x0.height = x1 },
      _2712: x0 => x0.videoWidth,
      _2713: x0 => x0.videoHeight,
      _2742: x0 => x0.error,
      _2744: (x0,x1) => { x0.src = x1 },
      _2745: x0 => x0.srcObject,
      _2746: (x0,x1) => { x0.srcObject = x1 },
      _2749: (x0,x1) => { x0.crossOrigin = x1 },
      _2752: (x0,x1) => { x0.preload = x1 },
      _2753: x0 => x0.buffered,
      _2754: x0 => x0.readyState,
      _2756: x0 => x0.currentTime,
      _2757: (x0,x1) => { x0.currentTime = x1 },
      _2758: x0 => x0.duration,
      _2762: x0 => x0.playbackRate,
      _2763: (x0,x1) => { x0.playbackRate = x1 },
      _2770: (x0,x1) => { x0.autoplay = x1 },
      _2772: (x0,x1) => { x0.loop = x1 },
      _2774: (x0,x1) => { x0.controls = x1 },
      _2775: x0 => x0.volume,
      _2776: (x0,x1) => { x0.volume = x1 },
      _2777: x0 => x0.muted,
      _2778: (x0,x1) => { x0.muted = x1 },
      _2793: x0 => x0.code,
      _2794: x0 => x0.message,
      _2868: x0 => x0.length,
      _3371: x0 => x0.src,
      _3372: (x0,x1) => { x0.src = x1 },
      _3374: (x0,x1) => { x0.type = x1 },
      _3378: (x0,x1) => { x0.async = x1 },
      _3392: (x0,x1) => { x0.charset = x1 },
      _3416: x0 => x0.width,
      _3417: (x0,x1) => { x0.width = x1 },
      _3418: x0 => x0.height,
      _3419: (x0,x1) => { x0.height = x1 },
      _3543: x0 => x0.width,
      _3545: x0 => x0.data,
      _3838: () => globalThis.window,
      _3901: x0 => x0.navigator,
      _3905: x0 => x0.screen,
      _4271: x0 => x0.geolocation,
      _4274: x0 => x0.mediaDevices,
      _4276: x0 => x0.permissions,
      _4290: x0 => x0.userAgent,
      _4291: x0 => x0.vendor,
      _4341: x0 => x0.data,
      _4449: (x0,x1) => { x0.onmessage = x1 },
      _5887: x0 => x0.destination,
      _5984: (x0,x1) => { x0.value = x1 },
      _6242: x0 => x0.pan,
      _6401: x0 => x0.type,
      _6442: x0 => x0.signal,
      _6454: x0 => x0.length,
      _6514: () => globalThis.document,
      _6595: x0 => x0.body,
      _6597: x0 => x0.head,
      _6929: (x0,x1) => { x0.id = x1 },
      _6953: (x0,x1) => { x0.innerHTML = x1 },
      _6956: x0 => x0.children,
      _8275: x0 => x0.value,
      _8277: x0 => x0.done,
      _8456: x0 => x0.size,
      _8475: x0 => x0.result,
      _8967: x0 => x0.url,
      _8969: x0 => x0.status,
      _8971: x0 => x0.statusText,
      _8972: x0 => x0.headers,
      _8973: x0 => x0.body,
      _9238: x0 => x0.type,
      _9270: x0 => x0.orientation,
      _9790: x0 => x0.facingMode,
      _9865: x0 => x0.facingMode,
      _10004: x0 => x0.width,
      _10006: x0 => x0.height,
      _10089: x0 => x0.deviceId,
      _10090: x0 => x0.kind,
      _10091: x0 => x0.label,
      _11089: (x0,x1) => { x0.border = x1 },
      _11367: (x0,x1) => { x0.display = x1 },
      _11531: (x0,x1) => { x0.height = x1 },
      _11725: (x0,x1) => { x0.objectFit = x1 },
      _11855: (x0,x1) => { x0.pointerEvents = x1 },
      _12153: (x0,x1) => { x0.transform = x1 },
      _12157: (x0,x1) => { x0.transformOrigin = x1 },
      _12221: (x0,x1) => { x0.width = x1 },
      _12589: x0 => x0.name,
      _12590: x0 => x0.message,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
