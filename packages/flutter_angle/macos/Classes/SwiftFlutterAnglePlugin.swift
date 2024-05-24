import FlutterMacOS

public class SwiftFlutterAnglePlugin: NSObject, FlutterPlugin {
  let fglp:FlutterAnglePlugin = FlutterAnglePlugin();
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let channel = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterAnglePlugin()
    #elseif os(macOS)
    let channel = FlutterMethodChannel(name:"flutter_angle", binaryMessenger: registrar.messenger)
    let instance = SwiftFlutterAnglePlugin()
    #endif
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      fglp.handle(call, result: result);
    }
  }
}
